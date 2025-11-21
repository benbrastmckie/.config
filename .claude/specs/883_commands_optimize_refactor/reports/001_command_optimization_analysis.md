# Command Optimization and Standardization Analysis

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Command optimization and standardization for improved workflow efficiency
- **Report Type**: codebase analysis + best practices

## Executive Summary

Analysis of 12 active commands (10,649 total lines) reveals a mature, well-functioning command system with strong standardization across state management, error logging, and agent integration patterns. The system demonstrates excellent architectural consistency with 171 error handling calls, 379 state persistence operations, and consistent library sourcing patterns. Primary optimization opportunities exist in reducing bash block count variance (3-32 blocks per command), extracting common initialization patterns into reusable library functions, and standardizing documentation structure across commands. The commands are performing robustly with clear separation of concerns between primary workflows (/plan, /build, /debug), progressive operations (/expand, /collapse), and utility functions (/errors, /repair, /setup).

## Findings

### Current State Analysis

#### 1. Command Structure and Organization

The `.claude/commands/` directory contains 12 active commands organized by type:

**Primary Commands** (4):
- `/build` (1,529 lines, 7 bash blocks) - Implementation orchestrator
- `/plan` (944 lines, 4 bash blocks) - Research-driven planning
- `/debug` (1,307 lines, 11 bash blocks) - Root cause analysis
- `/research` (666 lines, 3 bash blocks) - Research-only workflow

**Workflow Commands** (3):
- `/expand` (1,144 lines, 32 bash blocks) - Phase/stage expansion
- `/collapse` (744 lines, 29 bash blocks) - Phase/stage collapse
- `/revise` (978 lines, 8 bash blocks) - Plan revision

**Utility Commands** (5):
- `/errors` (255 lines, 2 bash blocks) - Error log querying
- `/repair` (679 lines, 3 bash blocks) - Error analysis and fix planning
- `/setup` (356 lines, 3 bash blocks) - CLAUDE.md configuration
- `/convert-docs` (501 lines, 14 bash blocks) - Document format conversion
- `/optimize-claude` (641 lines, 8 bash blocks) - System optimization analysis

**Key Metrics**:
- Total command LOC: 10,649 lines
- Average command size: 887 lines
- Bash block variance: 2-32 blocks (high variance)
- Metadata compliance: 100% (all commands have frontmatter)
- Library sourcing pattern: Highly consistent

#### 2. Standardization Strengths

**State Management Pattern** (379 occurrences):
- Consistent use of `STATE_FILE`, `append_workflow_state()`, `load_workflow_state()`
- All workflow commands use state persistence library
- State restoration patterns identical across `/plan`, `/debug`, `/build`, `/repair`
- Example from `/home/benjamin/.config/.claude/commands/plan.md:499-501`:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
```

**Error Handling Pattern** (171 occurrences):
- Consistent use of `log_command_error()`, `setup_bash_error_trap()`, `ensure_error_log_exists()`
- All commands initialize error logging early
- Standardized error types: `state_error`, `validation_error`, `agent_error`, `file_error`
- Example from `/home/benjamin/.config/.claude/commands/debug.md:44`:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}
ensure_error_log_exists
```

**History Expansion Protection** (38 occurrences):
- All commands use `set +H # CRITICAL: Disable history expansion` pattern
- Prevents bash history expansion issues with user input containing `!`
- Consistent placement at beginning of bash blocks
- Example pattern in all primary commands

**Library Sourcing Pattern**:
- Consistent order: state-persistence → workflow-state-machine → error-handling → specialized libs
- All use `2>/dev/null` for output suppression per standards
- Critical libraries use `|| { echo "ERROR"; exit 1; }` failfast pattern
- 100% adoption across workflow commands

**Agent Integration Pattern** (106 "EXECUTE NOW" + "Task {" occurrences):
- Standardized Task tool invocation format
- Consistent prompt structure with behavioral guideline references
- All agents receive `WORKFLOW_ID`, `COMMAND_NAME`, `USER_ARGS` context
- Return signal parsing consistently implemented

#### 3. Documentation Structure

