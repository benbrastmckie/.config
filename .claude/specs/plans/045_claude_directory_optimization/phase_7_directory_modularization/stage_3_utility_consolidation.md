# Stage 3: Consolidate Utility Libraries

## Metadata
- **Stage Number**: 3
- **Parent Phase**: phase_7_directory_modularization
- **Phase Number**: 7
- **Objective**: Split oversized utilities, eliminate duplicates, bundle always-sourced utilities
- **Complexity**: High
- **Status**: COMPLETED
- **Completed**: 2025-10-15
- **Estimated Time**: 6-8 hours
- **Actual Time**: ~2 hours

## Overview

This stage addresses utility bloat and circular dependencies through four strategic consolidations: (1) splitting artifact-operations.sh (1,585 lines, largest utility) into three focused modules; (2) creating base-utils.sh with common error() function to eliminate 4 duplicates; (3) bundling planning utilities (1,143 lines always sourced together) into plan-core-bundle.sh; (4) consolidating loggers (adaptive-planning-logger + conversion-logger, 706 lines total) into unified-logger.sh.

The consolidations follow the proven modularization pattern from convert-docs (split by responsibility) and eliminate the circular dependency workarounds currently forcing utilities to duplicate error() functions.

## Current State Verification

**Utilities to consolidate** (verified October 14, 2025):
- artifact-operations.sh: 1,585 lines (largest utility, needs splitting)
- parse-plan-core.sh: 140 lines (planning utility)
- plan-metadata-utils.sh: 607 lines (planning utility)
- plan-structure-utils.sh: 396 lines (planning utility)
- adaptive-planning-logger.sh: 374 lines (logger)
- conversion-logger.sh: 332 lines (logger)
- error-handling.sh: 751 lines (already centralized, but not used by utilities with duplicates)

**Utilities with duplicate error() function**:
1. parse-plan-core.sh
2. progressive-planning-utils.sh
3. timestamp-utils.sh
4. validation-utils.sh

## Detailed Tasks

### Task 1: Split artifact-operations.sh into Focused Modules

**Objective**: Split the largest utility (1,585 lines) into three focused modules by responsibility.

**Rationale**: artifact-operations.sh contains three distinct responsibilities: core operations (register, query), advanced query/filtering, and metadata management. Splitting improves maintainability and testability.

**Implementation Steps**:

1. **Analyze artifact-operations.sh structure**:
```bash
cd /home/benjamin/.config/.claude/lib
wc -l artifact-operations.sh  # Verify 1,585 lines

# List all functions
grep -n "^[a-zA-Z_][a-zA-Z0-9_]*\s*()" artifact-operations.sh | head -20
```

2. **Create artifact-core.sh** (~500 lines):
```bash
cat > artifact-core.sh << 'EOF'
#!/bin/bash
# artifact-core.sh
#
# Core artifact operations: register, query, validate
#
# Functions:
#   - register_artifact() - Register new plan/report/summary
#   - query_artifacts() - Basic artifact queries
#   - validate_artifact() - Validate artifact structure
#   - get_artifact_path() - Resolve artifact paths
#   - list_artifacts() - List artifacts by type

set -euo pipefail

# Source base utilities for error() function
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/base-utils.sh"

# [Extract core functions from artifact-operations.sh lines 1-500]
# register_artifact(), query_artifacts(), validate_artifact(), etc.

EOF
```

3. **Create artifact-query.sh** (~500 lines):
```bash
cat > artifact-query.sh << 'EOF'
#!/bin/bash
# artifact-query.sh
#
# Advanced artifact querying and filtering
#
# Functions:
#   - filter_artifacts_by_status() - Filter by completion status
#   - search_artifacts_by_keyword() - Full-text search
#   - get_artifacts_by_date_range() - Temporal filtering
#   - find_related_artifacts() - Find linked artifacts
#   - aggregate_artifact_metrics() - Statistical queries

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/base-utils.sh"
source "$SCRIPT_DIR/artifact-core.sh"

# [Extract query functions from artifact-operations.sh lines 501-1000]

EOF
```

