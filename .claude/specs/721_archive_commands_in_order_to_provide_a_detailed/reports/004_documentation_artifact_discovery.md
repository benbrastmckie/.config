# Documentation and Artifact Discovery (list.md, document.md) Research Report

## Metadata
- **Date**: 2025-11-15
- **Agent**: research-specialist
- **Topic**: Documentation and Artifact Discovery
- **Report Type**: codebase analysis
- **Complexity Level**: 4

## Executive Summary

The archived list.md and document.md commands implement complementary artifact discovery and documentation management systems. list.md achieves 85-90% context reduction through metadata-only reads (first 50-100 lines) using lib/metadata-extraction.sh, supporting progressive plan structures (L0/L1/L2) with visual indicators. document.md orchestrates CLAUDE.md-based documentation updates via Task delegation, enforcing UTF-8 encoding, no-emoji policies, cross-reference validation, and timeless writing standards through automated compliance checks.

## Findings

### Finding 1: list.md - Optimized Artifact Discovery with Progressive Plan Support

**Location**: /home/benjamin/.config/.claude/archive/commands/list.md (lines 1-260)

**Core Mechanism**: Metadata-only reads achieve 85-90% context reduction:
- Plans: First 50 lines extracted via `extract_plan_metadata()` (metadata-extraction.sh:89-150)
- Reports: First 100 lines extracted via `extract_report_metadata()` (metadata-extraction.sh:13-87)
- Summaries: First 100 lines (metadata + overview sections)

**Progressive Plan Structure Awareness** (lines 46-50):
- **Level 0 (L0)**: Single-file plans (`NNN_name.md`) - all phases inline
- **Level 1 (L1)**: Phase-expanded plans (`NNN_name/`) - some phases in separate files
- **Level 2 (L2)**: Stage-expanded plans - phases have stage subdirectories
- Detection: `parse-adaptive-plan.sh detect_structure_level` (referenced line 80)

**Output Format with Visual Indicators** (lines 88-95):
```
[L0] 001_feature_name           ○ 5 phases   2025-10-07
[L1] 025_another_feature (P:2,5) ⏳ 8 phases   2025-10-06
[L2] 033_complex (P:1[S:2,3])   ✓ 6 phases   2025-10-05
```

Indicators: Level markers, status symbols (✓/⏳/○), expansion details (P:N for phases, S:N for stages)

**Artifact Types Supported** (lines 19-23):
- **plans**: Implementation plans (all L0/L1/L2 structures)
- **reports**: Research reports
- **summaries**: Implementation summaries
- **all**: Combined view with cross-references

**Filtering Options** (lines 26-29):
- `--recent N`: Show N most recent items by date
- `--incomplete`: Filter to incomplete plans only
- `search-pattern`: Case-insensitive title/filename matching

**Discovery Process** (lines 62-84):
1. Find Level 0 plans: `*.md` files in `specs/plans/` (not in subdirectories)
2. Find Level 1/2 plans: Directories in `specs/plans/` with overview files
3. Extract metadata using `get_plan_metadata()` from artifact-creation.sh
4. Detect structure level via parse-adaptive-plan.sh
5. Check completion status via plan parsing

### Finding 2: document.md - Documentation Standards Enforcement via CLAUDE.md

**Location**: /home/benjamin/.config/.claude/archive/commands/document.md (lines 1-169)

**Five-Phase Documentation Update Process**:

**Phase 0: Initialize and Verify Scope** (lines 19-43):
- CLAUDE_PROJECT_DIR detection via Standard 13
- Argument parsing: `[change-description] [scope]`
- Scope validation (directory existence)
- File discovery: Find all `*.md` files in scope
- Checkpoint: Report validation status and file count

**Phase 1: Load Documentation Standards** (lines 45-60):
- Find CLAUDE.md in project root (maxdepth 1)
- Extract `<!-- SECTION: documentation_policy -->` section (line 58)
- Fallback: Use defaults if CLAUDE.md missing (line 54)
- Default standards: UTF-8, no emojis, README per directory