**Frontmatter Metadata** (142 occurrences across 23 files):
- All commands include: `allowed-tools`, `argument-hint`, `description`, `command-type`
- Optional fields: `dependent-agents`, `library-requirements`, `documentation`
- Library version requirements specified (e.g., `workflow-state-machine.sh: ">=2.0.0"`)

**Section Organization**:
Commands follow consistent structure but with variations:
- `/plan`: Block 1a (Setup) → 1b (Topic Naming) → 1c (Paths) → 1d (Research) → Block 2 (Planning) → Block 3 (Completion)
- `/debug`: Part 1-6 naming convention (different from "Block" pattern)
- `/build`: Block 1 (Setup) → Task → Block 1b (Phase Update) → Testing Phase → Block 2 → Block 3 → Block 4
- `/research`: Block 1a-1c → 2 (Research) → 3 (Completion)

**Inconsistency**: Mix of "Block N" vs "Part N" vs "Phase N" naming

**README.md Structure**:
- Comprehensive 905-line README with architecture diagrams
- Complete command catalog with usage examples
- Common flags documentation
- Navigation section with links

#### 4. Bash Block Organization

High variance in bash block count per command reveals opportunities for consolidation:

**Low Block Count** (2-4 blocks):
- `/errors`: 2 blocks - Simple query operations
- `/repair`: 3 blocks - Research + Analysis + Completion
- `/research`: 3 blocks - Setup + Research + Verification
- `/setup`: 3 blocks - Detection + Execution + Reporting
- `/plan`: 4 blocks - Well-consolidated workflow

**Medium Block Count** (7-14 blocks):
- `/build`: 7 blocks - Complex but consolidated
- `/optimize-claude`: 8 blocks - Multi-stage analysis
- `/revise`: 8 blocks - Plan revision workflow
- `/debug`: 11 blocks - Root cause investigation
- `/convert-docs`: 14 blocks - Format conversion operations

**High Block Count** (29-32 blocks):
- `/expand`: 32 blocks - Highest fragmentation
- `/collapse`: 29 blocks - High fragmentation

**Pattern**: `/expand` and `/collapse` have 4x-10x more bash blocks than other commands, suggesting excessive fragmentation

#### 5. Common Initialization Pattern

All workflow commands repeat identical initialization sequence (30-40 lines):

```bash
# Project directory detection
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
    current_dir="$(dirname "$current_dir")"
  done
fi

export CLAUDE_PROJECT_DIR

# Library sourcing
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null

# Error logging initialization
ensure_error_log_exists
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

This pattern appears 6+ times across commands with minimal variation.

#### 6. Library Dependencies

Commands depend on 46 library functions across 9 categories:

**Core Libraries** (most frequently sourced):
- `state-persistence.sh` - Workflow state management
- `workflow-state-machine.sh` - State transitions
- `error-handling.sh` - Centralized error logging
- `unified-location-detection.sh` - Topic path resolution
- `workflow-initialization.sh` - Workflow setup
- `summary-formatting.sh` - Console output formatting
- `library-version-check.sh` - Dependency verification

**Specialized Libraries**:
- `checkbox-utils.sh` - Plan progress tracking
- `checkpoint-utils.sh` - Build resumption
- `plan-core-bundle.sh` - Progressive plan operations
- `convert-core.sh` - Document conversion

All libraries use semantic versioning and version checks where required.

### Performance and Maintainability

#### Strengths

1. **Error Recovery**: Comprehensive error logging with queryable JSONL format enables `/errors` → `/repair` → `/build` workflow
2. **State Persistence**: Robust state management across bash block boundaries prevents data loss
3. **Agent Integration**: Clean separation between command orchestration and agent execution
4. **Progressive Workflow**: `/expand` and `/collapse` support on-demand plan complexity
5. **Documentation**: Extensive README (905 lines) with architecture diagrams and examples

#### Bottlenecks

1. **Initialization Overhead**: 30-40 line initialization block repeated in every bash block of workflow commands
2. **Bash Block Fragmentation**: `/expand` (32 blocks) and `/collapse` (29 blocks) have excessive fragmentation
3. **Documentation Variance**: "Block N" vs "Part N" vs "Phase N" naming inconsistency
4. **State Restoration Pattern**: Same 20-30 line state loading pattern repeated in every block
5. **Error Context Setup**: Identical 10-line error logging context restoration in every block

### Standards Compliance

Commands demonstrate excellent adherence to existing standards:

**Output Formatting Standards** (from `/home/benjamin/.config/CLAUDE.md:48-56`):
- All commands use `2>/dev/null` for library sourcing ✓
- Console summaries use 4-section format with `print_artifact_summary()` ✓
- Comments describe WHAT code does (not WHY) ✓

**Error Logging Standards** (from `/home/benjamin/.config/CLAUDE.md:58-88`):
- All commands source error-handling library early ✓
- Workflow metadata set before operations (`COMMAND_NAME`, `WORKFLOW_ID`, `USER_ARGS`) ✓
- Errors logged with standardized types ✓
- Bash error traps configured via `setup_bash_error_trap()` ✓

**Code Standards** (inferred from patterns):
- Fail-fast with `set -e` where appropriate ✓
- Exit code capture patterns: `CMD; EXIT_CODE=$?` ✓
- Absolute paths only (no relative paths) ✓
- History expansion disabled (`set +H`) ✓

## Recommendations

### High-Priority Optimizations

#### 1. Extract Common Initialization Library

**Problem**: 30-40 line initialization block repeated in every bash block of workflow commands

**Solution**: Create `/home/benjamin/.config/.claude/lib/workflow/command-initialization.sh` with:

```bash
#!/usr/bin/env bash
# Standardized command initialization for workflow commands
# Version: 1.0.0