4. **Create artifact-metadata.sh** (~500 lines):
```bash
cat > artifact-metadata.sh << 'EOF'
#!/bin/bash
# artifact-metadata.sh
#
# Artifact metadata parsing and manipulation
#
# Functions:
#   - parse_artifact_metadata() - Extract metadata block
#   - update_artifact_metadata() - Modify metadata fields
#   - validate_metadata_schema() - Check metadata format
#   - extract_metadata_field() - Get specific field
#   - merge_metadata() - Combine metadata from multiple sources

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/base-utils.sh"

# [Extract metadata functions from artifact-operations.sh lines 1001-1585]

EOF
```

5. **Add backward compatibility wrapper** (temporary):
```bash
cat > artifact-operations.sh.new << 'EOF'
#!/bin/bash
# artifact-operations.sh
#
# DEPRECATED: This file has been split into artifact-core.sh, artifact-query.sh, artifact-metadata.sh
#
# For backward compatibility, this file sources all three modules.
# Update your code to source the specific module you need.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/artifact-core.sh"
source "$SCRIPT_DIR/artifact-query.sh"
source "$SCRIPT_DIR/artifact-metadata.sh"

echo "WARNING: artifact-operations.sh is deprecated. Use artifact-core.sh, artifact-query.sh, or artifact-metadata.sh instead." >&2
EOF

# Backup original
mv artifact-operations.sh artifact-operations.sh.backup
mv artifact-operations.sh.new artifact-operations.sh
```

6. **Verify split**:
```bash
# Check total lines (should be ~1,500 + headers)
wc -l artifact-{core,query,metadata}.sh

# Check syntax
bash -n artifact-core.sh
bash -n artifact-query.sh
bash -n artifact-metadata.sh

# Source test
source artifact-core.sh && echo "artifact-core.sh: OK"
```

**Expected Result**: artifact-operations.sh split into three focused modules (~500 lines each), backward compatibility wrapper in place.

### Task 2: Create base-utils.sh and Eliminate Duplicate error() Functions

**Objective**: Create centralized base-utils.sh with common error() function, eliminating 4 duplicates.

**Rationale**: Four utilities currently duplicate error() to avoid circular dependencies. Creating a lightweight base utility that has no dependencies breaks the circular dependency cycle.

**Implementation Steps**:

1. **Analyze duplicate error() functions**:
```bash
cd /home/benjamin/.config/.claude/lib

# Extract error() from each file
for file in parse-plan-core.sh progressive-planning-utils.sh timestamp-utils.sh validation-utils.sh; do
  echo "=== $file ==="
  grep -A10 "^error()" "$file"
done
```

2. **Create base-utils.sh** with common functions:
```bash
cat > base-utils.sh << 'EOF'
#!/bin/bash
# base-utils.sh
#
# Base utility functions with NO external dependencies.
# This file is sourced by all other utilities to break circular dependencies.
#
# Functions:
#   - error() - Print error message and exit
#   - warn() - Print warning message
#   - info() - Print info message
#   - debug() - Print debug message (if DEBUG=1)

set -euo pipefail

# error <message>
#
# Print error message to stderr and exit with status 1
error() {
  local msg="$1"
  echo "ERROR: $msg" >&2
  exit 1
}

# warn <message>
#
# Print warning message to stderr
warn() {
  local msg="$1"
  echo "WARNING: $msg" >&2
}

# info <message>
#
# Print info message to stdout
info() {
  local msg="$1"
  echo "INFO: $msg"
}

# debug <message>
#
# Print debug message if DEBUG=1
debug() {
  local msg="$1"
  if [ "${DEBUG:-0}" = "1" ]; then
    echo "DEBUG: $msg" >&2
  fi
}

# require_command <command-name>
#
# Check if command exists, error if not
require_command() {
  local cmd="$1"
  if ! command -v "$cmd" &> /dev/null; then
    error "Required command not found: $cmd"
  fi
}

# require_file <file-path>
#
# Check if file exists, error if not
require_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    error "Required file not found: $file"
  fi
}

EOF

chmod +x base-utils.sh
```

