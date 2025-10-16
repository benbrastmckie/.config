# Phase 3: Input Validation & Integration - Detailed Specification

## Overview

**Objective**: Enhance document conversion system quality through comprehensive input validation, agent registry integration, logging library extraction, and TodoWrite integration.

**Complexity**: 8 (High - integration across multiple subsystems with major refactoring)

**Estimated Effort**: 22 hours (10-14 days with integration testing)

**Key Outcomes**:
- Robust input validation with magic number checks preventing invalid conversions
- Agent registry tracking for doc-converter with automated metrics collection
- Modular logging library following established patterns
- TodoWrite integration for agent progress visibility

## Architecture Overview

### Integration Points

```
┌─────────────────────────────────────────────────────────────┐
│                     Phase 3 Components                       │
├──────────────────┬──────────────────┬──────────────────────┤
│ Input Validation │  Agent Registry  │  Logging Library     │
│                  │  Integration     │  Extraction          │
├──────────────────┼──────────────────┼──────────────────────┤
│ • Magic number   │ • Registry JSON  │ • conversion-logger  │
│   checks         │   schema         │   .sh library        │
│ • File type      │ • Metrics        │ • Log functions      │
│   detection      │   tracking       │   migration          │
│ • Validation     │ • Hook updates   │ • Agent refactor     │
│   counters       │ • Query tools    │   (1961→600 lines)   │
└──────────────────┴──────────────────┴──────────────────────┘
                            │
                            ▼
                  TodoWrite Integration
                  • Agent tool access
                  • Phase tracking
                  • Task updates
```

### Subsystem Dependencies

1. **convert-docs.sh** → Uses validation, sources logging library
2. **doc-converter.md** → Sources logging library, uses TodoWrite, registers with agent registry
3. **agent-registry.json** → Stores agent metadata and metrics
4. **post-subagent-metrics.sh** → Updates registry automatically on agent completion
5. **conversion-logger.sh** → Shared logging functions for script and agent modes

---

## Section 3.1: Input Validation with Magic Number Checks

### 3.1.1 Validation Architecture

**Purpose**: Prevent processing of corrupted, invalid, or misnamed files before attempting conversion.

**Validation Strategy**:
- Magic number inspection (first bytes of file)
- File type detection using `file` command
- Size and corruption checks
- Extension vs. actual format verification

**Integration**: Called early in conversion pipeline, before tool selection.

### 3.1.2 Magic Number Reference

```bash
# Magic number patterns (hexadecimal first bytes)
DOCX_MAGIC="504B"           # PK (ZIP format, DOCX is ZIP archive)
PDF_MAGIC="25504446"        # %PDF-
MD_PATTERN="text"           # Text file (from `file` command output)

# Expected file signatures
# DOCX: 50 4B 03 04 (PK..) - ZIP archive
# PDF:  25 50 44 46 (%PDF-) - PDF signature
# MD:   Any UTF-8 text (no binary signature)
```

### 3.1.3 validate_input_file() Implementation

**Location**: `/home/benjamin/.config/.claude/lib/convert-docs.sh` (insert after line 750)

**Function Signature**:
```bash
#
# validate_input_file - Validate file before conversion attempt
#
# Arguments:
#   $1 - File path to validate
#   $2 - Expected extension (docx, pdf, md)
#
# Returns:
#   0 if valid, 1 if invalid
#
# Side Effects:
#   Increments VALIDATION_FAILURES counter on failure
#   Logs validation failure to LOG_FILE
#
validate_input_file() {
  local file_path="$1"
  local expected_ext="$2"

  # Check file exists
  if [[ ! -f "$file_path" ]]; then
    echo "[VALIDATION] File not found: $file_path" >> "$LOG_FILE"
    VALIDATION_FAILURES=$((VALIDATION_FAILURES + 1))
    return 1
  fi

  # Check file size (must be at least 1 byte)
  local file_size
  file_size=$(wc -c < "$file_path" 2>/dev/null || echo "0")

  if [[ $file_size -eq 0 ]]; then
    echo "[VALIDATION] Empty file: $file_path" >> "$LOG_FILE"
    VALIDATION_FAILURES=$((VALIDATION_FAILURES + 1))
    return 1
  fi

  # Check file is readable
  if [[ ! -r "$file_path" ]]; then
    echo "[VALIDATION] File not readable: $file_path" >> "$LOG_FILE"
    VALIDATION_FAILURES=$((VALIDATION_FAILURES + 1))
    return 1
  fi

  # Perform magic number check based on expected extension
  case "${expected_ext,,}" in
    docx)
      # DOCX should be a ZIP file (PK magic number)
      local magic
      magic=$(xxd -l 2 -p "$file_path" 2>/dev/null || echo "")

      if [[ "${magic^^}" != "504B" ]]; then
        echo "[VALIDATION] Invalid DOCX magic number: $file_path (expected 504B, got $magic)" >> "$LOG_FILE"
        VALIDATION_FAILURES=$((VALIDATION_FAILURES + 1))
        return 1
      fi

      # Additional check: Verify it's recognized as a ZIP/DOCX
      local file_type
      file_type=$(file -b "$file_path" 2>/dev/null || echo "")

      if [[ ! "$file_type" =~ (Microsoft.*OOXML|Zip.*archive|Office.*Open.*XML) ]]; then
        echo "[VALIDATION] File type mismatch for DOCX: $file_path (file reports: $file_type)" >> "$LOG_FILE"
        VALIDATION_FAILURES=$((VALIDATION_FAILURES + 1))
        return 1
      fi
      ;;

    pdf)
      # PDF should start with %PDF- magic number
      local magic
      magic=$(xxd -l 4 -p "$file_path" 2>/dev/null || echo "")

      if [[ "${magic^^}" != "25504446" ]]; then
        echo "[VALIDATION] Invalid PDF magic number: $file_path (expected 25504446, got $magic)" >> "$LOG_FILE"
        VALIDATION_FAILURES=$((VALIDATION_FAILURES + 1))
        return 1
      fi

      # Additional check: Verify PDF format
      local file_type
      file_type=$(file -b "$file_path" 2>/dev/null || echo "")

      if [[ ! "$file_type" =~ PDF ]]; then
        echo "[VALIDATION] File type mismatch for PDF: $file_path (file reports: $file_type)" >> "$LOG_FILE"
        VALIDATION_FAILURES=$((VALIDATION_FAILURES + 1))
        return 1
      fi
      ;;

    md|markdown)
      # Markdown should be a text file
      local file_type
      file_type=$(file -b "$file_path" 2>/dev/null || echo "")

      # Accept various text formats
      if [[ ! "$file_type" =~ (text|ASCII|UTF-8) ]]; then
        echo "[VALIDATION] Non-text file for Markdown: $file_path (file reports: $file_type)" >> "$LOG_FILE"
        VALIDATION_FAILURES=$((VALIDATION_FAILURES + 1))
        return 1
      fi

      # Sanity check: File should not be too large (>50MB)
      if [[ $file_size -gt 52428800 ]]; then
        echo "[VALIDATION] Markdown file suspiciously large: $file_path ($file_size bytes)" >> "$LOG_FILE"
        VALIDATION_FAILURES=$((VALIDATION_FAILURES + 1))
        return 1
      fi
      ;;

    *)
      echo "[VALIDATION] Unknown expected extension: $expected_ext" >> "$LOG_FILE"
      VALIDATION_FAILURES=$((VALIDATION_FAILURES + 1))
      return 1
      ;;
  esac

  # All checks passed
  return 0
}
```