init_command_block() {
  local workflow_id_file="$1"
  local command_name="$2"

  # Project directory detection
  if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    current_dir="$(pwd)"
    while [ "$current_dir" != "/" ]; do
      [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
      current_dir="$(dirname "$current_dir")"
    done
  fi

  export CLAUDE_PROJECT_DIR

  # Load workflow ID
  if [ -f "$workflow_id_file" ]; then
    WORKFLOW_ID=$(cat "$workflow_id_file" 2>/dev/null)
    export WORKFLOW_ID
  else
    echo "ERROR: Workflow ID file not found: $workflow_id_file" >&2
    return 1
  fi

  # Source core libraries
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || return 1
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || return 1
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || return 1

  # Load and validate state
  load_workflow_state "$WORKFLOW_ID" false || return 1

  # Restore error logging context
  if [ -z "${COMMAND_NAME:-}" ]; then
    COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "$command_name")
  fi
  if [ -z "${USER_ARGS:-}" ]; then
    USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
  fi
  export COMMAND_NAME USER_ARGS

  # Setup error trap
  setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

  # Validate state file
  if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "state_error" "State file validation failed" "init_command_block" \
      "$(jq -n --arg path "${STATE_FILE:-UNDEFINED}" '{state_file: $path}')"
    return 1
  fi

  return 0
}
```

**Usage**: Replace 40 lines with 2 lines in each bash block:
```bash
set +H
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/command-initialization.sh" || exit 1
init_command_block "${HOME}/.claude/tmp/plan_state_id.txt" "/plan" || exit 1
```

**Impact**: Reduces code duplication by 1,200+ lines across all workflow commands (30-40 lines × 6 commands × average 5 blocks = 900-1,200 lines)

#### 2. Consolidate Bash Blocks in `/expand` and `/collapse`

**Problem**: `/expand` (32 blocks) and `/collapse` (29 blocks) have 4x-10x more fragmentation than other commands

**Analysis**:
- `/plan` achieves full workflow in 4 bash blocks
- `/research` achieves full workflow in 3 bash blocks
- `/expand` and `/collapse` could consolidate to 6-8 blocks

**Target Reduction**:
- `/expand`: 32 → 8 blocks (75% reduction)
- `/collapse`: 29 → 8 blocks (72% reduction)

**Consolidation Strategy**:
- Combine adjacent blocks with no agent invocations between them
- Group validation operations into single "validation block"
- Merge state persistence operations at phase boundaries only
- Keep agent invocations as natural block separators

**Benefits**:
- Reduced state serialization/deserialization overhead
- Fewer "EXECUTE NOW" instructions for Claude
- Improved execution performance
- Better maintainability

#### 3. Standardize Documentation Section Naming

**Problem**: Inconsistent section naming across commands ("Block N" vs "Part N" vs "Phase N")

**Current State**:
- `/plan`, `/build`, `/research`: Use "Block N" pattern
- `/debug`: Uses "Part N" pattern
- `/expand`, `/collapse`: Mix of patterns

**Recommended Standard**:

```markdown
## Block N: [Phase Name]

