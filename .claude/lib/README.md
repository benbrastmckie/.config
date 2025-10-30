# Shared Utility Libraries

This directory contains 42 modular utility libraries used across Claude Code commands, organized by domain and responsibility following the clean-break refactor of 2025-10-14.

**Recent Cleanup (October 2025)**: 25 unused scripts archived to `.claude/archive/lib/cleanup-2025-10-26/` (see [Archive Manifest](../archive/lib/cleanup-2025-10-26/README.md) for details). Library size reduced by ~13%.

**Note**: This README documents **sourced utility libraries** (functions that are sourced into other scripts). For documentation of **standalone utility scripts** (executable scripts), see [UTILS_README.md](UTILS_README.md).

## Table of Contents

- [Purpose](#purpose)
- [Library Classification](#library-classification)
  - [Core Libraries](#core-libraries-required-by-all-commands)
  - [Workflow Libraries](#workflow-libraries-orchestration-commands)
  - [Specialized Libraries](#specialized-libraries-single-command-use-cases)
  - [Optional Libraries](#optional-libraries-can-be-disabled)
  - [Sourcing Best Practices](#sourcing-best-practices)
  - [Array Deduplication Implementation](#array-deduplication-implementation)
- [Module Organization](#module-organization)
- [Core Modules](#core-modules)
  - [Parsing & Plans](#parsing--plans)
  - [Artifact Management](#artifact-management)
  - [Error Handling & Validation](#error-handling--validation)
  - [Document Conversion](#document-conversion)
  - [Adaptive Planning](#adaptive-planning)
  - [Agent Coordination](#agent-coordination)
  - [Analysis & Metrics](#analysis--metrics)
  - [Template System](#template-system)
  - [Infrastructure](#infrastructure)
- [Module Dependencies](#module-dependencies)
- [Usage Guidelines](#usage-guidelines)
- [Testing](#testing)
- [Neovim Integration](#neovim-integration)

## Purpose

Extracting common functionality to shared libraries:
- **Reduces code duplication** (~300-400 LOC saved across commands)
- **Improves maintainability** (update once, applies everywhere)
- **Increases testability** (utilities can be unit tested independently)
- **Ensures consistency** (same logic used by all commands)
- **Single responsibility** (each module focused on one domain)

## Library Classification

Libraries are classified by usage pattern to help commands source only what they need:

### Core Libraries (Required by All Commands)
Essential utilities sourced automatically by all orchestration commands via `library-sourcing.sh`:

- **unified-location-detection.sh** - Standard path resolution (85% token reduction, 25x speedup vs agent-based detection)
- **error-handling.sh** - Fail-fast error handling, retry logic, and logging
- **checkpoint-utils.sh** - State preservation for resumable workflows
- **unified-logger.sh** - Progress logging utilities with structured output
- **workflow-detection.sh** - Workflow scope detection functions
- **metadata-extraction.sh** - 99% context reduction through metadata-only passing
- **context-pruning.sh** - Context management utilities for budget control

### Workflow Libraries (Orchestration Commands)
Used by `/orchestrate`, `/coordinate`, `/supervise`, `/implement`:

- **parallel-execution.sh** - Wave-based parallel implementation (40-60% time savings)
- **dependency-analyzer.sh** - Wave-based execution analysis
- **complexity-utils.sh** - Complexity analysis and threshold detection
- **adaptive-planning-logger.sh** - Structured logging for adaptive events
- **plan-core-bundle.sh** - Core plan parsing functions (phases, stages, metadata)
- **progress-dashboard.sh** - Real-time progress tracking visualization

### Specialized Libraries (Single-Command Use Cases)
Command-specific utilities with narrow scope:

- **convert-*.sh** (convert-core.sh, convert-docx.sh, convert-pdf.sh, convert-markdown.sh) - Document conversion (only /convert-docs)
- **analyze-metrics.sh** - Performance and workflow metrics analysis (only /analyze)
- **template-*.sh** (parse-template.sh, substitute-variables.sh, template-integration.sh) - Template system (only /plan-from-template, /plan-wizard)
- **agent-*.sh** (agent-registry-utils.sh, agent-invocation.sh) - Agent management (only orchestration commands)

### Optional Libraries (Can Be Disabled)
Feature-specific utilities that can be excluded without breaking core functionality:

- **auto-analysis-utils.sh** - Automatic complexity analysis (can use manual complexity evaluation instead)
- **timestamp-utils.sh** - Timestamp formatting (can use raw date commands)
- **json-utils.sh** - JSON processing (can use direct jq calls)

### Sourcing Best Practices

**Use `source_required_libraries()` when:**
- Building orchestration commands that need core + workflow libraries
- Adding optional libraries via function parameters
- Benefits from automatic deduplication (prevents re-sourcing duplicates)

**Use direct sourcing when:**
- Command only needs 1-2 specific libraries
- Library is specialized/command-specific
- Avoids loading unnecessary core libraries

**Example Usage:**
```bash
# Orchestration command (uses library-sourcing.sh)
source .claude/lib/library-sourcing.sh
source_required_libraries "dependency-analyzer.sh" || exit 1

# Specialized command (direct sourcing)
source .claude/lib/convert-core.sh
source .claude/lib/conversion-logger.sh
```

### Array Deduplication Implementation

**Problem Solved**: The `/coordinate` timeout was caused by passing 6 duplicate library names to `source_required_libraries()`, which blindly re-sourced them, causing excessive loading time (>120s).

**Solution**: 20-line array deduplication removes duplicates before sourcing, directly solving the parameter duplication problem.

**Algorithm**:
```bash
# O(n²) string matching (acceptable for n≈10 libraries)
local unique_libs=()
local seen=" "
for lib in "${libraries[@]}"; do
  if [[ ! "$seen" =~ " $lib " ]]; then
    unique_libs+=("$lib")
    seen+="$lib "
  fi
done
```

**Trade-offs**:
- **Benefits**: Directly solves duplicate parameter problem, no global state management, 93% less code than memoization (20 lines vs 310)
- **Limitations**: Not idempotent across multiple function calls (acceptable since commands run in isolated processes where multiple calls don't occur)
- **Performance**: <0.01ms overhead, preserves first occurrence order

**Why Not Memoization?**: Research showed memoization (310 lines, global state, 10 tests) was over-engineered for the problem. The root cause was duplicate parameters, not repeated function calls across the session. Deduplication solves it directly with 93% less code.

**Decision Rationale**: "Cross-call persistence value is theoretical (commands don't call source_required_libraries multiple times)" - Memoization optimizes scenarios that don't occur in practice.

## Module Organization

After the refactor, the library is organized into functional domains:

### Parsing & Plans (3 modules)
- `parse-plan-core.sh` - Core plan parsing (phases, stages)
- `plan-structure-utils.sh` - Structure operations (expansion, collapse)
- `plan-metadata-utils.sh` - Metadata extraction and manipulation

### Artifact Management (2 modules)
- `artifact-creation.sh` - Artifact creation and workflow integration
- `artifact-registry.sh` - Artifact tracking and querying

### Error Handling & Validation (1 module)
- `error-handling.sh` - Error classification, recovery, retry logic

### Document Conversion (5 modules)
- `convert-core.sh` - Conversion orchestration
- `convert-docx.sh` - DOCX conversion functions
- `convert-pdf.sh` - PDF conversion functions
- `convert-markdown.sh` - Markdown validation
- `conversion-logger.sh` - Conversion logging

### Adaptive Planning (3 modules)
- `adaptive-planning-logger.sh` - Structured logging for adaptive events
- `checkpoint-utils.sh` - Checkpoint management for workflow resume
- `complexity-utils.sh` - Complexity analysis and threshold detection

### Agent Coordination (3 modules)
- `agent-registry-utils.sh` - Agent registry operations
- `agent-invocation.sh` - Agent coordination and invocation
- `workflow-detection.sh` - Workflow scope detection and phase execution logic

### Analysis & Metrics (2 modules)
- `analysis-pattern.sh` - Common phase/stage analysis patterns
- `analyze-metrics.sh` - Performance and workflow metrics

### Template System (3 modules)
- `parse-template.sh` - Template file parsing
- `substitute-variables.sh` - Variable substitution in templates
- `template-integration.sh` - Template system integration

### Infrastructure (6 modules)
- `progress-dashboard.sh` - Real-time progress tracking
- `auto-analysis-utils.sh` - Automatic analysis orchestration
- `timestamp-utils.sh` - Timestamp utilities
- `json-utils.sh` - JSON processing utilities
- `deps-utils.sh` - Dependency checking utilities
- `detect-project-dir.sh` - Project directory detection

## Core Modules

### Recent Consolidation (Stage 3 - October 2025)

Following Stage 3 of the directory optimization, several utilities have been consolidated for improved maintainability:

#### plan-core-bundle.sh (1,159 lines) - NEW
**Consolidates**: parse-plan-core.sh, plan-structure-utils.sh, plan-metadata-utils.sh

Core planning utilities bundled into a single module. The original files now act as lightweight wrappers that source this bundle.

**Key Functions:** All functions from the three consolidated modules
- Plan parsing (extract_phase_name, extract_phase_content, parse_phase_list)
- Structure operations (detect_structure_level, is_phase_expanded, list_expanded_phases)
- Metadata manipulation (add_phase_metadata, update_structure_level, merge_phase_into_plan)

**Usage Example:**
```bash
# New way (recommended)
source .claude/lib/plan-core-bundle.sh

# Old way (still works via wrapper)
source .claude/lib/parse-plan-core.sh
```

**Benefits:** Reduced sourcing overhead (3 files → 1), consistent function availability, simplified imports

---

#### unified-logger.sh (717 lines) - NEW
**Consolidates**: adaptive-planning-logger.sh, conversion-logger.sh

Unified logging interface for all operation types. The original logger files now act as wrappers that source this unified logger.

**Key Functions:** All functions from both loggers
- Adaptive planning events (log_complexity_check, log_replan_invocation, log_loop_prevention)
- Conversion operations (log_conversion_start, log_conversion_success, log_tool_detection)
- Common logging (init_log, rotate_log_file, query_log)

**Usage Example:**
```bash
# New way (recommended)
source .claude/lib/unified-logger.sh

# Old way (still works via wrapper)
source .claude/lib/adaptive-planning-logger.sh
```

**Benefits:** Consistent logging interface, reduced duplication, single log format standard

---

#### base-utils.sh (~100 lines) - NEW
**Purpose**: Common utility functions to eliminate circular dependencies

Provides base functions used across multiple utilities, eliminating 4 duplicate `error()` function implementations.

**Key Functions:**
- `error()` - Print error message and exit
- `warn()` - Print warning message
- `info()` - Print info message
- `debug()` - Print debug message (if DEBUG=1)
- `require_command()` - Check for required command
- `require_file()` - Check for required file
- `require_dir()` - Check for required directory

**Usage Example:**
```bash
source .claude/lib/base-utils.sh

# Use common error function
error "Configuration file not found"

# Check for required tools
require_command "jq" "Please install jq: sudo apt install jq"
```

**Benefits:** Zero dependencies (breaks circular dependency cycles), consistent error handling, eliminates code duplication

---

### Parsing & Plans

#### parse-plan-core.sh (140 lines)

Core parsing functions for extracting phases and stages from implementation plans.

**Key Functions:**
- `extract_phase_name()` - Extract phase name from heading
- `extract_phase_content()` - Extract full phase content
- `extract_stage_name()` - Extract stage name from heading
- `extract_stage_content()` - Extract full stage content
- `parse_phase_list()` - Get list of all phases in plan

**Usage Example:**
```bash
source .claude/lib/parse-plan-core.sh

# Extract phase content
PHASE_CONTENT=$(extract_phase_content "$PLAN_FILE" 3)

# Get phase name
PHASE_NAME=$(extract_phase_name "$PHASE_CONTENT")

# Parse all phases
PHASE_LIST=$(parse_phase_list "$PLAN_FILE")
```

**Used By:** `/implement`, `/expand`, `/collapse`, `/list`

---

#### plan-structure-utils.sh (396 lines)

Structure operations for progressive plan organization (expansion, collapse, directory management).

**Key Functions:**
- `detect_structure_level()` - Detect plan structure level (0/1/2)
- `is_plan_expanded()` - Check if plan is expanded to directory
- `get_plan_directory()` - Get plan directory path
- `is_phase_expanded()` - Check if phase is expanded to file
- `get_phase_file()` - Get phase file path
- `is_stage_expanded()` - Check if stage is expanded to file
- `list_expanded_phases()` - List all expanded phases
- `list_expanded_stages()` - List all expanded stages for phase
- `has_remaining_phases()` - Check if plan has remaining inline phases
- `has_remaining_stages()` - Check if phase has remaining inline stages
- `cleanup_plan_directory()` - Remove plan directory if empty
- `cleanup_phase_directory()` - Remove phase directory if empty

**Usage Example:**
```bash
source .claude/lib/plan-structure-utils.sh

# Detect structure level
LEVEL=$(detect_structure_level "$PLAN_PATH")

# Check if phase is expanded
if is_phase_expanded "$PLAN_PATH" 3; then
  PHASE_FILE=$(get_phase_file "$PLAN_PATH" 3)
fi

# List expanded phases
EXPANDED=$(list_expanded_phases "$PLAN_PATH")
```

**Used By:** `/expand`, `/collapse`, `/implement`

---

#### plan-metadata-utils.sh (607 lines)

Metadata extraction and manipulation for plans (phase/stage metadata, expansion tracking).

**Key Functions:**
- `revise_main_plan_for_phase()` - Update main plan after phase expansion
- `add_phase_metadata()` - Add expansion metadata to phase
- `update_structure_level()` - Update plan structure level metadata
- `update_expanded_phases()` - Update list of expanded phases
- `revise_phase_file_for_stage()` - Update phase file after stage expansion
- `add_stage_metadata()` - Add expansion metadata to stage
- `update_phase_expanded_stages()` - Update phase's expanded stages list
- `update_plan_expanded_stages()` - Update plan's stage tracking
- `merge_phase_into_plan()` - Merge expanded phase back into main plan
- `merge_stage_into_phase()` - Merge expanded stage back into phase
- `remove_expanded_phase()` - Remove phase from expansion tracking
- `remove_phase_expanded_stage()` - Remove stage from phase tracking
- `remove_plan_expanded_stage()` - Remove stage from plan tracking

**Usage Example:**
```bash
source .claude/lib/plan-metadata-utils.sh

# Add phase expansion metadata
add_phase_metadata "$PLAN_FILE" 3 "$PHASE_FILE"

# Update structure level
update_structure_level "$PLAN_FILE" 1

# Merge phase back
merge_phase_into_plan "$PLAN_FILE" 3 "$PHASE_FILE"
```

**Used By:** `/expand`, `/collapse`, `/revise`

---

## Archived Scripts

These scripts are archived in `.claude/archive/lib/cleanup-2025-10-26/`. See the [Archive Manifest](../archive/lib/cleanup-2025-10-26/README.md) for restoration instructions.

**Archived**: progressive-planning-utils.sh, validation-utils.sh, parallel-orchestration-utils.sh, structure-eval-utils.sh (and 21 others)

---

#### progressive-planning-utils.sh (490 lines) - ARCHIVED

Progressive plan structure management for adaptive expansion and collapse operations.

**Key Functions:**
- `expand_phase_to_file()` - Extract phase to separate file
- `expand_stage_to_file()` - Extract stage to separate file
- `collapse_phase_to_plan()` - Merge phase file back into plan
- `collapse_stage_to_phase()` - Merge stage file back into phase
- `validate_expansion_prerequisites()` - Check if phase can be expanded
- `validate_collapse_prerequisites()` - Check if phase can be collapsed

**Usage Example:**
```bash
source .claude/lib/progressive-planning-utils.sh

# Expand phase
expand_phase_to_file "$PLAN_FILE" 3

# Collapse phase
collapse_phase_to_plan "$PLAN_FILE" 3
```

**Used By:** `/expand`, `/collapse`, `/implement` (adaptive)

---

### Artifact Management

#### artifact-creation.sh and artifact-registry.sh (1585 lines combined)

Unified artifact registry, operations, metadata extraction, and report generation. Consolidates artifact-utils.sh and artifact-management.sh.

**Key Functions:**

*Registry Operations:*
- `register_artifact()` - Register artifact in central registry
- `query_artifacts()` - Query artifacts by type or pattern
- `update_artifact_status()` - Update artifact metadata
- `cleanup_artifacts()` - Remove old artifact entries
- `validate_artifact_references()` - Check if artifact paths exist
- `list_artifacts()` - List all registered artifacts
- `get_artifact_path_by_id()` - Get artifact path by registry ID

*Metadata Extraction:*
- `get_plan_metadata()` - Extract plan metadata without reading full file
- `get_report_metadata()` - Extract report metadata without reading full file
- `get_plan_phase()` - Extract single phase content on-demand
- `get_plan_section()` - Generic section extraction by heading pattern
- `get_report_section()` - Extract report section by heading

*Artifact Creation:*
- `create_artifact_directory()` - Create directory for plan-based artifacts
- `create_artifact_directory_with_workflow()` - Create directory with workflow context
- `get_next_artifact_number()` - Get next sequential artifact number
- `write_artifact_file()` - Write artifact with proper formatting
- `generate_artifact_invocation()` - Generate slash command invocation

*Report Generation:*
- `generate_analysis_report()` - Generate analysis report from results
- `review_plan_hierarchy()` - Review and recommend hierarchy improvements
- `present_recommendations_for_approval()` - Present recommendations to user

*Operation Tracking:*
- `register_operation_artifact()` - Register artifacts created during operations
- `get_artifact_path()` - Get artifact path for operation (plan_path + item_id)
- `validate_operation_artifacts()` - Validate artifacts from operation

**Usage Example:**
```bash
source .claude/lib/artifact-creation.sh
source .claude/lib/artifact-registry.sh

# Register a plan
PLAN_ID=$(register_artifact "plan" "specs/plans/025.md" '{"status":"in_progress"}')

# Query all plans
PLANS=$(query_artifacts "plan")

# Get plan metadata (efficient, without reading full file)
METADATA=$(get_plan_metadata "specs/plans/025.md")
PHASE_COUNT=$(echo "$METADATA" | jq -r '.total_phases')

# Create artifact directory
create_artifact_directory "specs/plans" "new_feature"

# Get artifact path by ID
PATH=$(get_artifact_path_by_id "$PLAN_ID")

# Get artifact path for operation
PATH=$(get_artifact_path "specs/plans/025.md" "phase_3")
```

**Function Name Resolutions:**
- `create_artifact_directory()` - Plan-based directory creation
- `create_artifact_directory_with_workflow()` - Workflow-based directory creation
- `get_artifact_path()` - Operation tracking path resolution (plan_path + item_id)
- `get_artifact_path_by_id()` - Registry lookup by ID

**Used By:** `/list`, `/orchestrate`, `/implement`, all artifact-generating commands

---

### Error Handling & Validation

#### error-handling.sh (751 lines)

Error classification, recovery strategies, retry logic, and user escalation.

**Key Functions:**
- `classify_error()` - Classify error as transient/permanent/fatal
- `detect_error_type()` - Detect specific error type from message
- `suggest_recovery()` - Suggest recovery action for error type
- `generate_suggestions()` - Generate error-specific suggestions
- `retry_with_backoff()` - Retry command with exponential backoff
- `retry_with_timeout()` - Generate retry metadata with extended timeout
- `retry_with_fallback()` - Generate fallback retry metadata
- `log_error_context()` - Log error with context for debugging
- `escalate_to_user()` - Present error to user with options
- `escalate_to_user_parallel()` - Format escalation for parallel operations
- `try_with_fallback()` - Try primary approach, fall back to alternative
- `format_error_report()` - Format error message with context
- `handle_partial_failure()` - Process successful operations, report failures
- `cleanup_on_error()` - Cleanup temp files on error
- `format_orchestrate_agent_failure()` - Format agent invocation failures
- `format_orchestrate_test_failure()` - Format test failures in workflows
- `extract_location()` - Extract file location from error message

**Usage Example:**
```bash
source .claude/lib/error-handling.sh

# Classify an error
ERROR_TYPE=$(classify_error "Database connection timeout")

# Retry with exponential backoff
if retry_with_backoff 3 500 curl "https://api.example.com"; then
  echo "Request succeeded"
fi

# Try with fallback
try_with_fallback \
  "complex_edit large_file.lua" \
  "simple_edit large_file.lua"

# Format orchestrate agent failure
format_orchestrate_agent_failure "code-writer" "Phase 3" "Syntax error in generated code"
```

**Error Types:**
- **Transient**: Temporary failures (locks, timeouts, resource unavailable)
- **Permanent**: Code-level issues (syntax errors, logic bugs)
- **Fatal**: Environment issues (disk full, permissions)

**Retry Strategy:**
- Max attempts: 3 (default)
- Base delay: 500ms (default)
- Exponential backoff: 500ms → 1s → 2s

**Used By:** `/implement`, `/orchestrate`, `/test`, `/setup`, all commands

---

#### validation-utils.sh (298 lines) - ARCHIVED

Input validation and parameter checking utilities.

**Key Functions:**
- `require_param()` - Exit with error if parameter is empty
- `validate_file_exists()` - Check if file exists
- `validate_dir_exists()` - Check if directory exists
- `validate_number()` - Check if value is a valid positive integer
- `validate_positive_number()` - Check if value is positive (> 0)
- `validate_float()` - Check if value is a valid float
- `validate_path_safe()` - Validate path doesn't contain dangerous characters
- `validate_choice()` - Validate value is one of allowed choices
- `validate_boolean()` - Validate value is a boolean
- `validate_not_empty()` - Validate value is not empty or whitespace
- `validate_file_readable()` - Check if file is readable
- `validate_file_writable()` - Check if file is writable
- `check_required_tool()` - Check if required tool is available
- `check_file_writable()` - Legacy function for file writability

**Usage Example:**
```bash
source .claude/lib/validation-utils.sh

# Require parameters
require_param "plan_file" "$1" || exit 1

# Validate file exists
validate_file_exists "$plan_file" || exit 1

# Validate number
validate_positive_number "$phase_number" || exit 1

# Validate choice
validate_choice "$mode" "sequential" "parallel" "hybrid" || exit 1

# Check required tools
check_required_tool "jq" "sudo apt install jq" || exit 1
```

**Validation Patterns:**
- File/Directory: validate_file_exists, validate_dir_exists, validate_file_readable
- Numbers: validate_number, validate_positive_number, validate_float
- Strings: validate_not_empty, require_param
- Choices: validate_choice, validate_boolean
- Security: validate_path_safe (prevents directory traversal)
- Tools: check_required_tool

**Used By:** All commands requiring input validation

---

### Document Conversion

#### convert-core.sh (1308 lines)

Main document conversion orchestration with tool detection, file discovery, and batch processing.

**Key Functions:**
- `detect_tools()` - Detect available conversion tools
- `select_docx_tool()` - Select best DOCX converter
- `select_pdf_tool()` - Select best PDF converter
- `with_timeout()` - Execute command with timeout protection
- `discover_files()` - Find convertible files with validation
- `validate_input_file()` - Validate file magic numbers and format
- `convert_file()` - Main conversion dispatcher with automatic fallback
- `process_conversions()` - Process files sequentially or in parallel
- `convert_batch_parallel()` - Parallel conversion with worker pool
- `check_output_collision()` - Ensure unique output filenames
- `acquire_lock()` / `release_lock()` - Prevent concurrent conversions
- `check_disk_space()` - Verify sufficient disk space
- `show_tool_detection()` - Display detected tools
- `show_dry_run()` - Display files that would be converted
- `generate_summary()` - Print conversion statistics
- `main_conversion()` - Main entry point for conversion workflow

**Usage Example:**
```bash
source .claude/lib/convert-core.sh

# Run conversion
main_conversion "/path/to/input" "/path/to/output"

# With options
main_conversion "/input" "/output" --parallel 4
main_conversion "/input" --dry-run
```

**Module Dependencies:**
- `convert-docx.sh` - DOCX conversion functions
- `convert-pdf.sh` - PDF conversion functions
- `convert-markdown.sh` - Markdown validation

**Supported Conversions:**
- DOCX → Markdown (MarkItDown primary, Pandoc fallback)
- PDF → Markdown (MarkItDown primary, PyMuPDF4LLM fallback)
- Markdown → DOCX (Pandoc)
- Markdown → PDF (Pandoc with Typst or XeLaTeX)

**Used By:** `/convert-docs`

---

#### convert-docx.sh (78 lines)

DOCX conversion utilities for DOCX ↔ Markdown transformations.

**Key Functions:**
- `convert_docx()` - DOCX→MD using MarkItDown
- `convert_docx_pandoc()` - DOCX→MD using Pandoc
- `convert_md_to_docx()` - MD→DOCX using Pandoc

**Usage Example:**
```bash
# Sourced automatically by convert-core.sh
source .claude/lib/convert-docx.sh

convert_docx "input.docx" "output.md"
convert_md_to_docx "input.md" "output.docx"
```

**Dependencies:** MarkItDown (optional), Pandoc (optional)

**Used By:** `convert-core.sh`

---

#### convert-pdf.sh (95 lines)

PDF conversion utilities for PDF ↔ Markdown transformations.

**Key Functions:**
- `convert_pdf_markitdown()` - PDF→MD using MarkItDown
- `convert_pdf_pymupdf()` - PDF→MD using PyMuPDF4LLM
- `convert_md_to_pdf()` - MD→PDF using Pandoc

**Usage Example:**
```bash
# Sourced automatically by convert-core.sh
source .claude/lib/convert-pdf.sh

convert_pdf_markitdown "input.pdf" "output.md"
convert_md_to_pdf "input.md" "output.pdf"
```

**Dependencies:** MarkItDown (optional), PyMuPDF4LLM (optional), Pandoc (required for MD→PDF), Typst or XeLaTeX

**Used By:** `convert-core.sh`

---

#### convert-markdown.sh (83 lines)

Markdown validation and structure analysis utilities.

**Key Functions:**
- `check_structure()` - Analyze Markdown structure (headings, tables)
- `report_validation_warnings()` - Report conversion quality warnings

**Usage Example:**
```bash
# Sourced automatically by convert-core.sh
source .claude/lib/convert-markdown.sh

STRUCTURE=$(check_structure "document.md")
echo "Structure: $STRUCTURE"  # "15 headings, 3 tables"

report_validation_warnings "output.md" "md"
```

**Validation Checks:**
- File existence and size (minimum 100 bytes)
- Heading presence in Markdown
- Structure analysis (heading count, table count)

**Used By:** `convert-core.sh`

---

#### conversion-logger.sh (332 lines)

Structured logging for document conversion operations with validation and statistics.

**Key Functions:**
- `init_conversion_log()` - Initialize conversion log file
- `log_conversion_start()` - Log start of conversion
- `log_conversion_success()` - Log successful conversion
- `log_conversion_failure()` - Log failed conversion
- `log_conversion_fallback()` - Log fallback attempt
- `log_tool_detection()` - Log tool detection results
- `log_phase_start()` - Log start of conversion phase
- `log_phase_end()` - Log end of conversion phase
- `log_validation_check()` - Log validation check result
- `log_summary()` - Log conversion summary statistics
- `rotate_log_file()` - Rotate log files automatically

**Usage Example:**
```bash
source .claude/lib/conversion-logger.sh

init_conversion_log "output/conversion.log" "input/" "output/"
log_conversion_start "file.docx" "markdown"
log_conversion_success "file.docx" "file.md" "markitdown" 1500
log_summary 10 8 2 0
```

**Log Rotation:** Max 10MB, 5 rotated files

**Used By:** `/convert-docs`, `convert-core.sh`

---

### Adaptive Planning

#### adaptive-planning-logger.sh (374 lines)

Structured logging for adaptive planning trigger evaluations and replanning events.

**Key Functions:**
- `log_trigger_evaluation()` - Log a trigger evaluation with result
- `log_complexity_check()` - Log complexity score and threshold comparison
- `log_test_failure_pattern()` - Log test failure pattern detection
- `log_scope_drift()` - Log scope drift detection
- `log_replan_invocation()` - Log a replanning invocation and result
- `log_loop_prevention()` - Log loop prevention enforcement
- `query_adaptive_log()` - Query log for recent events
- `get_adaptive_stats()` - Get statistics about adaptive planning activity

**Usage Example:**
```bash
source .claude/lib/adaptive-planning-logger.sh

# Log complexity check
log_complexity_check 3 9.2 8 12

# Log replan invocation
log_replan_invocation "expand_phase" "success" "/path/to/plan.md" '{"phase": 3}'

# Query recent events
query_adaptive_log "trigger_eval" 5

# Get statistics
get_adaptive_stats
```

**Log Format:**
```
[2025-10-06T12:30:45Z] INFO trigger_eval: complexity -> triggered | data={"score": 9.2}
[2025-10-06T12:31:15Z] INFO replan: expand_phase -> success | data={...}
```

**Log Rotation:** Max 10MB, 5 rotated files

**Used By:** `/implement` (adaptive planning)

---

#### checkpoint-utils.sh (778 lines)

Checkpoint management for workflow resume capability with schema migration.

**Key Functions:**
- `save_checkpoint()` - Save workflow state for resume
- `restore_checkpoint()` - Load most recent checkpoint
- `validate_checkpoint()` - Validate checkpoint structure
- `migrate_checkpoint_format()` - Migrate old checkpoints to current schema
- `checkpoint_get_field()` - Extract field value from checkpoint
- `checkpoint_set_field()` - Update field value in checkpoint
- `checkpoint_increment_replan()` - Increment replanning counters
- `checkpoint_delete()` - Delete checkpoint file

**Usage Example:**
```bash
source .claude/lib/checkpoint-utils.sh

# Save checkpoint
STATE='{"phase": 3, "status": "in_progress"}'
CHECKPOINT=$(save_checkpoint "implement" "project" "$STATE")

# Restore checkpoint
CHECKPOINT=$(restore_checkpoint "implement" "project")
PHASE=$(echo "$CHECKPOINT" | jq -r '.current_phase')

# Increment replan counter
checkpoint_increment_replan "$CHECKPOINT_FILE" "3" "Complexity exceeded"
```

**Checkpoint Schema (v1.1):**
```json
{
  "schema_version": "1.1",
  "checkpoint_id": "implement_project_20251006_123045",
  "workflow_type": "implement",
  "status": "in_progress",
  "current_phase": 3,
  "replanning_count": 1,
  "replan_phase_counts": {"phase_3": 1},
  "replan_history": [...]
}
```

**Schema Migration:** Automatic migration from v1.0 to v1.1 with backups

**Used By:** `/implement`, `/orchestrate`, `/resume-implement`

---

#### complexity-utils.sh (770 lines)

Complexity analysis for phases and plans, enabling adaptive planning detection.

**Key Functions:**
- `calculate_phase_complexity()` - Calculate complexity score (0-10+)
- `analyze_task_structure()` - Analyze task metrics (count, nesting, files)
- `detect_complexity_triggers()` - Check if thresholds exceeded
- `generate_complexity_report()` - Generate JSON report with all metrics
- `analyze_plan_complexity()` - Analyze overall plan complexity
- `get_complexity_level()` - Get human-readable complexity level
- `format_complexity_summary()` - Format report for display

**Usage Example:**
```bash
source .claude/lib/complexity-utils.sh

# Calculate phase complexity
SCORE=$(calculate_phase_complexity "Phase 3: Refactor" "$TASK_LIST")

# Check if triggers exceeded
if detect_complexity_triggers "$SCORE" "12"; then
  echo "Expansion recommended"
fi

# Generate report
REPORT=$(generate_complexity_report "Phase 3" "$TASK_LIST")
format_complexity_summary "$REPORT"
```

**Complexity Thresholds:**
- Low: 0-2 (trivial)
- Medium: 3-5 (standard)
- High: 6-8 (complex)
- Critical: 9+ (expansion recommended)

**Trigger Conditions:**
- Complexity score > 8
- Task count > 10

**Used By:** `/implement` (adaptive planning), `/plan`

---

### Agent Coordination

#### agent-registry-utils.sh (218 lines)

Agent registry operations for tracking agent performance and availability.

**Key Functions:**
- `get_agent_info()` - Get agent metadata from registry
- `update_agent_metrics()` - Update agent performance metrics
- `record_agent_invocation()` - Record agent invocation event
- `get_agent_history()` - Get agent invocation history
- `validate_agent_exists()` - Check if agent exists in registry

**Usage Example:**
```bash
source .claude/lib/agent-registry-utils.sh

# Get agent info
INFO=$(get_agent_info "code-writer")

# Update metrics
update_agent_metrics "code-writer" "success" 1500

# Get history
HISTORY=$(get_agent_history "code-writer" 10)
```

**Used By:** `/orchestrate`, `/implement`, agent invocation commands

---

#### agent-invocation.sh (135 lines)

Agent coordination and invocation with prompt construction.

**Key Functions:**
- `invoke_complexity_estimator()` - Construct prompts and invoke complexity agent
- `invoke_agent()` - Generic agent invocation with error handling
- `construct_agent_prompt()` - Build agent-specific prompts

**Usage Example:**
```bash
source .claude/lib/agent-invocation.sh

# Invoke complexity estimator
RESULT=$(invoke_complexity_estimator "$PLAN_FILE" "$PHASE_NUM")

# Generic agent invocation
invoke_agent "code-writer" "$PROMPT" "$CONTEXT"
```

**Used By:** `/orchestrate`, `/implement`

---

#### parallel-orchestration-utils.sh (400 lines) - ARCHIVED

Parallel agent workflow management for orchestrated operations.

**Key Functions:**
- `run_parallel_agents()` - Run multiple agents in parallel
- `collect_agent_results()` - Collect results from parallel agents
- `validate_parallel_prerequisites()` - Check if parallel execution is safe
- `handle_parallel_failure()` - Handle failures in parallel workflows

**Usage Example:**
```bash
source .claude/lib/parallel-orchestration-utils.sh

# Run research agents in parallel
run_parallel_agents "research-specialist" "${RESEARCH_TOPICS[@]}"

# Collect results
RESULTS=$(collect_agent_results)
```

**Used By:** `/orchestrate`

---

#### workflow-detection.sh (130 lines)

Workflow scope detection and phase execution logic for /supervise command.

**Key Functions:**
- `detect_workflow_scope()` - Detect workflow type (research-only, research-and-plan, full-implementation, debug-only)
- `should_run_phase()` - Check if phase should execute for current scope

**Usage Example:**
```bash
source .claude/lib/workflow-detection.sh

# Detect workflow scope
SCOPE=$(detect_workflow_scope "research auth to create plan")
echo "Detected scope: $SCOPE"  # Output: research-and-plan

# Check if phase should run
export PHASES_TO_EXECUTE="0,1,2"
if should_run_phase 3; then
  echo "Execute phase 3"
else
  echo "Skip phase 3"
fi
```

**Used By:** `/supervise`

---

### Analysis & Metrics

#### analysis-pattern.sh (390 lines)

Common phase/stage analysis patterns extracted from phase-analysis.sh and stage-analysis.sh.

**Key Functions:**
- `analyze_phase_structure()` - Analyze phase complexity and structure
- `analyze_stage_structure()` - Analyze stage complexity and structure
- `extract_analysis_metrics()` - Extract common metrics
- `analyze_items_for_expansion()` - Generic analysis for expansion
- `analyze_items_for_collapse()` - Generic analysis for collapse

**Usage Example:**
```bash
source .claude/lib/analysis-pattern.sh

# Analyze phase
METRICS=$(analyze_phase_structure "Phase 1: Setup" "$TASK_LIST")

# Analyze for expansion
if analyze_items_for_expansion "$PHASE_CONTENT"; then
  echo "Expansion recommended"
fi
```

**Used By:** `complexity-utils.sh`, `/plan`, `/implement`

---

#### structure-eval-utils.sh (299 lines) - ARCHIVED

Plan structure evaluation for revision and optimization recommendations.

**Key Functions:**
- `evaluate_plan_structure()` - Evaluate plan organization quality
- `suggest_structure_improvements()` - Recommend structure improvements
- `validate_plan_hierarchy()` - Validate plan hierarchy consistency

**Usage Example:**
```bash
source .claude/lib/structure-eval-utils.sh

# Evaluate structure
EVAL=$(evaluate_plan_structure "$PLAN_FILE")

# Get suggestions
SUGGESTIONS=$(suggest_structure_improvements "$EVAL")
```

**Used By:** `/revise`, `/plan`

---

#### analyze-metrics.sh (579 lines)

Performance and workflow metrics analysis. Consolidates functionality from deprecated workflow-metrics.sh.

**Features:**
- **Workflow timing analysis** - Duration, phase counts, average times
- **Agent performance tracking** - Invocation stats, success rates, duration averages
- **Complexity evaluation metrics** - Method usage, discrepancies, agent invocation rates
- **Markdown report generation** - Human-readable performance summaries

**Key Functions:**
- `collect_workflow_metrics()` - Collect metrics from workflow execution
- `generate_metrics_report()` - Generate performance report
- `analyze_agent_performance()` - Analyze agent performance patterns
- `identify_bottlenecks()` - Identify workflow bottlenecks
- `aggregate_workflow_times()` - Extract timing data from adaptive-planning.log
- `aggregate_agent_metrics()` - Extract agent performance from agent-registry.json
- `aggregate_complexity_metrics()` - Extract complexity evaluation statistics

**Usage Example:**
```bash
source .claude/lib/analyze-metrics.sh

# Collect workflow metrics
METRICS=$(collect_workflow_metrics "$WORKFLOW_TYPE")

# Aggregate timing data
TIMING=$(aggregate_workflow_times)
DURATION=$(echo "$TIMING" | jq -r '.workflow_duration_seconds')

# Generate full performance report
generate_metrics_report "$METRICS" > report.md
```

**Data Sources:**
- `.claude/logs/adaptive-planning.log` - Workflow timing markers
- `.claude/agents/agent-registry.json` - Agent performance data

**Report Sections:**
1. Workflow Summary - Duration, phases, average time
2. Agent Performance - Per-agent statistics table
3. Complexity Evaluation - Method distribution and metrics

**Used By:** `/analyze`

---

### Template System

#### parse-template.sh (166 lines)

Template file parsing for variable extraction.

**Key Functions:**
- `parse_template_file()` - Parse template YAML structure
- `extract_template_variables()` - Extract required variables
- `validate_template_structure()` - Validate template format

**Usage Example:**
```bash
source .claude/lib/parse-template.sh

# Parse template
TEMPLATE=$(parse_template_file "templates/crud.yaml")

# Extract variables
VARS=$(extract_template_variables "$TEMPLATE")
```

**Used By:** `/plan-from-template`, `/plan-wizard`

---

#### substitute-variables.sh (242 lines)

Variable substitution in templates with validation.

**Key Functions:**
- `substitute_variables()` - Replace variables in template content
- `validate_substitution()` - Validate all variables substituted
- `escape_variable_value()` - Escape special characters in values

**Usage Example:**
```bash
source .claude/lib/substitute-variables.sh

# Substitute variables
CONTENT=$(substitute_variables "$TEMPLATE" "$VARS_JSON")

# Validate substitution
validate_substitution "$CONTENT"
```

**Used By:** `/plan-from-template`, `/plan-wizard`

---

#### template-integration.sh (231 lines)

Template system integration for plan generation workflows.

**Key Functions:**
- `generate_plan_from_template()` - Full template-to-plan workflow
- `list_available_templates()` - List templates by category
- `get_template_info()` - Get template metadata

**Usage Example:**
```bash
source .claude/lib/template-integration.sh

# Generate plan
generate_plan_from_template "crud-feature" "$VARS_JSON"

# List templates
list_available_templates "feature"
```

**Used By:** `/plan-from-template`, `/plan-wizard`

---

### Infrastructure

#### progress-dashboard.sh (351 lines)

Progress dashboard rendering utility for real-time visual feedback during implementation workflows.

**Features:**
- **Terminal capability detection** - Automatically detects ANSI support
- **ANSI rendering** - In-place updates using ANSI escape codes
- **Unicode box-drawing** - Professional layout with Unicode characters
- **Graceful fallback** - Falls back to PROGRESS markers on unsupported terminals
- **Parallel execution support** - Wave-based execution visualization

**Key Functions:**
- `detect_terminal_capabilities()` - Detects terminal support for ANSI rendering
- `render_dashboard()` - Renders the complete dashboard with all information
- `initialize_dashboard()` - Initializes dashboard by reserving screen space
- `update_dashboard_phase()` - Updates phase status
- `clear_dashboard()` - Clears dashboard area on completion or error
- `render_progress_markers()` - Fallback rendering using PROGRESS markers

**Usage Example:**
```bash
source .claude/lib/progress-dashboard.sh

# Initialize dashboard
initialize_dashboard "My Implementation Plan" 5

# Render full dashboard
render_dashboard \
  "My Plan" \
  2 \
  5 \
  '[{"number":1,"name":"Setup","status":"completed"}]' \
  323 \
  492 \
  "Running tests" \
  '{"name":"auth_test","status":"pass"}' \
  '{"wave_num":2,"total_waves":3,"phases_in_wave":2,"parallel":true}'

# Clear dashboard on completion
clear_dashboard
```

**Integration:** Automatically used by `/implement` when `--dashboard` flag is provided

**Supported Terminals:** bash with xterm-256color, zsh with color support, tmux with 256 colors, GNOME Terminal, Konsole (Linux), iTerm2, Terminal.app (macOS)

**Unsupported Terminals:** Emacs shell (TERM=dumb), non-interactive contexts, terminals without tput, terminals with <8 colors

**Used By:** `/implement`, `/orchestrate`

---

#### auto-analysis-utils.sh (636 lines)

Automatic analysis orchestration for complexity detection and recommendations.

**Key Functions:**
- `run_auto_analysis()` - Run automatic complexity analysis
- `generate_expansion_recommendations()` - Recommend phase expansions
- `execute_auto_expansion()` - Execute automatic expansion

**Usage Example:**
```bash
source .claude/lib/auto-analysis-utils.sh

# Run analysis
RECOMMENDATIONS=$(run_auto_analysis "$PLAN_FILE")

# Execute expansion
execute_auto_expansion "$PLAN_FILE" 3
```

**Used By:** `/expand`, `/collapse`, `/implement` (adaptive)

---

#### timestamp-utils.sh (122 lines)

Timestamp utilities for consistent time formatting.

**Key Functions:**
- `get_timestamp()` - Get current timestamp in ISO 8601 format
- `format_timestamp()` - Format timestamp for display
- `parse_timestamp()` - Parse timestamp string
- `timestamp_diff()` - Calculate time difference

**Usage Example:**
```bash
source .claude/lib/timestamp-utils.sh

# Get timestamp
NOW=$(get_timestamp)

# Format for display
DISPLAY=$(format_timestamp "$NOW")

# Calculate diff
DIFF=$(timestamp_diff "$START" "$END")
```

**Used By:** All logging modules, checkpoint-utils.sh

---

#### json-utils.sh (213 lines)

JSON processing utilities with jq integration.

**Key Functions:**
- `json_get()` - Extract value from JSON
- `json_set()` - Set value in JSON
- `json_merge()` - Merge JSON objects
- `json_validate()` - Validate JSON structure

**Usage Example:**
```bash
source .claude/lib/json-utils.sh

# Get value
VALUE=$(json_get "$JSON" '.field.nested')

# Set value
JSON=$(json_set "$JSON" '.status' '"completed"')

# Validate
json_validate "$JSON" || echo "Invalid JSON"
```

**Dependencies:** `jq`, `deps-utils.sh`

**Used By:** artifact-creation.sh, artifact-registry.sh, checkpoint-utils.sh, agent-registry-utils.sh

---

#### deps-utils.sh (146 lines)

Dependency checking utilities for external tools.

**Key Functions:**
- `check_dependency()` - Check if tool is available
- `check_version()` - Check tool version meets requirement
- `install_suggestion()` - Suggest installation command

**Usage Example:**
```bash
source .claude/lib/deps-utils.sh

# Check dependency
check_dependency "jq" || exit 1

# Check version
check_version "git" "2.0" || echo "Upgrade git"

# Get install suggestion
INSTALL=$(install_suggestion "pandoc")
```

**Used By:** json-utils.sh, convert-core.sh, validation-utils.sh

---

#### detect-project-dir.sh (50 lines)

Project directory detection for determining project root.

**Key Functions:**
- `detect_project_root()` - Find project root directory
- `find_claude_dir()` - Locate .claude directory

**Usage Example:**
```bash
source .claude/lib/detect-project-dir.sh

# Detect root
ROOT=$(detect_project_root)

# Find .claude
CLAUDE_DIR=$(find_claude_dir)
```

**Used By:** `/orchestrate`, all commands

---

## Module Dependencies

### Dependency Graph

```
Core Infrastructure:
├─ timestamp-utils.sh (no dependencies)
├─ deps-utils.sh (no dependencies)
└─ detect-project-dir.sh (no dependencies)

JSON & Validation:
├─ json-utils.sh → deps-utils.sh
└─ validation-utils.sh (no dependencies)

Parsing & Structure:
├─ parse-plan-core.sh (no dependencies)
├─ plan-structure-utils.sh (no dependencies)
├─ plan-metadata-utils.sh → parse-plan-core.sh, plan-structure-utils.sh
└─ progressive-planning-utils.sh → plan-structure-utils.sh, plan-metadata-utils.sh

Artifacts:
├─ artifact-creation.sh → json-utils.sh, timestamp-utils.sh
└─ artifact-registry.sh → json-utils.sh, timestamp-utils.sh

Error Handling:
└─ error-handling.sh → timestamp-utils.sh

Analysis:
├─ analysis-pattern.sh (no dependencies)
├─ complexity-utils.sh → analysis-pattern.sh
└─ structure-eval-utils.sh → parse-plan-core.sh

Adaptive Planning:
├─ adaptive-planning-logger.sh → timestamp-utils.sh
├─ checkpoint-utils.sh → json-utils.sh, timestamp-utils.sh
└─ complexity-utils.sh → analysis-pattern.sh

Templates:
├─ parse-template.sh (no dependencies)
├─ substitute-variables.sh (no dependencies)
└─ template-integration.sh → parse-template.sh, substitute-variables.sh

Agents:
├─ agent-registry-utils.sh → json-utils.sh
├─ agent-invocation.sh → agent-registry-utils.sh
└─ parallel-orchestration-utils.sh → agent-invocation.sh, error-handling.sh

Conversion:
├─ conversion-logger.sh → timestamp-utils.sh
├─ convert-docx.sh (no dependencies)
├─ convert-pdf.sh (no dependencies)
├─ convert-markdown.sh (no dependencies)
└─ convert-core.sh → convert-docx.sh, convert-pdf.sh, convert-markdown.sh, conversion-logger.sh

High-Level:
├─ progress-dashboard.sh → timestamp-utils.sh
└─ auto-analysis-utils.sh → complexity-utils.sh, artifact-creation.sh, artifact-registry.sh, error-handling.sh
```

### Sourcing Order

When sourcing multiple modules, follow this order to satisfy dependencies:

1. Infrastructure: timestamp-utils.sh, deps-utils.sh, detect-project-dir.sh
2. JSON & Validation: json-utils.sh, validation-utils.sh
3. Parsing: parse-plan-core.sh, plan-structure-utils.sh, plan-metadata-utils.sh
4. Error & Artifacts: error-handling.sh, artifact-creation.sh, artifact-registry.sh
5. Analysis: analysis-pattern.sh, complexity-utils.sh, structure-eval-utils.sh
6. Specialized: checkpoint-utils.sh, agents, conversion, templates
7. High-level: auto-analysis-utils.sh, progress-dashboard.sh

## Usage Guidelines

### When to Use Shared Utilities

✅ **Use shared utilities when:**
- Functionality is used by 2+ commands
- Logic is complex and benefits from centralized testing
- Consistency across commands is important
- Code would otherwise be duplicated

❌ **Don't use shared utilities when:**
- Functionality is command-specific
- Logic is trivial (1-2 lines)
- Command has unique requirements that don't generalize

### Adding New Utilities

When adding a new shared utility library:

1. **Create utility file** in `.claude/lib/`
2. **Follow naming convention**: `[domain]-[purpose].sh`
3. **Include header comment** describing purpose
4. **Document dependencies** in header
5. **Export functions** at bottom of file
6. **Document in this README** with usage examples
7. **Add unit tests** in `.claude/tests/`

### Utility Structure Template

```bash
#!/usr/bin/env bash
# [Utility Name] - Brief description
# Purpose and use cases
#
# Dependencies:
#   - module1.sh
#   - module2.sh

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/dependency.sh"

# ==============================================================================
# Constants
# ==============================================================================

readonly CONSTANT_NAME="value"

# ==============================================================================
# Core Functions
# ==============================================================================

# function_name: Description
# Usage: function_name <arg1> <arg2>
# Returns: Description of return value
# Example: function_name "value1" "value2"
function_name() {
  local arg1="${1:-}"
  local arg2="${2:-}"

  # Implementation
}

# ==============================================================================
# Export Functions (if sourced)
# ==============================================================================

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f function_name
fi
```

## Testing

### Unit Testing

Test individual modules:

```bash
# Source module
source .claude/lib/checkpoint-utils.sh

# Test functions
save_checkpoint "test" "project" '{"phase": 1}'
restore_checkpoint "test" "project"
```

### Integration Testing

Run test suite:

```bash
# Run all tests
cd .claude/tests
./run_all_tests.sh

# Run specific test
./test_shared_utilities.sh
./test_parsing_utilities.sh
```

### Test Categories

- `test_parsing_utilities.sh` - Parsing modules
- `test_shared_utilities.sh` - Core utilities (error, validation, checkpoint)
- `test_artifact_utils.sh` - Artifact operations
- `test_progressive_*.sh` - Progressive planning
- `test_adaptive_planning.sh` - Adaptive planning integration
- `test_convert_docs_*.sh` - Document conversion (5 test files)

### Coverage

- Aim for >80% coverage on new utilities
- All public APIs must have tests
- Critical paths require integration tests

## Neovim Integration

Utility library files are integrated with the Neovim artifact picker for easy browsing and editing.

### Accessing Library Files via Picker

- **Keybinding**: `<leader>ac` in normal mode
- **Command**: `:ClaudeCommands`
- **Category**: [Lib] section in picker

### Picker Features

**Visual Display:**
- Library utilities listed with descriptions from script headers
- Local utilities marked with `*` prefix
- Descriptions automatically extracted from file comments

**Quick Actions:**
- `<CR>` - Open utility script for editing
- `<C-l>` - Load utility locally to project
- `<C-g>` - Update from global version
- `<C-s>` - Save local utility to global
- `<C-e>` - Edit utility file in buffer

### Example Workflow

```vim
" Open picker
:ClaudeCommands

" Navigate to [Lib] category
" Select checkpoint-utils.sh
" Press <C-e> to view or modify utility functions
```

### Documentation

- [Neovim Claude Integration](../../nvim/lua/neotex/plugins/ai/claude/README.md)
- [Commands Picker](../../nvim/lua/neotex/plugins/ai/claude/commands/README.md)
- [Picker Implementation](../../nvim/lua/neotex/plugins/ai/claude/commands/picker.lua)

## Version History

### v2.0 (2025-10-14) - Clean-Break Refactor

**Major Changes:**
- Split parse-adaptive-plan.sh (1298 lines) → 3 modules (parse-plan-core.sh, plan-structure-utils.sh, plan-metadata-utils.sh)
- Split error-utils.sh (809 lines) → error-handling.sh + enhanced validation-utils.sh
- Split convert-docs.sh (1502 lines) → 4 modules (convert-core.sh, convert-docx.sh, convert-pdf.sh, convert-markdown.sh)
- Consolidated artifact-utils.sh + artifact-management.sh → artifact-creation.sh + artifact-registry.sh (1585 lines combined)
- Merged phase-analysis.sh + stage-analysis.sh → analysis-pattern.sh (90% duplicate code eliminated)
- Removed 3 dead scripts (analyze-plan-requirements.sh, parse-phase-dependencies.sh, workflow-metrics.sh)
- Scripts reduced: 30 → 27 (10% reduction from refactor start)

**Function Name Resolutions:**
- artifact-creation.sh and artifact-registry.sh: Resolved 2 duplicate function name conflicts
  - create_artifact_directory() (plan-based) vs create_artifact_directory_with_workflow() (workflow-based)
  - get_artifact_path() (operation tracking) vs get_artifact_path_by_id() (registry lookup)

**Documentation:**
- Comprehensive README with all 30 modules documented
- Module dependencies mapped
- Usage examples for all public APIs
- Clear sourcing order guidelines

### v1.2 (2025-10-06)

- Created checkpoint-utils.sh with checkpoint management
- Created error-utils.sh with error handling
- Created complexity-utils.sh with adaptive planning

### v1.1 (Initial)

- Basic utility structure
- conversion-logger.sh
- artifact-utils.sh

## Navigation

- [← Parent Directory](../README.md)
- [Agent Shared Protocols](../agents/shared/) - Shared agent documentation
- [Command Documentation](../commands/) - Commands using these utilities
- [Testing Documentation](../tests/) - Test suite for utilities
- [CLAUDE.md](../../CLAUDE.md) - Project standards and protocols