### 3.1.4 Integration into Discovery Loops

**Modify discover_files() function** (lines 148-165):

```bash
#
# discover_files - Find convertible files in input directory
#
# Arguments:
#   $1 - Input directory path
#
# Populates global arrays: docx_files, pdf_files, md_files
# Validates each file before adding to array
#
discover_files() {
  local input_dir="$1"

  # Find and validate DOCX files
  while IFS= read -r -d '' file; do
    if validate_input_file "$file" "docx"; then
      docx_files+=("$file")
    else
      echo "  Skipping invalid DOCX file: $(basename "$file")"
    fi
  done < <(find "$input_dir" -maxdepth 1 -type f -iname "*.docx" -print0 2>/dev/null)

  # Find and validate PDF files
  while IFS= read -r -d '' file; do
    if validate_input_file "$file" "pdf"; then
      pdf_files+=("$file")
    else
      echo "  Skipping invalid PDF file: $(basename "$file")"
    fi
  done < <(find "$input_dir" -maxdepth 1 -type f -iname "*.pdf" -print0 2>/dev/null)

  # Find and validate Markdown files
  while IFS= read -r -d '' file; do
    if validate_input_file "$file" "md"; then
      md_files+=("$file")
    else
      echo "  Skipping invalid Markdown file: $(basename "$file")"
    fi
  done < <(find "$input_dir" -maxdepth 1 -type f \( -iname "*.md" -o -iname "*.markdown" \) -print0 2>/dev/null)
}
```

### 3.1.5 Validation Counter Tracking

**Add to script initialization** (after line 60):

```bash
# Validation counters
VALIDATION_FAILURES=0
```

**Add to generate_summary() function** (after line 851):

```bash
echo "Validation:" >> "$LOG_FILE"
echo "  Failed:  $VALIDATION_FAILURES files" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

if [[ $VALIDATION_FAILURES -gt 0 ]]; then
  echo "Validation: $VALIDATION_FAILURES files skipped (see log)" | tee -a "$LOG_FILE"
fi
```

### 3.1.6 Enhanced Error Messages

**Update script help message** (lines 18-21):

```bash
# Validation:
#   Files are validated before conversion:
#   - Magic number checks (DOCX=PK, PDF=%PDF-)
#   - File type verification using `file` command
#   - Size and corruption checks
#   Invalid files are skipped and logged
```

### 3.1.7 Test Cases

**Create**: `/home/benjamin/.config/.claude/tests/test_convert_docs_validation.sh`

```bash
#!/usr/bin/env bash
#
# Test suite for convert-docs.sh input validation
#

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

source "$(dirname "$0")/../lib/convert-docs.sh"

# Initialize global validation counter
VALIDATION_FAILURES=0
LOG_FILE="$TEST_DIR/test.log"
touch "$LOG_FILE"

# Test 1: Empty file
echo "Test 1: Empty file validation"
touch "$TEST_DIR/empty.docx"
if validate_input_file "$TEST_DIR/empty.docx" "docx"; then
  echo "  FAIL: Empty file should fail validation"
  exit 1
else
  echo "  PASS: Empty file rejected"
fi

# Test 2: Wrong extension (PDF named as DOCX)
echo "Test 2: Extension mismatch validation"
echo "%PDF-1.4" > "$TEST_DIR/fake.docx"
if validate_input_file "$TEST_DIR/fake.docx" "docx"; then
  echo "  FAIL: PDF with .docx extension should fail"
  exit 1
else
  echo "  PASS: Extension mismatch detected"
fi

# Test 3: Corrupted DOCX (invalid ZIP)
echo "Test 3: Corrupted file validation"
echo "NOT A REAL ZIP FILE" > "$TEST_DIR/corrupted.docx"
if validate_input_file "$TEST_DIR/corrupted.docx" "docx"; then
  echo "  FAIL: Corrupted DOCX should fail"
  exit 1
else
  echo "  PASS: Corrupted file detected"
fi

# Test 4: Valid markdown
echo "Test 4: Valid markdown validation"
echo "# Test Markdown" > "$TEST_DIR/valid.md"
if ! validate_input_file "$TEST_DIR/valid.md" "md"; then
  echo "  FAIL: Valid markdown should pass"
  exit 1
else
  echo "  PASS: Valid markdown accepted"
fi

# Test 5: Binary file as markdown
echo "Test 5: Binary file with .md extension"
printf '\x00\x01\x02\x03\x04' > "$TEST_DIR/binary.md"
if validate_input_file "$TEST_DIR/binary.md" "md"; then
  echo "  FAIL: Binary file should fail markdown validation"
  exit 1
else
  echo "  PASS: Binary file rejected"
fi

# Test 6: Validation counter
echo "Test 6: Validation counter tracking"
VALIDATION_FAILURES=0
validate_input_file "$TEST_DIR/empty.docx" "docx" || true
validate_input_file "$TEST_DIR/fake.docx" "docx" || true
if [[ $VALIDATION_FAILURES -ne 2 ]]; then
  echo "  FAIL: Expected 2 validation failures, got $VALIDATION_FAILURES"
  exit 1
else
  echo "  PASS: Validation counter correct"
fi

echo ""
echo "All validation tests passed!"
```

### 3.1.8 Documentation Updates

**Update**: `/home/benjamin/.config/.claude/commands/convert-docs.md`

Add new section after line 109:

```markdown
## Input Validation

Files are validated before conversion to prevent processing invalid or corrupted files:

### Validation Checks

1. **File Existence**: File must exist and be readable
2. **File Size**: File must not be empty (>0 bytes)
3. **Magic Number**: File header must match expected format
   - DOCX: `504B` (PK - ZIP archive signature)
   - PDF: `25504446` (%PDF- signature)
   - Markdown: Must be text file (UTF-8/ASCII)
4. **File Type Verification**: Uses `file` command to verify format matches extension

### Validation Behavior

- Invalid files are skipped with warning message
- Validation failures are logged to conversion.log
- Conversion summary reports validation failure count
- Common issues detected:
  - Empty files
  - Wrong file extensions (e.g., PDF named as .docx)
  - Corrupted file headers
  - Binary files with text extensions

### Example Output

```
Discovering documents in ./input...
  Skipping invalid DOCX file: corrupted.docx
  Skipping invalid PDF file: empty.pdf
Found 10 valid DOCX, 5 valid PDF files

Conversion Summary:
  Validation: 2 files skipped (see log)
```
```

---

## Section 3.2: Agent Registry Integration

### 3.2.1 Registry JSON Schema

**File**: `/home/benjamin/.config/.claude/agents/agent-registry.json`

Current structure (from existing file):
```json
{
  "agents": {},
  "metadata": {
    "created": "2025-10-03",
    "last_updated": "2025-10-03",
    "description": "Agent performance tracking registry",
    "version": "1.0"
  }
}
```