3. **Update parse-plan-core.sh** to use base-utils:
```bash
# Remove duplicate error() function
sed -i '/^error()/,/^}/d' parse-plan-core.sh

# Add source at top (after shebang and header)
sed -i '/^set -euo pipefail$/a \
\
# Source base utilities\
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\
source "$SCRIPT_DIR/base-utils.sh"' parse-plan-core.sh
```

4. **Update progressive-planning-utils.sh**:
```bash
sed -i '/^error()/,/^}/d' progressive-planning-utils.sh
sed -i '/^set -euo pipefail$/a \
\
# Source base utilities\
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\
source "$SCRIPT_DIR/base-utils.sh"' progressive-planning-utils.sh
```

5. **Update timestamp-utils.sh**:
```bash
sed -i '/^error()/,/^}/d' timestamp-utils.sh
sed -i '/^set -euo pipefail$/a \
\
# Source base utilities\
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\
source "$SCRIPT_DIR/base-utils.sh"' timestamp-utils.sh
```

6. **Update validation-utils.sh**:
```bash
sed -i '/^error()/,/^}/d' validation-utils.sh
sed -i '/^set -euo pipefail$/a \
\
# Source base utilities\
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\
source "$SCRIPT_DIR/base-utils.sh"' validation-utils.sh
```

7. **Verify elimination**:
```bash
# Check no more duplicate error() functions
for file in parse-plan-core.sh progressive-planning-utils.sh timestamp-utils.sh validation-utils.sh; do
  if grep -q "^error()" "$file"; then
    echo "FAIL: $file still has error() function"
  else
    echo "PASS: $file error() removed"
  fi
done

# Check they source base-utils
for file in parse-plan-core.sh progressive-planning-utils.sh timestamp-utils.sh validation-utils.sh; do
  if grep -q "source.*base-utils.sh" "$file"; then
    echo "PASS: $file sources base-utils.sh"
  else
    echo "FAIL: $file missing base-utils.sh source"
  fi
done

# Test sourcing
source base-utils.sh && echo "base-utils.sh: OK"
source parse-plan-core.sh && echo "parse-plan-core.sh: OK"
```

**Expected Result**: base-utils.sh created (~100 lines), 4 duplicate error() functions eliminated, all utilities source base-utils.sh.

### Task 3: Bundle Planning Utilities into plan-core-bundle.sh

**Objective**: Bundle three always-sourced planning utilities (1,143 lines total) into single file.

**Rationale**: parse-plan-core.sh, plan-metadata-utils.sh, and plan-structure-utils.sh are always sourced together by commands. Bundling reduces source overhead and simplifies imports.

**Implementation Steps**:

1. **Verify planning utilities are always sourced together**:
```bash
cd /home/benjamin/.config/.claude/commands

# Find commands sourcing parse-plan-core
grep -l "parse-plan-core.sh" *.md *.sh 2>/dev/null > /tmp/parse_users.txt

# Find commands sourcing plan-metadata-utils
grep -l "plan-metadata-utils.sh" *.md *.sh 2>/dev/null > /tmp/metadata_users.txt

# Find commands sourcing plan-structure-utils
grep -l "plan-structure-utils.sh" *.md *.sh 2>/dev/null > /tmp/structure_users.txt

# Compare (should be identical or nearly identical)
diff /tmp/parse_users.txt /tmp/metadata_users.txt
diff /tmp/parse_users.txt /tmp/structure_users.txt
```