**EXECUTE NOW**: [Instructions]

[Task invocation or bash block]
```

**Naming Convention**:
- "Block" for bash execution blocks
- "Phase" for workflow stages in console output
- "Part" reserved for breaking down complex blocks

**Migration**: Update `/debug` to use "Block" pattern for consistency

#### 4. Create Command Template Library

**Problem**: New commands lack standardized starting point

**Solution**: Create `/home/benjamin/.config/.claude/commands/templates/workflow-command-template.md`:

```markdown
---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob
argument-hint: <description> [--file <path>] [--complexity 1-4]
description: [One-line command description]
command-type: primary|workflow|utility
dependent-agents:
  - [agent-name]
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
documentation: See .claude/docs/guides/commands/[command]-guide.md
---

# /[command] - [Full Name]

YOU ARE EXECUTING [workflow description].

**Workflow Type**: [workflow-type]
**Terminal State**: [terminal-state]
**Expected Output**: [output description]

## Block 1: Initial Setup and State Initialization

**EXECUTE NOW**: [Instructions for capturing arguments]

```bash
set +H  # CRITICAL: Disable history expansion

# Use command-initialization.sh library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/command-initialization.sh" || exit 1
init_command_block "${HOME}/.claude/tmp/[command]_state_id.txt" "/[command]" || exit 1

# Command-specific setup
[...]
```

[Additional blocks following standard patterns]
```

**Benefits**:
- Ensures new commands follow established patterns
- Reduces development time for new commands
- Maintains consistency across command suite

### Medium-Priority Optimizations

#### 5. Enhance README Navigation Structure

**Problem**: 905-line README is comprehensive but could benefit from hierarchical navigation

**Recommendation**: Add table of contents at top:

```markdown
# Commands Directory