**Enhanced schema with doc-converter entry**:

```json
{
  "agents": {
    "doc-converter": {
      "type": "specialized",
      "description": "Bidirectional document conversion between Markdown, DOCX, and PDF",
      "tools": ["Read", "Grep", "Glob", "Bash", "Write"],
      "total_invocations": 0,
      "successes": 0,
      "total_duration_ms": 0,
      "avg_duration_ms": 0,
      "success_rate": 0.0,
      "last_execution": null,
      "last_status": null
    }
  },
  "metadata": {
    "created": "2025-10-03",
    "last_updated": "2025-10-12",
    "description": "Agent performance tracking registry",
    "version": "1.0"
  }
}
```

### 3.2.2 Agent Registry Schema Fields

**Agent Entry Fields**:

| Field | Type | Description | Source |
|-------|------|-------------|--------|
| `type` | string | Agent category (specialized/general-purpose) | Manual |
| `description` | string | One-line agent purpose | From agent .md frontmatter |
| `tools` | array | List of allowed tools | From agent .md frontmatter |
| `total_invocations` | integer | Total times agent was called | Auto-updated by hook |
| `successes` | integer | Successful completions | Auto-updated by hook |
| `total_duration_ms` | integer | Sum of all execution times | Auto-updated by hook |
| `avg_duration_ms` | integer | Average execution time | Calculated by hook |
| `success_rate` | float | successes / total_invocations | Calculated by hook |
| `last_execution` | timestamp | ISO 8601 timestamp | Auto-updated by hook |
| `last_status` | string | success/failure | Auto-updated by hook |

### 3.2.3 update_agent_metrics() Implementation

**Create**: `/home/benjamin/.config/.claude/lib/agent-registry-utils.sh`

```bash
#!/usr/bin/env bash
#
# Agent Registry Utilities
# Functions for reading and updating agent-registry.json
#
# Usage:
#   source .claude/lib/agent-registry-utils.sh
#   update_agent_metrics "agent-name" "success" 1500
#   get_agent_info "agent-name"
#

set -euo pipefail

# Configuration
readonly REGISTRY_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/agents/agent-registry.json"

# Ensure registry file exists
ensure_registry_exists() {
  if [[ ! -f "$REGISTRY_FILE" ]]; then
    mkdir -p "$(dirname "$REGISTRY_FILE")"
    cat > "$REGISTRY_FILE" <<'EOF'
{
  "agents": {},
  "metadata": {
    "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "description": "Agent performance tracking registry",
    "version": "1.0"
  }
}
EOF
  fi
}

#
# register_agent - Add or update agent entry in registry
#
# Arguments:
#   $1 - agent_name
#   $2 - agent_type (specialized/general-purpose)
#   $3 - description
#   $4 - tools (comma-separated string)
#
register_agent() {
  local agent_name="$1"
  local agent_type="$2"
  local description="$3"
  local tools="$4"

  ensure_registry_exists

  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    echo "Warning: jq not available, skipping agent registration" >&2
    return 1
  fi

  # Convert comma-separated tools to JSON array
  local tools_json
  tools_json=$(echo "$tools" | jq -R 'split(",") | map(. | gsub("^\\s+|\\s+$"; ""))')

  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Use atomic write: create temp file, then move
  local temp_file="${REGISTRY_FILE}.tmp.$$"

  jq \
    --arg agent "$agent_name" \
    --arg type "$agent_type" \
    --arg desc "$description" \
    --argjson tools "$tools_json" \
    --arg timestamp "$timestamp" \
    '.agents[$agent] = {
      type: $type,
      description: $desc,
      tools: $tools,
      total_invocations: (.agents[$agent].total_invocations // 0),
      successes: (.agents[$agent].successes // 0),
      total_duration_ms: (.agents[$agent].total_duration_ms // 0),
      avg_duration_ms: (.agents[$agent].avg_duration_ms // 0),
      success_rate: (.agents[$agent].success_rate // 0.0),
      last_execution: (.agents[$agent].last_execution // null),
      last_status: (.agents[$agent].last_status // null)
    } | .metadata.last_updated = $timestamp' \
    "$REGISTRY_FILE" > "$temp_file"

  # Atomic move
  mv "$temp_file" "$REGISTRY_FILE"

  return 0
}

#
# update_agent_metrics - Update agent performance metrics
#
# Arguments:
#   $1 - agent_name
#   $2 - status (success/failure)
#   $3 - duration_ms
#
update_agent_metrics() {
  local agent_name="$1"
  local status="$2"
  local duration_ms="$3"

  ensure_registry_exists

  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    return 1
  fi

  # Check if agent exists
  if ! jq -e ".agents.\"$agent_name\"" "$REGISTRY_FILE" > /dev/null 2>&1; then
    echo "Warning: Agent '$agent_name' not found in registry, skipping metrics update" >&2
    return 1
  fi

  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Use atomic write
  local temp_file="${REGISTRY_FILE}.tmp.$$"

  # Read current values
  local total_invocations
  local successes
  local total_duration

  total_invocations=$(jq -r ".agents.\"$agent_name\".total_invocations // 0" "$REGISTRY_FILE")
  successes=$(jq -r ".agents.\"$agent_name\".successes // 0" "$REGISTRY_FILE")
  total_duration=$(jq -r ".agents.\"$agent_name\".total_duration_ms // 0" "$REGISTRY_FILE")

  # Update counters
  total_invocations=$((total_invocations + 1))
  total_duration=$((total_duration + duration_ms))

  if [[ "$status" == "success" ]]; then
    successes=$((successes + 1))
  fi

  # Calculate metrics
  local avg_duration=$((total_duration / total_invocations))
  local success_rate
  success_rate=$(echo "scale=3; $successes / $total_invocations" | bc 2>/dev/null || echo "0")

  # Update registry
  jq \
    --arg agent "$agent_name" \
    --argjson invocations "$total_invocations" \
    --argjson successes "$successes" \
    --argjson total_duration "$total_duration" \
    --argjson avg_duration "$avg_duration" \
    --arg success_rate "$success_rate" \
    --arg timestamp "$timestamp" \
    --arg status "$status" \
    '.agents[$agent].total_invocations = $invocations |
     .agents[$agent].successes = $successes |
     .agents[$agent].total_duration_ms = $total_duration |
     .agents[$agent].avg_duration_ms = $avg_duration |
     .agents[$agent].success_rate = ($success_rate | tonumber) |
     .agents[$agent].last_execution = $timestamp |
     .agents[$agent].last_status = $status |
     .metadata.last_updated = $timestamp' \
    "$REGISTRY_FILE" > "$temp_file"

  # Atomic move
  mv "$temp_file" "$REGISTRY_FILE"

  return 0
}

#
# get_agent_info - Retrieve agent information from registry
#
# Arguments:
#   $1 - agent_name
#
get_agent_info() {
  local agent_name="$1"

  if [[ ! -f "$REGISTRY_FILE" ]]; then
    echo "Registry file not found: $REGISTRY_FILE" >&2
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo "jq not available" >&2
    return 1
  fi

  jq ".agents.\"$agent_name\"" "$REGISTRY_FILE"
}

#
# list_agents - List all agents in registry
#
list_agents() {
  if [[ ! -f "$REGISTRY_FILE" ]]; then
    echo "Registry file not found: $REGISTRY_FILE" >&2
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo "jq not available" >&2
    return 1
  fi

  jq -r '.agents | keys[]' "$REGISTRY_FILE"
}

# Export functions
export -f ensure_registry_exists
export -f register_agent
export -f update_agent_metrics
export -f get_agent_info
export -f list_agents
```