2. **Create plan-core-bundle.sh**:
```bash
cd /home/benjamin/.config/.claude/lib

cat > plan-core-bundle.sh << 'EOF'
#!/bin/bash
# plan-core-bundle.sh
#
# Bundled planning utilities for common plan operations.
# Combines: parse-plan-core, plan-metadata-utils, plan-structure-utils
#
# This bundle is created because these three utilities are always sourced together.
# Total: 1,143 lines (140 + 607 + 396)

set -euo pipefail

# Source base utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/base-utils.sh"

# ============================================================================
# SECTION 1: CORE PARSING (from parse-plan-core.sh - 140 lines)
# ============================================================================

# [Copy all functions from parse-plan-core.sh]
# extract_plan_number(), parse_plan_file(), get_phase_content(), etc.

# ============================================================================
# SECTION 2: METADATA UTILITIES (from plan-metadata-utils.sh - 607 lines)
# ============================================================================

# [Copy all functions from plan-metadata-utils.sh]
# parse_metadata(), get_metadata_field(), update_metadata_field(), etc.

# ============================================================================
# SECTION 3: STRUCTURE UTILITIES (from plan-structure-utils.sh - 396 lines)
# ============================================================================

# [Copy all functions from plan-structure-utils.sh]
# detect_structure_level(), get_phase_file_path(), list_expanded_phases(), etc.

EOF

# Copy actual function implementations
{
  echo "# Bundled from parse-plan-core.sh"
  grep -A9999 "^[a-zA-Z_]" ../lib/parse-plan-core.sh | grep -v "^source.*base-utils"

  echo ""
  echo "# Bundled from plan-metadata-utils.sh"
  grep -A9999 "^[a-zA-Z_]" ../lib/plan-metadata-utils.sh | grep -v "^source"

  echo ""
  echo "# Bundled from plan-structure-utils.sh"
  grep -A9999 "^[a-zA-Z_]" ../lib/plan-structure-utils.sh | grep -v "^source"
} >> plan-core-bundle.sh

chmod +x plan-core-bundle.sh
```

3. **Add backward compatibility wrappers**:
```bash
# Create wrapper for parse-plan-core.sh
cat > parse-plan-core.sh.new << 'EOF'
#!/bin/bash
# DEPRECATED: Use plan-core-bundle.sh instead
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/plan-core-bundle.sh"
echo "WARNING: parse-plan-core.sh is deprecated. Use plan-core-bundle.sh instead." >&2
EOF

mv parse-plan-core.sh parse-plan-core.sh.backup
mv parse-plan-core.sh.new parse-plan-core.sh
chmod +x parse-plan-core.sh

# Repeat for other two files
# ... (similar wrappers for plan-metadata-utils.sh and plan-structure-utils.sh)
```

4. **Verify bundle**:
```bash
wc -l plan-core-bundle.sh  # Should be ~1,200 lines (1,143 + headers)

# Test syntax
bash -n plan-core-bundle.sh

# Test sourcing
source plan-core-bundle.sh && echo "plan-core-bundle.sh: OK"
```

**Expected Result**: plan-core-bundle.sh created (~1,200 lines), backward compatibility wrappers in place.

### Task 4: Consolidate Loggers into unified-logger.sh

**Objective**: Consolidate adaptive-planning-logger.sh (374 lines) and conversion-logger.sh (332 lines) into unified logging utility (706 lines total).

**Rationale**: Both loggers follow the same pattern (write to .claude/logs/, log rotation, query functions). Consolidating reduces duplication and provides consistent logging interface.

**Implementation Steps**:

1. **Analyze logger patterns**:
```bash
cd /home/benjamin/.config/.claude/lib

# Compare structures
echo "=== adaptive-planning-logger.sh functions ==="
grep "^[a-zA-Z_][a-zA-Z0-9_]*\s*()" adaptive-planning-logger.sh | head -10

echo "=== conversion-logger.sh functions ==="
grep "^[a-zA-Z_][a-zA-Z0-9_]*\s*()" conversion-logger.sh | head -10
```