**Phase 2: Identify Documentation Updates Needed** (lines 62-83):
- Task tool delegation to specialized agent (line 65)
- Agent analyzes codebase scope for:
  - Directories missing README.md files
  - Outdated documentation based on code changes
  - Missing API documentation
  - Broken cross-references
  - Non-compliant documentation (emojis, wrong encoding)

**Phase 3: Update Documentation** (lines 85-118):
- Perform actual documentation updates
- Compliance checks after updates (lines 96-112):
  - UTF-8 encoding verification via `file` command (line 101)
  - Emoji detection via grep Unicode ranges (line 107)
  - Error counting and reporting (line 115)

**Phase 4: Verify Cross-References** (lines 120-148):
- Extract markdown links: `\[.*?\]\(([^)]+)\)` pattern (line 127)
- Skip external URLs (http/https) (line 131)
- Resolve relative paths to absolute (line 134)
- Verify target file/directory existence (line 136)
- Report broken links for manual review

**Phase 5: Report Completion** (lines 150-164):
- Comprehensive checkpoint report with scope, file count, compliance status, broken links

**Standards Enforcement** (from document-command-guide.md:248-280):
- **Documentation Policy**: README per subdirectory, UTF-8 encoding, no emojis, Unicode box-drawing
- **Timeless Writing Policy**: Avoid temporal markers ("(New)", "recently"), migration language, version references

### Finding 3: Metadata Extraction Architecture - Section-Based Lazy Loading

**Location**: /home/benjamin/.config/.claude/lib/metadata-extraction.sh (lines 1-655)

**Core Functions**:

**1. extract_report_metadata()** (lines 13-87):
- Reads first 100 lines of report file
- Extracts title from first `# ` heading (line 27)
- Extracts 50-word summary from Executive Summary via `get_report_section()` (line 31)
- Fallback: First 50 words from content after title (line 38)
- Extracts file paths from code blocks (line 42)
- Extracts 3-5 recommendations from Recommendations section (line 47)
- Returns JSON with title, summary, paths, recommendations, file size

**2. extract_plan_metadata()** (lines 89-150):
- Reads first 50 lines of plan file (line 103)
- Extracts title, date, phase count (lines 106-113)
- Extracts complexity from Risk field (line 117)
- Counts success criteria checkboxes (line 126)
- Returns JSON with title, date, phases, complexity, time estimate

**3. get_report_section()** (lines 496-527):
- Generic section extractor by heading pattern
- Finds section start: `grep -n "^## .*$section_pattern"` (line 511)
- Finds section end: Next `^## ` heading or EOF (line 519)
- Extracts content between start and end lines via sed (lines 522-526)

**Section-Based Extraction Pattern**:
```bash
# 1. Call get_report_section to extract specific section
exec_summary=$(get_report_section "$report_path" "Executive Summary")

# 2. Parse section content for specific data
summary=$(echo "$exec_summary" | grep -v '^#' | head -5 | tr '\n' ' ')

# 3. Return extracted data without reading full file
```

**Exported Functions** (lines 652-655): get_report_metadata, get_plan_phase, get_plan_section, get_report_section

### Finding 4: Cross-Command Integration Patterns and Artifact Registry

**Artifact Creation Library Integration** (/home/benjamin/.config/.claude/lib/artifact-creation.sh:1-150):

**1. Topic-Based Artifact Creation** (lines 14-84):
- `create_topic_artifact()` supports topic-based directory structure
- Artifact types validated: debug, scripts, outputs, artifacts, backups, data, logs, notes, reports, plans (lines 30-38)
- Gitignore behavior: debug committed, others gitignored (lines 26-29)
- Two modes:
  - **Path-only mode**: Calculate path without creating directory (lazy creation, lines 43-54)
  - **File creation mode**: Create directory and file with content (lines 56-84)

**2. Artifact Numbering** (lines 134-150):
- `get_next_artifact_number()` finds highest NNN in `[0-9][0-9][0-9]_*.md` files
- Strips leading zeros to avoid octal interpretation: `$((10#$num))` (line 150)
- Returns next sequential number (001, 002, 003...)