### 3.2.4 Register doc-converter Agent

**Add to doc-converter.md frontmatter** (after line 3):

```markdown
---
allowed-tools: Read, Grep, Glob, Bash, Write, TodoWrite
description: Bidirectional document conversion between Markdown, DOCX, and PDF
agent-type: specialized
register-with-metrics: true
---
```

**Add initialization to agent prompt** (after line 8):

```markdown
## Agent Registration

I am registered in the agent registry at `.claude/agents/agent-registry.json` with:
- **Type**: specialized
- **Tools**: Read, Grep, Glob, Bash, Write, TodoWrite
- **Metrics**: Invocation count, success rate, average duration

Performance metrics are automatically tracked via the post-subagent-metrics hook.
```

### 3.2.5 Metrics Visualization Tool

**Create**: `/home/benjamin/.config/.claude/utils/show-agent-metrics.sh`

```bash
#!/usr/bin/env bash
#
# Show Agent Metrics
# Display performance metrics from agent-registry.json in human-readable format
#

set -euo pipefail

REGISTRY_FILE="${1:-.claude/agents/agent-registry.json}"

if [[ ! -f "$REGISTRY_FILE" ]]; then
  echo "Error: Registry file not found: $REGISTRY_FILE"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required for this script"
  exit 1
fi

echo "=========================================="
echo "Agent Performance Metrics"
echo "=========================================="
echo ""

# Get all agent names
agents=$(jq -r '.agents | keys[]' "$REGISTRY_FILE")

if [[ -z "$agents" ]]; then
  echo "No agents registered"
  exit 0
fi

for agent in $agents; do
  echo "Agent: $agent"
  echo "----------------------------------------"

  type=$(jq -r ".agents.\"$agent\".type // \"unknown\"" "$REGISTRY_FILE")
  desc=$(jq -r ".agents.\"$agent\".description // \"No description\"" "$REGISTRY_FILE")
  invocations=$(jq -r ".agents.\"$agent\".total_invocations // 0" "$REGISTRY_FILE")
  successes=$(jq -r ".agents.\"$agent\".successes // 0" "$REGISTRY_FILE")
  avg_duration=$(jq -r ".agents.\"$agent\".avg_duration_ms // 0" "$REGISTRY_FILE")
  success_rate=$(jq -r ".agents.\"$agent\".success_rate // 0.0" "$REGISTRY_FILE")
  last_exec=$(jq -r ".agents.\"$agent\".last_execution // \"Never\"" "$REGISTRY_FILE")
  last_status=$(jq -r ".agents.\"$agent\".last_status // \"N/A\"" "$REGISTRY_FILE")

  echo "  Type: $type"
  echo "  Description: $desc"
  echo ""
  echo "  Performance:"
  echo "    Total Invocations: $invocations"
  echo "    Successes: $successes"
  echo "    Success Rate: $(printf "%.1f%%" $(echo "$success_rate * 100" | bc))"
  echo "    Average Duration: ${avg_duration}ms ($(echo "scale=2; $avg_duration / 1000" | bc)s)"
  echo ""
  echo "  Last Execution:"
  echo "    Time: $last_exec"
  echo "    Status: $last_status"
  echo ""
done

echo "=========================================="
echo "Registry: $REGISTRY_FILE"
echo "Last Updated: $(jq -r '.metadata.last_updated' "$REGISTRY_FILE")"
echo "=========================================="
```

### 3.2.6 Integration with post-subagent-metrics Hook

The existing hook (`/home/benjamin/.config/.claude/hooks/post-subagent-metrics.sh`) already handles automatic updates. No changes needed - it will automatically track doc-converter metrics when the agent completes.

**Verification**: Test that hook updates registry correctly:

```bash
# After doc-converter agent runs, verify metrics were recorded
jq '.agents."doc-converter"' .claude/agents/agent-registry.json
```

### 3.2.7 Documentation

**Update**: `/home/benjamin/.config/.claude/commands/convert-docs.md`

Add section after line 213:

```markdown
## Agent Metrics

The doc-converter agent is registered in the agent registry with automatic performance tracking:

### Tracked Metrics

- **Total Invocations**: Number of times agent was called
- **Success Rate**: Percentage of successful conversions
- **Average Duration**: Mean execution time in milliseconds
- **Last Execution**: Timestamp and status of most recent run

### View Metrics

```bash
# Show all agent metrics
/home/benjamin/.config/.claude/utils/show-agent-metrics.sh

# View doc-converter metrics only
jq '.agents."doc-converter"' .claude/agents/agent-registry.json
```

### Metrics Location

- **Registry**: `.claude/agents/agent-registry.json`
- **Per-invocation logs**: `.claude/data/metrics/agents/doc-converter.jsonl`
- **Hook**: `.claude/hooks/post-subagent-metrics.sh` (automatic updates)
```

---

## Section 3.3: Logging Library Extraction

### 3.3.1 Library Structure Design

**Goal**: Extract 311 lines of logging code from doc-converter.md (lines 1650-1961) into reusable library following adaptive-planning-logger.sh pattern.

**File**: `/home/benjamin/.config/.claude/lib/conversion-logger.sh`

**Design Principles**:
- Follow adaptive-planning-logger.sh structure
- Provide functions for common logging patterns
- Support both script and agent modes
- Enable log rotation
- Export functions for sourcing

### 3.3.2 conversion-logger.sh Implementation