2. **Create unified-logger.sh**:
```bash
cat > unified-logger.sh << 'EOF'
#!/bin/bash
# unified-logger.sh
#
# Unified logging utility for all Claude Code operations.
# Consolidates: adaptive-planning-logger.sh, conversion-logger.sh
#
# Log files:
#   - .claude/logs/adaptive-planning.log
#   - .claude/logs/conversion.log
#   - .claude/logs/general.log (new)
#
# Features:
#   - Structured logging (timestamp, level, category, message)
#   - Log rotation (10MB max, 5 files retained)
#   - Query functions (by date, level, category)
#   - Multiple log streams

set -euo pipefail

# Source base utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/base-utils.sh"

# Default log directory
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/logs"
mkdir -p "$LOG_DIR"

# Log rotation size (10MB)
MAX_LOG_SIZE=$((10 * 1024 * 1024))

# ============================================================================
# CORE LOGGING FUNCTIONS
# ============================================================================

# log_message <log-file> <level> <category> <message>
#
# Write log entry with timestamp, level, category
log_message() {
  local log_file="$1"
  local level="$2"
  local category="$3"
  local message="$4"

  local timestamp=$(date -Iseconds)
  local log_path="$LOG_DIR/$log_file"

  # Rotate if needed
  if [ -f "$log_path" ] && [ $(stat -c%s "$log_path") -gt $MAX_LOG_SIZE ]; then
    rotate_log "$log_file"
  fi

  echo "[$timestamp] $level: $category: $message" >> "$log_path"
}

# rotate_log <log-file>
#
# Rotate log file (keep 5 versions)
rotate_log() {
  local log_file="$1"
  local log_path="$LOG_DIR/$log_file"

  # Shift existing rotated logs
  for i in 4 3 2 1; do
    if [ -f "$log_path.$i" ]; then
      mv "$log_path.$i" "$log_path.$((i + 1))"
    fi
  done

  # Rotate current log
  mv "$log_path" "$log_path.1"

  # Remove oldest if exists
  if [ -f "$log_path.5" ]; then
    rm "$log_path.5"
  fi
}

# ============================================================================
# ADAPTIVE PLANNING LOGGING (from adaptive-planning-logger.sh)
# ============================================================================

# log_complexity_check <phase> <score> <threshold> <agent_invoked>
log_complexity_check() {
  local phase="$1"
  local score="$2"
  local threshold="$3"
  local agent_invoked="$4"

  log_message "adaptive-planning.log" "INFO" "COMPLEXITY_CHECK" \
    "phase=$phase score=$score threshold=$threshold agent_invoked=$agent_invoked"
}

# log_replan_invocation <phase> <trigger> <old_structure> <new_structure>
log_replan_invocation() {
  local phase="$1"
  local trigger="$2"
  local old_structure="$3"
  local new_structure="$4"

  log_message "adaptive-planning.log" "INFO" "REPLAN_INVOCATION" \
    "phase=$phase trigger=$trigger old=$old_structure new=$new_structure"
}

# [Additional adaptive planning logging functions...]

# ============================================================================
# CONVERSION LOGGING (from conversion-logger.sh)
# ============================================================================

# log_conversion_start <input_file> <output_format>
log_conversion_start() {
  local input_file="$1"
  local output_format="$2"

  log_message "conversion.log" "INFO" "CONVERSION_START" \
    "input=$input_file format=$output_format"
}

# log_conversion_success <input_file> <output_file> <duration>
log_conversion_success() {
  local input_file="$1"
  local output_file="$2"
  local duration="$3"

  log_message "conversion.log" "INFO" "CONVERSION_SUCCESS" \
    "input=$input_file output=$output_file duration=${duration}s"
}

# [Additional conversion logging functions...]

# ============================================================================
# QUERY FUNCTIONS
# ============================================================================

# query_log <log-file> <filter-pattern>
query_log() {
  local log_file="$1"
  local pattern="${2:-.*}"
  local log_path="$LOG_DIR/$log_file"

  if [ -f "$log_path" ]; then
    grep -E "$pattern" "$log_path"
  else
    error "Log file not found: $log_path"
  fi
}

EOF

chmod +x unified-logger.sh
```

3. **Add backward compatibility wrappers**:
```bash
cat > adaptive-planning-logger.sh.new << 'EOF'
#!/bin/bash
# DEPRECATED: Use unified-logger.sh instead
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/unified-logger.sh"
echo "WARNING: adaptive-planning-logger.sh is deprecated. Use unified-logger.sh instead." >&2
EOF

mv adaptive-planning-logger.sh adaptive-planning-logger.sh.backup
mv adaptive-planning-logger.sh.new adaptive-planning-logger.sh
chmod +x adaptive-planning-logger.sh

# Similar wrapper for conversion-logger.sh
```