## Quick Navigation
- [Core Workflow](#core-workflow) - /research → /plan → /revise → /build
- [Primary Commands](#primary-commands) - /build, /plan, /debug, /research
- [Workflow Commands](#workflow-commands) - /expand, /collapse, /revise
- [Utility Commands](#utility-commands) - /errors, /repair, /setup, /convert-docs, /optimize-claude
- [Common Flags](#common-flags) - --file, --complexity, --dry-run, --auto-mode
- [Command Architecture](#command-architecture) - System design overview
- [Creating Custom Commands](#creating-custom-commands) - Development guide
- [Best Practices](#best-practices) - Command design principles
```

**Current**: Single-level sections require scrolling
**Improved**: Jump to any section in 1 click

#### 6. Document Bash Block Budget Guidelines

**Problem**: No established guidelines for target bash block count

**Recommendation**: Add to `/home/benjamin/.config/.claude/docs/reference/standards/command-standards.md`:

```markdown
## Bash Block Budget Guidelines

### Target Block Counts by Command Type

**Primary Workflow Commands**: 3-8 blocks
- Example: /plan (4 blocks), /build (7 blocks)
- Rationale: One block per major workflow phase

**Utility Commands**: 2-4 blocks
- Example: /errors (2 blocks), /repair (3 blocks)
- Rationale: Simple operations, minimal state

**Progressive Operations**: 6-10 blocks
- Target for /expand and /collapse after consolidation
- Rationale: Multiple structural transformation stages

### Block Consolidation Triggers
- More than 10 blocks: Review for consolidation opportunities
- Adjacent blocks with no agent invocations: Merge
- Validation-only blocks: Combine into single validation phase
```

#### 7. Standardize Topic Naming Integration

**Problem**: Topic naming agent invocation pattern slightly differs between commands

**Current State**:
- All commands invoke `topic-naming-agent.md` correctly
- Slight variations in error handling and fallback logic
- Fallback to `no_name` is consistent but logging differs

**Recommendation**: Extract topic naming into helper function in `workflow-initialization.sh`:

```bash
invoke_topic_naming_agent() {
  local workflow_description="$1"
  local command_name="$2"
  local workflow_id="$3"

  # [Standardized topic naming logic]
  # Returns: Sets TOPIC_NAME and NAMING_STRATEGY
}
```

### Low-Priority Enhancements

#### 8. Add Command Performance Metrics

**Opportunity**: No performance tracking currently implemented

**Recommendation**: Add optional performance logging to command-initialization.sh:

```bash
COMMAND_START_TIME=$(date +%s)
# ... command execution ...
COMMAND_END_TIME=$(date +%s)
COMMAND_DURATION=$((COMMAND_END_TIME - COMMAND_START_TIME))
echo "Command execution time: ${COMMAND_DURATION}s" >> "${HOME}/.claude/data/metrics/command_performance.log"
```

**Benefits**: Enables performance regression detection and optimization prioritization

#### 9. Command Dependency Visualization

**Opportunity**: Create visual dependency graph of command → agent → library relationships

**Tool**: Generate Graphviz diagram from frontmatter metadata:
```bash
#!/usr/bin/env bash
# Parse all command frontmatter and generate dependency graph
# Output: .claude/docs/diagrams/command-dependencies.dot
```

**Benefits**: Visual understanding of system architecture for new contributors

## References

### Command Files Analyzed
- `/home/benjamin/.config/.claude/commands/build.md` (lines 1-1529)
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 1-944)
- `/home/benjamin/.config/.claude/commands/debug.md` (lines 1-1307)
- `/home/benjamin/.config/.claude/commands/research.md` (lines 1-666)
- `/home/benjamin/.config/.claude/commands/expand.md` (lines 1-1144)
- `/home/benjamin/.config/.claude/commands/collapse.md` (lines 1-744)
- `/home/benjamin/.config/.claude/commands/revise.md` (lines 1-978)
- `/home/benjamin/.config/.claude/commands/errors.md` (lines 1-255)
- `/home/benjamin/.config/.claude/commands/repair.md` (lines 1-679)
- `/home/benjamin/.config/.claude/commands/setup.md` (lines 1-356)
- `/home/benjamin/.config/.claude/commands/convert-docs.md` (lines 1-501)
- `/home/benjamin/.config/.claude/commands/optimize-claude.md` (lines 1-641)
- `/home/benjamin/.config/.claude/commands/README.md` (lines 1-905)
- `/home/benjamin/.config/.claude/commands/shared/README.md` (lines 1-86)

### Library Functions Referenced
- `/home/benjamin/.config/.claude/lib/core/state-persistence.sh` - State management
- `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh` - State transitions
- `/home/benjamin/.config/.claude/lib/core/error-handling.sh` - Error logging
- `/home/benjamin/.config/.claude/lib/core/unified-location-detection.sh` - Path resolution
- `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` - Workflow setup
- `/home/benjamin/.config/.claude/lib/core/summary-formatting.sh` - Output formatting
- `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh` - Progress tracking
- `/home/benjamin/.config/.claude/lib/workflow/checkpoint-utils.sh` - Build resumption

### Standards Documents Referenced
- `/home/benjamin/.config/CLAUDE.md` (lines 48-88) - Output formatting and error logging standards
- `/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md` - Coding conventions
- `/home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md` - Output standards
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` - Directory structure

### Pattern Analysis
- State persistence: 379 occurrences across 6 workflow commands
- Error handling: 171 occurrences across 9 commands
- History expansion protection: 38 occurrences across all commands
- Agent invocations: 106 "EXECUTE NOW" + "Task {" patterns
- Bash blocks: 146 total blocks across 12 commands (average: 12 blocks/command)
- Metadata frontmatter: 142 occurrences across 23 files (100% compliance)