```bash
#!/usr/bin/env bash
#
# Conversion Logger Library
# Provides structured logging for document conversion operations
#
# Usage:
#   source .claude/lib/conversion-logger.sh
#   init_conversion_log "$OUTPUT_DIR/conversion.log"
#   log_conversion_start "file.docx" "markdown"
#   log_conversion_success "file.docx" "file.md" "markitdown" 1500
#   log_conversion_failure "file.docx" "Error message" "markitdown"
#

set -euo pipefail

# Configuration
CONVERSION_LOG_FILE=""
readonly CONVERSION_LOG_MAX_SIZE=$((10 * 1024 * 1024))  # 10MB
readonly CONVERSION_LOG_MAX_FILES=5

#
# init_conversion_log - Initialize conversion log file
#
# Arguments:
#   $1 - Log file path
#   $2 - Input directory (optional)
#   $3 - Output directory (optional)
#
init_conversion_log() {
  CONVERSION_LOG_FILE="$1"
  local input_dir="${2:-}"
  local output_dir="${3:-}"

  # Ensure log directory exists
  mkdir -p "$(dirname "$CONVERSION_LOG_FILE")"

  # Initialize with header
  cat > "$CONVERSION_LOG_FILE" <<EOF
========================================
Document Conversion Log
Started: $(date)
========================================

EOF

  if [[ -n "$input_dir" ]]; then
    echo "Input Directory: $input_dir" >> "$CONVERSION_LOG_FILE"
  fi

  if [[ -n "$output_dir" ]]; then
    echo "Output Directory: $output_dir" >> "$CONVERSION_LOG_FILE"
  fi

  echo "" >> "$CONVERSION_LOG_FILE"
}

#
# rotate_conversion_log_if_needed - Rotate log file if it exceeds max size
#
rotate_conversion_log_if_needed() {
  if [[ ! -f "$CONVERSION_LOG_FILE" ]]; then
    return 0
  fi

  local file_size
  file_size=$(stat -f%z "$CONVERSION_LOG_FILE" 2>/dev/null || stat -c%s "$CONVERSION_LOG_FILE" 2>/dev/null || echo 0)

  if (( file_size >= CONVERSION_LOG_MAX_SIZE )); then
    # Rotate logs: .log -> .log.1, .log.1 -> .log.2, etc.
    for ((i = CONVERSION_LOG_MAX_FILES - 1; i >= 1; i--)); do
      if [[ -f "${CONVERSION_LOG_FILE}.$i" ]]; then
        mv "${CONVERSION_LOG_FILE}.$i" "${CONVERSION_LOG_FILE}.$((i + 1))"
      fi
    done

    # Move current log to .1
    mv "$CONVERSION_LOG_FILE" "${CONVERSION_LOG_FILE}.1"

    # Remove oldest if we exceed max files
    if [[ -f "${CONVERSION_LOG_FILE}.$((CONVERSION_LOG_MAX_FILES + 1))" ]]; then
      rm "${CONVERSION_LOG_FILE}.$((CONVERSION_LOG_MAX_FILES + 1))"
    fi
  fi
}

#
# log_conversion_start - Log the start of a conversion
#
# Arguments:
#   $1 - Input file path
#   $2 - Target format (markdown, docx, pdf)
#
log_conversion_start() {
  local input_file="$1"
  local target_format="$2"

  rotate_conversion_log_if_needed

  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  echo "[$timestamp] START: $(basename "$input_file") -> $target_format" >> "$CONVERSION_LOG_FILE"
}

#
# log_conversion_success - Log a successful conversion
#
# Arguments:
#   $1 - Input file path
#   $2 - Output file path
#   $3 - Tool used (markitdown, pandoc, marker_pdf, pymupdf4llm)
#   $4 - Duration in milliseconds (optional)
#
log_conversion_success() {
  local input_file="$1"
  local output_file="$2"
  local tool_used="$3"
  local duration_ms="${4:-0}"

  rotate_conversion_log_if_needed

  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  local file_size
  if [[ -f "$output_file" ]]; then
    file_size=$(wc -c < "$output_file" 2>/dev/null || echo "0")
  else
    file_size="0"
  fi

  cat >> "$CONVERSION_LOG_FILE" <<EOF
[$timestamp] SUCCESS: $(basename "$input_file")
  Tool: $tool_used
  Output: $(basename "$output_file")
  Size: $file_size bytes
  Duration: ${duration_ms}ms

EOF
}

#
# log_conversion_failure - Log a failed conversion
#
# Arguments:
#   $1 - Input file path
#   $2 - Error message
#   $3 - Tool attempted (optional)
#
log_conversion_failure() {
  local input_file="$1"
  local error_message="$2"
  local tool_attempted="${3:-unknown}"

  rotate_conversion_log_if_needed

  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  cat >> "$CONVERSION_LOG_FILE" <<EOF
[$timestamp] FAILURE: $(basename "$input_file")
  Tool: $tool_attempted
  Error: $error_message

EOF
}

#
# log_conversion_fallback - Log a fallback attempt
#
# Arguments:
#   $1 - Input file path
#   $2 - Primary tool that failed
#   $3 - Fallback tool being tried
#
log_conversion_fallback() {
  local input_file="$1"
  local primary_tool="$2"
  local fallback_tool="$3"

  rotate_conversion_log_if_needed

  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  echo "[$timestamp] FALLBACK: $(basename "$input_file") - $primary_tool failed, trying $fallback_tool" >> "$CONVERSION_LOG_FILE"
}

#
# log_tool_detection - Log tool detection results
#
# Arguments:
#   $1 - Tool name
#   $2 - Available (true/false)
#   $3 - Version (optional)
#
log_tool_detection() {
  local tool_name="$1"
  local available="$2"
  local version="${3:-unknown}"

  rotate_conversion_log_if_needed

  if [[ "$available" == "true" ]]; then
    echo "TOOL DETECTION: $tool_name - AVAILABLE ($version)" >> "$CONVERSION_LOG_FILE"
  else
    echo "TOOL DETECTION: $tool_name - NOT AVAILABLE" >> "$CONVERSION_LOG_FILE"
  fi
}

#
# log_phase_start - Log the start of a conversion phase
#
# Arguments:
#   $1 - Phase name (TOOL DETECTION, CONVERSION, VALIDATION, etc.)
#
log_phase_start() {
  local phase_name="$1"

  rotate_conversion_log_if_needed

  cat >> "$CONVERSION_LOG_FILE" <<EOF

========================================
$phase_name PHASE
========================================

EOF
}

#
# log_phase_end - Log the end of a conversion phase
#
# Arguments:
#   $1 - Phase name
#
log_phase_end() {
  local phase_name="$1"

  rotate_conversion_log_if_needed

  cat >> "$CONVERSION_LOG_FILE" <<EOF
========================================
END: $phase_name PHASE
========================================

EOF
}

#
# log_validation_check - Log a validation check result
#
# Arguments:
#   $1 - File path
#   $2 - Check type (size, structure, magic_number)
#   $3 - Result (pass/fail/warning)
#   $4 - Details
#
log_validation_check() {
  local file_path="$1"
  local check_type="$2"
  local result="$3"
  local details="$4"

  rotate_conversion_log_if_needed

  local symbol
  case "$result" in
    pass) symbol="✓" ;;
    fail) symbol="✗" ;;
    warning) symbol="⚠" ;;
    *) symbol="·" ;;
  esac

  echo "VALIDATION [$symbol $result]: $(basename "$file_path") - $check_type - $details" >> "$CONVERSION_LOG_FILE"
}

#
# log_summary - Log conversion summary statistics
#
# Arguments:
#   $1 - Total files processed
#   $2 - Successful conversions
#   $3 - Failed conversions
#   $4 - Validation failures
#
log_summary() {
  local total="$1"
  local successes="$2"
  local failures="$3"
  local validation_failures="${4:-0}"

  rotate_conversion_log_if_needed

  cat >> "$CONVERSION_LOG_FILE" <<EOF

========================================
CONVERSION SUMMARY
========================================
Total Files Processed: $total
  Successful: $successes
  Failed: $failures
  Validation Failures: $validation_failures

Completed: $(date)
========================================
EOF
}

# Export functions for use in other scripts
export -f init_conversion_log
export -f rotate_conversion_log_if_needed
export -f log_conversion_start
export -f log_conversion_success
export -f log_conversion_failure
export -f log_conversion_fallback
export -f log_tool_detection
export -f log_phase_start
export -f log_phase_end
export -f log_validation_check
export -f log_summary
```

### 3.3.3 Update convert-docs.sh to Source Library