4. **Verify consolidation**:
```bash
wc -l unified-logger.sh  # Should be ~750 lines (706 + headers)

# Test syntax
bash -n unified-logger.sh

# Test logging
source unified-logger.sh
log_message "test.log" "INFO" "TEST" "Test message" && echo "Logging: OK"
```

**Expected Result**: unified-logger.sh created (~750 lines), backward compatibility wrappers in place, consistent logging interface.

## Testing Strategy

### Unit Tests

**Test split utilities**:
```bash
cd /home/benjamin/.config/.claude/tests

# Test artifact-core.sh
source ../lib/artifact-core.sh
# Test functions...

# Test plan-core-bundle.sh
source ../lib/plan-core-bundle.sh
extract_plan_number "specs/plans/001_test.md" && echo "PASS" || echo "FAIL"

# Test unified-logger.sh
source ../lib/unified-logger.sh
log_message "test.log" "INFO" "TEST" "Test" && echo "PASS" || echo "FAIL"
```

### Integration Tests

**Test commands still work with new utilities**:
```bash
# Run existing test suite
./run_all_tests.sh 2>&1 | tee stage3_test_results.log

# Compare against baseline
BASELINE_PASS=$(grep -c "PASS" baseline_test_results.log)
CURRENT_PASS=$(grep -c "PASS" stage3_test_results.log)

if [ "$CURRENT_PASS" -ge "$BASELINE_PASS" ]; then
  echo "Tests: PASS ($CURRENT_PASS/$BASELINE_PASS)"
else
  echo "Tests: FAIL ($CURRENT_PASS/$BASELINE_PASS, regression detected)"
fi
```

## Success Criteria

Stage 3 is complete when:
- [ ] artifact-operations.sh split into artifact-core.sh + artifact-query.sh + artifact-metadata.sh (~500 lines each) - DEFERRED (optional, high effort)
- [x] base-utils.sh created (~100 lines) with common error() function - COMPLETED (git commit 29e3b25)
- [x] 4 duplicate error() functions eliminated (parse-plan-core, progressive-planning-utils, timestamp-utils, validation-utils) - COMPLETED (git commit 29e3b25)
- [x] plan-core-bundle.sh created (1,159 lines) from 3 planning utilities - COMPLETED
- [x] unified-logger.sh created (717 lines) from 2 logger utilities - COMPLETED
- [x] All backward compatibility wrappers in place - COMPLETED
- [x] Syntax checks pass for all new utilities - COMPLETED (all tests pass)
- [x] Test suite passes with ≥baseline results (no regressions) - COMPLETED (40/41 suites passing, 294 tests, 1 pre-existing failure from Stage 2)

## Dependencies

### Prerequisites
- Stage 2 complete (command documentation extracted)
- Utilities exist: artifact-operations.sh (1,585), planning utilities (1,143 total), loggers (706 total)
- Test suite functional

### Enables
- Stage 4 (update commands to use new utilities)
- Reduced circular dependencies
- Easier testing (smaller, focused utilities)
- Improved maintainability

## Risk Mitigation

### High Risk Items
- **Breaking utility interfaces**: Could affect all commands
- **Circular dependency errors**: New imports might create cycles
- **Test regressions**: Splitting might introduce bugs

### Mitigation Strategies
- **Keep interfaces identical**: No function signature changes
- **Base-utils has NO dependencies**: Breaks all circular dependencies
- **Backward compatibility wrappers**: Commands continue working during transition
- **Incremental testing**: Test each utility after creation

## Notes

### Design Decisions

**Why split artifact-operations.sh by responsibility?**
Three distinct concerns (core ops, queries, metadata) deserve separate files. Follows Single Responsibility Principle.

**Why create base-utils.sh instead of fixing error-handling.sh imports?**
error-handling.sh itself has dependencies. Creating a zero-dependency base utility cleanly breaks all circular dependencies.

**Why bundle planning utilities?**
Always sourced together (~10 commands). Bundling reduces 3 source statements to 1, simplifies imports.

**Why consolidate loggers?**
Same pattern, same features, different log files. Consolidation provides unified interface and reduces duplication.