**3. Artifact Registry Integration** (lines 74-82):
- Registers artifact with metadata: topic, type, number
- Uses jq to build metadata JSON (lines 75-79)
- Calls `register_artifact()` from artifact-registry.sh (line 81)

**Document.md Integration with list.md**:
- list.md discovers documentation files via metadata extraction
- document.md updates discovered files using Task delegation
- Both use CLAUDE.md as single source of truth for standards

**Library Dependency Chain**:
```
list.md → artifact-creation.sh → artifact-registry.sh
         → metadata-extraction.sh → base-utils.sh
                                  → unified-logger.sh

document.md → detect-project-dir.sh
           → Task tool (agent delegation)
           → CLAUDE.md (standards source)
```

**Metadata-Only Read Performance**:
- `get_plan_metadata()`: Reads first 50 lines only
- `get_report_metadata()`: Reads first 100 lines only
- Achieves 85-90% context reduction across large artifact sets

## Recommendations

### 1. Preserve Metadata-Only Read Pattern for New Artifact Discovery Features

**Rationale**: The 85-90% context reduction through metadata-extraction.sh (first 50-100 lines) enables scalable artifact listing without loading entire files.

**Application**: When implementing new artifact discovery:
- Use `extract_plan_metadata()` for plans (first 50 lines)
- Use `extract_report_metadata()` for reports (first 100 lines)
- Use `get_report_section()` for targeted section extraction
- Avoid reading full files unless content analysis required

**Evidence**: list.md lines 34-42 document ~88% reduction for plans (1.5MB → 180KB).

### 2. Adopt Progressive Plan Structure Detection for All Plan-Aware Commands

**Rationale**: list.md's L0/L1/L2 structure awareness (lines 46-50) provides clear visual indicators of plan complexity and expansion state.

**Implementation Pattern**:
```bash
LEVEL=$(parse-adaptive-plan.sh detect_structure_level "$PLAN_PATH")
case "$LEVEL" in
  0) echo "[L0] single-file plan" ;;
  1) echo "[L1] phase-expanded plan (P:2,5)" ;;
  2) echo "[L2] stage-expanded plan (P:1[S:2,3])" ;;
esac
```

**Applicable Commands**: /implement, /expand, /collapse, /plan-wizard.

### 3. Extract CLAUDE.md Standards Enforcement Pattern for Reusable Library

**Rationale**: document.md's standards enforcement (lines 45-60, 96-118) should become reusable library function.

**Proposed Function** (for lib/standards-compliance.sh):
```bash
validate_documentation_compliance() {
  local file_path="${1:-}"
  # Load CLAUDE.md standards
  # UTF-8 encoding check
  # Emoji check
  # Timeless writing check
  return $error_count
}
```

**Benefits**: Reusable across /document, /setup, /validate-setup.

### 4. Unify Artifact Discovery Across list.md Filters and Search Patterns

**Rationale**: list.md filtering (--recent, --incomplete, search-pattern) implemented separately for each artifact type.

**Proposed Abstraction**:
```bash
filter_artifacts() {
  local artifacts_json="$1"
  local filter_type="$2"
  local filter_value="$3"
  # Apply jq filters based on type
}
```

**Application**: Replace separate filtering logic in list.md lines 160-197 with unified function.

### 5. Implement Cross-Reference Validation as Standalone Utility

**Rationale**: document.md's cross-reference validation (lines 120-148) useful beyond documentation updates.

**Proposed Utility** (for lib/cross-reference-validator.sh):
```bash
validate_markdown_links() {
  local file_path="${1:-}"
  # Extract links, validate existence, return broken count
}
```

**Integration Points**: Pre-commit hooks, /validate-setup, CI pipelines, /document Phase 4.

## References

- /home/benjamin/.config/.claude/archive/commands/list.md (lines 1-260)
- /home/benjamin/.config/.claude/archive/commands/document.md (lines 1-169)
- /home/benjamin/.config/.claude/docs/guides/document-command-guide.md (lines 1-670)
- /home/benjamin/.config/.claude/lib/metadata-extraction.sh (lines 1-655)
- /home/benjamin/.config/.claude/lib/artifact-creation.sh (lines 1-150)