**Add after line 35** (before tool detection):

```bash
# Source conversion logger library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/conversion-logger.sh" ]]; then
  source "$SCRIPT_DIR/conversion-logger.sh"
else
  echo "Warning: conversion-logger.sh not found, using basic logging"
fi
```

**Replace existing log initialization** (around line 352):

```bash
# Initialize log file using library
if command -v init_conversion_log &> /dev/null; then
  init_conversion_log "$LOG_FILE" "$INPUT_DIR" "$OUTPUT_DIR"
else
  # Fallback to basic initialization
  echo "Document Conversion Log - $(date)" > "$LOG_FILE"
  echo "Input Directory: $INPUT_DIR" >> "$LOG_FILE"
  echo "Output Directory: $OUTPUT_DIR" >> "$LOG_FILE"
  echo "" >> "$LOG_FILE"
fi
```

### 3.3.4 Migrate Existing Log Calls

**Update convert_file() function** (lines 491-629) to use library functions:

Before:
```bash
echo "[SUCCESS] $basename → $(basename "$output_file") (tool: $tool_used)" >> "$LOG_FILE"
```

After:
```bash
if command -v log_conversion_success &> /dev/null; then
  log_conversion_success "$input_file" "$output_file" "$tool_used"
else
  echo "[SUCCESS] $basename → $(basename "$output_file") (tool: $tool_used)" >> "$LOG_FILE"
fi
```

**Update validation logging**:

Before:
```bash
echo "[VALIDATION] File not found: $file_path" >> "$LOG_FILE"
```

After:
```bash
if command -v log_validation_check &> /dev/null; then
  log_validation_check "$file_path" "existence" "fail" "File not found"
else
  echo "[VALIDATION] File not found: $file_path" >> "$LOG_FILE"
fi
```

### 3.3.5 Update doc-converter.md Agent Spec

**Remove logging code** (lines 1650-1961) and replace with:

```markdown
## Logging System

I use the shared conversion logging library for consistent log formatting across script and agent modes.

### Logging Functions

Sourced from `.claude/lib/conversion-logger.sh`:

- `init_conversion_log()` - Initialize log file with header
- `log_conversion_start()` - Log conversion start
- `log_conversion_success()` - Log successful conversion with tool info
- `log_conversion_failure()` - Log conversion failure with error details
- `log_conversion_fallback()` - Log fallback tool attempt
- `log_tool_detection()` - Log tool availability
- `log_phase_start()` / `log_phase_end()` - Log phase boundaries
- `log_validation_check()` - Log validation results
- `log_summary()` - Log final summary statistics

### Usage in Agent Mode

When executing bash commands for conversions:

```bash
# Source logging library
source /home/benjamin/.config/.claude/lib/conversion-logger.sh

# Initialize log
init_conversion_log "$OUTPUT_DIR/conversion.log" "$INPUT_DIR" "$OUTPUT_DIR"

# Log conversions
log_conversion_start "document.docx" "markdown"
log_conversion_success "document.docx" "document.md" "markitdown" 1500
```

### Log Rotation

Logs are automatically rotated when exceeding 10MB:
- Maximum 5 rotated files retained
- Oldest files automatically deleted
- Rotation transparent to logging calls
```

**This reduces doc-converter.md from ~1961 lines to ~650 lines** (311 lines of logging code extracted).

### 3.3.6 Testing Logging Consistency

**Create test script**: `/home/benjamin/.config/.claude/tests/test_conversion_logger.sh`

```bash
#!/usr/bin/env bash
#
# Test conversion-logger.sh library
#

set -euo pipefail

source "$(dirname "$0")/../lib/conversion-logger.sh"

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

TEST_LOG="$TEST_DIR/test.log"

echo "Testing conversion logger library..."

# Test 1: Log initialization
init_conversion_log "$TEST_LOG" "/input" "/output"
if [[ ! -f "$TEST_LOG" ]]; then
  echo "FAIL: Log file not created"
  exit 1
fi

# Test 2: Log conversion success
log_conversion_success "/input/test.docx" "/output/test.md" "markitdown" 1500
if ! grep -q "SUCCESS: test.docx" "$TEST_LOG"; then
  echo "FAIL: Success log not written"
  exit 1
fi

# Test 3: Log conversion failure
log_conversion_failure "/input/fail.pdf" "Tool not available" "marker_pdf"
if ! grep -q "FAILURE: fail.pdf" "$TEST_LOG"; then
  echo "FAIL: Failure log not written"
  exit 1
fi

# Test 4: Log validation check
log_validation_check "/input/test.docx" "magic_number" "pass" "Valid DOCX signature"
if ! grep -q "VALIDATION" "$TEST_LOG"; then
  echo "FAIL: Validation log not written"
  exit 1
fi

# Test 5: Log summary
log_summary 10 8 2 0
if ! grep -q "CONVERSION SUMMARY" "$TEST_LOG"; then
  echo "FAIL: Summary not written"
  exit 1
fi

# Test 6: Format consistency
if ! grep -q "========================================" "$TEST_LOG"; then
  echo "FAIL: Missing section separators"
  exit 1
fi

echo ""
echo "All logging tests passed!"
echo "Test log contents:"
cat "$TEST_LOG"
```

### 3.3.7 Documentation

**Create**: `/home/benjamin/.config/.claude/lib/README.md` (or update existing)

Add section:

```markdown
## conversion-logger.sh

Structured logging library for document conversion operations.

### Purpose

Provides consistent logging across:
- Script mode (`convert-docs.sh`)
- Agent mode (`doc-converter.md` agent)

### Features

- Structured log format with timestamps
- Automatic log rotation (10MB, 5 files)
- Phase-based logging
- Tool detection logging
- Validation result logging
- Summary statistics

### Usage

```bash
# Source library
source /home/benjamin/.config/.claude/lib/conversion-logger.sh

# Initialize log
init_conversion_log "/path/to/conversion.log" "/input" "/output"

# Log events
log_conversion_start "file.docx" "markdown"
log_conversion_success "file.docx" "file.md" "markitdown" 1500
log_conversion_failure "bad.pdf" "Corrupted file" "marker_pdf"
log_summary 10 8 2 0
```

### Pattern

Follows adaptive-planning-logger.sh structure:
- Rotation on size threshold
- Structured log entries with timestamps
- Exported functions for sourcing
- ISO 8601 timestamps
- Atomic operations for safety
```

---

## Section 3.4: TodoWrite Integration for Agent

### 3.4.1 Add TodoWrite to Agent Tool Access

**Update doc-converter.md frontmatter** (lines 1-3):

```markdown
---
allowed-tools: Read, Grep, Glob, Bash, Write, TodoWrite
description: Bidirectional document conversion between Markdown, DOCX, and PDF
---
```

### 3.4.2 Define Phase Structure with Tasks

**Add to doc-converter.md** (after line 175):

```markdown
## Task Tracking with TodoWrite

I use TodoWrite to provide visibility into conversion progress through 5 distinct phases.

### Phase Structure

**Phase 1: Tool Detection** (content: "Detect conversion tools", activeForm: "Detecting conversion tools")
- Detect MarkItDown availability
- Detect Pandoc availability
- Detect marker_pdf availability
- Detect PyMuPDF4LLM availability
- Detect PDF engines (Typst, XeLaTeX)

**Phase 2: File Discovery** (content: "Discover convertible files", activeForm: "Discovering convertible files")
- Scan input directory
- Validate file headers
- Categorize by type (DOCX, PDF, MD)
- Determine conversion direction

**Phase 3: Conversion Execution** (content: "Convert files", activeForm: "Converting files")
- Process DOCX files
- Process PDF files
- Process Markdown files
- Apply automatic fallbacks
- Track success/failure

**Phase 4: Validation** (content: "Validate conversions", activeForm: "Validating conversions")
- Check output files exist
- Verify file sizes
- Validate structure (headings, tables)
- Identify quality warnings

**Phase 5: Reporting** (content: "Generate summary report", activeForm: "Generating summary report")
- Calculate statistics
- Log detailed results
- Report missing tools
- Provide next steps

### Task Update Timing

- **Phase Start**: Mark task as `in_progress` before beginning phase
- **Phase End**: Mark task as `completed` immediately after finishing
- **Constraint**: Only ONE task `in_progress` at a time

### Example TodoWrite Usage

```lua
-- Initialize task list at start
TodoWrite({
  todos: [
    {content: "Detect conversion tools", status: "pending", activeForm: "Detecting conversion tools"},
    {content: "Discover convertible files", status: "pending", activeForm: "Discovering convertible files"},
    {content: "Convert files", status: "pending", activeForm: "Converting files"},
    {content: "Validate conversions", status: "pending", activeForm: "Validating conversions"},
    {content: "Generate summary report", status: "pending", activeForm: "Generating summary report"}
  ]
})

-- Mark Phase 1 in progress
TodoWrite({
  todos: [
    {content: "Detect conversion tools", status: "in_progress", activeForm: "Detecting conversion tools"},
    {content: "Discover convertible files", status: "pending", activeForm: "Discovering convertible files"},
    {content: "Convert files", status: "pending", activeForm: "Converting files"},
    {content: "Validate conversions", status: "pending", activeForm: "Validating conversions"},
    {content: "Generate summary report", status: "pending", activeForm: "Generating summary report"}
  ]
})

-- Complete Phase 1, start Phase 2
TodoWrite({
  todos: [
    {content: "Detect conversion tools", status: "completed", activeForm: "Detecting conversion tools"},
    {content: "Discover convertible files", status: "in_progress", activeForm: "Discovering convertible files"},
    {content: "Convert files", status: "pending", activeForm: "Converting files"},
    {content: "Validate conversions", status: "pending", activeForm: "Validating conversions"},
    {content: "Generate summary report", status: "pending", activeForm: "Generating summary report"}
  ]
})
```
```

### 3.4.3 Update Agent Behavioral Guidelines

**Add to doc-converter.md** (after line 145):

```markdown
### Progress Transparency with TodoWrite

When invoked in agent mode, I use TodoWrite to provide clear progress visibility:

1. **Initialize Task List**: Create 5-phase task list at start of conversion
2. **Mark Progress**: Update task status at phase boundaries
3. **One Task Active**: Only mark one task as `in_progress` at a time
4. **Complete Immediately**: Mark tasks `completed` as soon as phase finishes
5. **User Visibility**: Tasks appear in UI for real-time progress tracking

This complements PROGRESS markers for status updates:
- **PROGRESS markers**: Brief status messages during conversion
- **TodoWrite**: Structured phase tracking with completion status
```

### 3.4.4 Integration with Conversion Workflow

**Update doc-converter.md Conversion Workflow section** (around line 236):

```markdown
### Conversion Workflow with Task Tracking

1. **Initialize TodoWrite** with 5 phases (all `pending`)

2. **Tool Detection Phase**
   - Mark "Detect conversion tools" as `in_progress`
   - Detect available conversion tools
   - Select best available tool for each file type
   - Report which tools will be used
   - Mark "Detect conversion tools" as `completed`

3. **Discovery Phase**
   - Mark "Discover convertible files" as `in_progress`
   - Scan input directory for DOCX, PDF, and MD files
   - Validate files (magic numbers, corruption checks)
   - Count files by type
   - Report findings
   - Mark "Discover convertible files" as `completed`

4. **Conversion Phase**
   - Mark "Convert files" as `in_progress`
   - Process files with primary tools
   - Apply automatic fallback on failures
   - Track successes and failures
   - Emit PROGRESS for each file
   - Mark "Convert files" as `completed`

5. **Validation Phase**
   - Mark "Validate conversions" as `in_progress`
   - Check files created
   - Validate image references
   - Count headings and tables
   - Identify quality warnings
   - Mark "Validate conversions" as `completed`

6. **Reporting Phase**
   - Mark "Generate summary report" as `in_progress`
   - Generate summary statistics
   - List failed conversions
   - Report quality warnings
   - Provide next steps
   - Mark "Generate summary report" as `completed`
```

### 3.4.5 Testing TodoWrite Integration

**Manual Test Procedure**:

1. Invoke doc-converter agent via Task tool:
```
Task {
  subagent_type: "general-purpose"
  description: "Test TodoWrite integration"
  prompt: |
    Read and follow: /home/benjamin/.config/.claude/agents/doc-converter.md

    Convert files in test directory with TodoWrite tracking enabled.
    Input: /tmp/test-docs
    Output: /tmp/converted
}
```

2. Verify TodoWrite updates appear in UI during conversion

3. Check all phases marked `completed` at end

4. Verify only ONE task was `in_progress` at any time

### 3.4.6 Document TodoWrite Behavior

**Update**: `/home/benjamin/.config/.claude/commands/convert-docs.md`

Add section after Agent Mode Workflow (around line 130):

```markdown
## Agent Mode Task Tracking

When using agent mode (`--use-agent` flag), the doc-converter agent provides real-time progress through TodoWrite:

### Visible Phases

1. ☐ Detect conversion tools
2. ☐ Discover convertible files
3. ☐ Convert files
4. ☐ Validate conversions
5. ☐ Generate summary report

### Progress Indicators

- **Pending (☐)**: Phase not yet started
- **In Progress (▶)**: Currently executing phase
- **Completed (✓)**: Phase finished successfully

### Task Lifecycle

Each phase follows this pattern:
1. Mark task `in_progress` when starting phase
2. Execute phase operations
3. Mark task `completed` immediately when phase finishes
4. Move to next phase (only one active at a time)

### Benefits

- **Real-time visibility**: See which phase is currently running
- **Progress estimation**: Know how far along the conversion is
- **Debugging**: Identify which phase encountered issues
- **User experience**: Clear indication of agent activity
```

---

## Testing Strategy

### Integration Tests

1. **Validation Integration Test**
   - Create test files: valid DOCX, corrupted DOCX, valid PDF, fake PDF
   - Run convert-docs.sh with test files
   - Verify: Invalid files skipped, validation count accurate, log entries present

2. **Agent Registry Integration Test**
   - Register doc-converter agent manually
   - Invoke agent via Task tool
   - Verify: Registry updated with metrics, success/failure tracked correctly

3. **Logging Library Test**
   - Source conversion-logger.sh
   - Call each logging function
   - Verify: Log format consistent, rotation works, all entries present

4. **TodoWrite Integration Test**
   - Invoke doc-converter agent
   - Monitor TodoWrite updates during execution
   - Verify: All 5 phases tracked, only one in_progress, all completed at end

### End-to-End Test

**Scenario**: Convert mixed batch with validation, logging, metrics, and task tracking

```bash
# Setup test environment
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/input" "$TEST_DIR/output"

# Create test files
echo "%PDF-1.4" > "$TEST_DIR/input/valid.pdf"
echo "NOT A PDF" > "$TEST_DIR/input/fake.pdf"
touch "$TEST_DIR/input/empty.docx"
echo "# Test" > "$TEST_DIR/input/valid.md"

# Run conversion with agent mode
/convert-docs "$TEST_DIR/input" "$TEST_DIR/output" --use-agent

# Verify outcomes
# 1. Validation: fake.pdf and empty.docx skipped
grep "VALIDATION" "$TEST_DIR/output/conversion.log"

# 2. Registry: doc-converter metrics updated
jq '.agents."doc-converter".total_invocations' .claude/agents/agent-registry.json

# 3. Logging: Consistent format across all phases
grep "========================================" "$TEST_DIR/output/conversion.log"

# 4. TodoWrite: All phases completed (check UI or agent output)
```

---

## Error Handling

### Validation Failures
- **Empty files**: Skip with warning, increment counter
- **Magic number mismatch**: Skip with detailed error (expected vs actual)
- **Unreadable files**: Skip with permission error message
- **Corrupted files**: Skip with corruption indicator

### Registry Update Failures
- **jq not available**: Silent fallback, no metrics tracking
- **Agent not registered**: Warning message, continue execution
- **Write failures**: Log error, continue (metrics update is non-critical)

### Logging Library Failures
- **Library not found**: Fallback to basic echo-based logging
- **Rotation failures**: Continue with current log (no rotation)
- **Disk full**: Truncate log, continue conversion

### TodoWrite Integration Failures
- **TodoWrite not available**: Continue without task tracking
- **Update failures**: Log error, continue conversion (non-critical)

---

## Performance Considerations

### Validation Overhead
- Magic number check: ~1-2ms per file (reads first 4 bytes only)
- File type detection: ~5-10ms per file (calls `file` command)
- **Total overhead**: ~10-15ms per file (negligible compared to conversion time)

### Registry Update Overhead
- jq operations: ~50-100ms per update
- Atomic writes: ~10-20ms per update
- **Impact**: Only on agent completion (one-time cost)

### Logging Library Overhead
- Function calls: <1ms per log entry
- Rotation check: <1ms (stat call)
- **Impact**: Negligible (<1% of total execution time)

### TodoWrite Overhead
- Update calls: ~50-100ms per phase transition
- 5 phases = ~500ms total overhead
- **Impact**: <1% for typical conversions (conversions take seconds to minutes)

---

## Migration Plan

### Phase 3.1: Input Validation (4 hours)
1. Implement validate_input_file() function (1 hour)
2. Integrate into discovery loops (1 hour)
3. Add validation counters and reporting (1 hour)
4. Create test suite (1 hour)

### Phase 3.2: Agent Registry (6 hours)
1. Design registry schema and update existing file (1 hour)
2. Implement agent-registry-utils.sh (2 hours)
3. Register doc-converter agent (1 hour)
4. Create show-agent-metrics.sh tool (1 hour)
5. Test metrics tracking with actual agent runs (1 hour)

### Phase 3.3: Logging Library (8 hours)
1. Create conversion-logger.sh library (3 hours)
2. Update convert-docs.sh to source library (1 hour)
3. Refactor doc-converter.md to source library (2 hours)
4. Migrate existing log calls (1 hour)
5. Test logging consistency (1 hour)

### Phase 3.4: TodoWrite Integration (4 hours)
1. Update agent frontmatter with TodoWrite tool (0.5 hours)
2. Define 5-phase task structure (1 hour)
3. Update agent workflow with task tracking (1.5 hours)
4. Test TodoWrite integration (1 hour)

---

## Success Criteria

### Validation Success
- [ ] validate_input_file() correctly identifies empty files
- [ ] Magic number checks detect DOCX/PDF format mismatches
- [ ] Validation counter accurately tracks skipped files
- [ ] Test suite passes all validation scenarios

### Registry Integration Success
- [ ] doc-converter registered in agent-registry.json
- [ ] Metrics updated automatically after agent runs
- [ ] show-agent-metrics.sh displays correct statistics
- [ ] Registry updates are atomic (no corruption under concurrent access)

### Logging Library Success
- [ ] conversion-logger.sh follows adaptive-planning-logger.sh pattern
- [ ] convert-docs.sh successfully sources library
- [ ] doc-converter.md reduced from ~1961 to ~650 lines
- [ ] Log format consistent between script and agent modes
- [ ] Log rotation works correctly at 10MB threshold

### TodoWrite Integration Success
- [ ] TodoWrite tool added to agent frontmatter
- [ ] All 5 phases tracked with correct activeForm values
- [ ] Only one task in_progress at any time
- [ ] All tasks marked completed at end of successful conversion
- [ ] Task updates visible in UI during agent execution

---

## Rollback Plan

If Phase 3 encounters critical issues:

1. **Validation**: Remove validation checks from discovery loops, revert to simple find commands
2. **Registry**: Remove agent registry updates (metrics tracking is non-essential)
3. **Logging**: Revert to direct echo statements in convert-docs.sh and doc-converter.md
4. **TodoWrite**: Remove TodoWrite from agent tools, rely on PROGRESS markers only

All changes are additive and can be individually reverted without breaking core conversion functionality.

---

## Appendix: File Reference Summary

### Files Created
- `/home/benjamin/.config/.claude/lib/conversion-logger.sh` (new, ~350 lines)
- `/home/benjamin/.config/.claude/lib/agent-registry-utils.sh` (new, ~250 lines)
- `/home/benjamin/.config/.claude/utils/show-agent-metrics.sh` (new, ~80 lines)
- `/home/benjamin/.config/.claude/tests/test_convert_docs_validation.sh` (new, ~70 lines)
- `/home/benjamin/.config/.claude/tests/test_conversion_logger.sh` (new, ~50 lines)

### Files Modified
- `/home/benjamin/.config/.claude/lib/convert-docs.sh` (add validate_input_file after line 750, source logger at line 35, update logging calls)
- `/home/benjamin/.config/.claude/agents/doc-converter.md` (update frontmatter, add TodoWrite integration, remove lines 1650-1961, add library sourcing)
- `/home/benjamin/.config/.claude/agents/agent-registry.json` (add doc-converter entry)
- `/home/benjamin/.config/.claude/commands/convert-docs.md` (add Validation, Agent Metrics, and TodoWrite sections)

### Integration Points
- **post-subagent-metrics.sh**: Already exists, automatically updates registry (no changes needed)
- **adaptive-planning-logger.sh**: Pattern reference for conversion-logger.sh (read-only reference)

### Total Line Counts
- Lines added: ~850 (new files)
- Lines removed: ~311 (extracted from doc-converter.md)
- Net change: +539 lines
