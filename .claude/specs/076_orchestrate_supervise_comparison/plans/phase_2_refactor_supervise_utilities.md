# Phase 2: Refactor /supervise Phase 0 to Use Utilities - Detailed Implementation Specification

## Metadata
- **Parent Plan**: 002_optimize_supervise_location_detection.md
- **Phase Number**: 2
- **Dependencies**: Phase 1 (Topic Utilities Library)
- **Status**: Pending
- **Complexity**: 6/10 (medium-high)
- **Estimated Time**: 2-3 hours
- **Risk Level**: Medium
- **Created**: 2025-10-23
- **Assignee**: Expansion Specialist Agent

## Overview

This phase replaces the location-specialist agent invocation in /supervise Phase 0 with direct utility function calls, achieving 85-95% token reduction (from 75.6k to 7.5-11k tokens) and 20x speedup (from 25.2s to <1s).

**Core Transformation**:
- **Current**: Task tool → location-specialist agent → codebase search (15-20k tokens) → location calculation
- **Optimized**: Source utilities → bash functions → deterministic calculation (0 AI tokens)

**Key Insight**: 90%+ of workflows use simple location detection (project root + sequential topic number), which requires no AI reasoning—just deterministic bash logic.

## Objectives

### Primary Objectives
1. Replace Steps 3-4 in supervise.md Phase 0 (lines 397-443) with utility function calls
2. Maintain 100% compatibility with downstream phases (Phases 1-6)
3. Preserve exact location context format for subagent compatibility
4. Achieve 85-95% token reduction in location detection phase
5. Reduce execution time from 25.2s to <1s (20x+ speedup)

### Secondary Objectives
1. Add comprehensive error handling for edge cases
2. Implement verification checkpoints for directory creation
3. Add logging infrastructure for monitoring optimization impact
4. Create rollback mechanism for production safety

## Technical Design

### Architecture Changes

#### Before (Current Implementation)
```
┌─────────────────────────────────────────────────────────────┐
│ /supervise Phase 0: Location Detection                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  STEP 1: Parse workflow description                        │
│  STEP 2: Detect workflow scope                             │
│  STEP 3: Invoke location-specialist agent (Task tool)      │
│           ↓                                                 │
│        ┌──────────────────────────────────────────┐        │
│        │ location-specialist.md                   │        │
│        │ - Analyze workflow request (Grep/Glob)   │        │
│        │ - Search codebase (15-20k tokens)        │        │
│        │ - Determine specs root                   │        │
│        │ - Calculate topic number                 │        │
│        │ - Sanitize topic name                    │        │
│        │ - Create directory structure             │        │
│        │ - Generate location context              │        │
│        └──────────────────────────────────────────┘        │
│           ↓                                                 │
│  STEP 4: Parse location-specialist output                  │
│  STEP 5: Create topic directory structure                  │
│  STEP 6: Pre-calculate artifact paths                      │
│  STEP 7: Initialize tracking arrays                        │
│                                                             │
│  Token Cost: 75,600 tokens                                 │
│  Time Cost: 25.2 seconds                                   │
│  AI Cost: $0.68 (Sonnet 4.5)                              │
└─────────────────────────────────────────────────────────────┘
```

#### After (Optimized Implementation)
```
┌─────────────────────────────────────────────────────────────┐
│ /supervise Phase 0: Location Detection (Optimized)         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  STEP 1: Parse workflow description                        │
│  STEP 2: Detect workflow scope                             │
│  STEP 3: Source utility libraries                          │
│           ↓                                                 │
│        source .claude/lib/topic-utils.sh                   │
│        source .claude/lib/detect-project-dir.sh            │
│           ↓                                                 │
│  STEP 4: Detect project root (CLAUDE_PROJECT_DIR)          │
│  STEP 5: Determine specs directory (.claude/specs)         │
│  STEP 6: Calculate topic metadata (bash functions)         │
│           ↓                                                 │
│        TOPIC_NUM = get_next_topic_number($SPECS_ROOT)      │
│        TOPIC_NAME = sanitize_topic_name($WORKFLOW_DESC)    │
│        TOPIC_PATH = "${SPECS_ROOT}/${TOPIC_NUM}_..."       │
│           ↓                                                 │
│  STEP 7: Create directory structure (utility function)     │
│           ↓                                                 │
│        create_topic_structure($TOPIC_PATH)                 │
│           ↓                                                 │
│  STEP 8: Generate location context (inline bash)           │
│  STEP 9: Pre-calculate artifact paths                      │
│  STEP 10: Initialize tracking arrays                       │
│                                                             │
│  Token Cost: 7,500-11,000 tokens (85-95% reduction)       │
│  Time Cost: 0.7-1.0 seconds (20x+ speedup)                │
│  AI Cost: $0.00 (no agent invocation)                     │
└─────────────────────────────────────────────────────────────┘
```

### Code Location Mapping

**File to Modify**: `/home/benjamin/.config/.claude/commands/supervise.md`

**Sections Affected**:
1. **Phase 0 Header** (lines 343-350): Update description to reflect utility-based approach
2. **STEP 3-4 Replacement** (lines 397-443): Replace agent invocation with utility calls
3. **Error Handling** (new): Add verification checkpoints throughout
4. **Logging** (new): Add monitoring instrumentation

**Dependencies**:
- `.claude/lib/topic-utils.sh` (created in Phase 1)
- `.claude/lib/detect-project-dir.sh` (existing)
- `.claude/data/logs/` directory (create if needed)

## Detailed Implementation Steps

### Step 1: Create Backup and Prepare Environment

**Objective**: Ensure safe modification with rollback capability

**Commands**:
```bash
# Create timestamped backup
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
cp /home/benjamin/.config/.claude/commands/supervise.md \
   /home/benjamin/.config/.claude/commands/supervise.md.backup_phase2_${TIMESTAMP}

# Verify backup created
if [ ! -f "/home/benjamin/.config/.claude/commands/supervise.md.backup_phase2_${TIMESTAMP}" ]; then
  echo "ERROR: Backup creation failed"
  exit 1
fi

# Create logs directory if needed
mkdir -p /home/benjamin/.config/.claude/data/logs

echo "✓ Backup created: supervise.md.backup_phase2_${TIMESTAMP}"
echo "✓ Environment prepared"
```

**Verification**:
- [ ] Backup file exists with correct timestamp
- [ ] Logs directory exists and is writable
- [ ] Original supervise.md is unchanged

### Step 2: Update Phase 0 Header Documentation

**Objective**: Reflect the new utility-based approach in Phase 0 description

**File**: `/home/benjamin/.config/.claude/commands/supervise.md`
**Lines**: 343-350

**Current Content**:
```markdown
## Phase 0: Project Location and Path Pre-Calculation

**Objective**: Establish topic directory structure and calculate all artifact paths.

**Pattern**: location-specialist agent → directory creation → path export

**Critical**: ALL paths MUST be calculated before Phase 1 begins.
```

**New Content**:
```markdown
## Phase 0: Project Location and Path Pre-Calculation

**Objective**: Establish topic directory structure and calculate all artifact paths using deterministic utility functions.

**Pattern**: utility functions → directory creation → path export

**Optimization**: Uses bash utilities instead of AI agent (85-95% token reduction, 20x speedup)

**Critical**: ALL paths MUST be calculated before Phase 1 begins.
```

**Implementation**:
```bash
# Use Edit tool to update header
# Replace old pattern description with new optimized description
```

**Verification**:
- [ ] Header updated to reference "utility functions"
- [ ] Optimization note added
- [ ] Critical notice preserved

### Step 3: Replace STEP 3-4 with Utility Function Implementation

**Objective**: Replace agent invocation (lines 397-443) with utility function calls

**File**: `/home/benjamin/.config/.claude/commands/supervise.md`
**Lines to Replace**: 397-443 (47 lines)

**Current Content (to be replaced)**:
```markdown
STEP 3: Invoke location-specialist agent

Use the Task tool to invoke the location-specialist agent. The agent will determine the appropriate project location and topic metadata.

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Determine project location for workflow"
  prompt: "
    Read behavioral guidelines: .claude/agents/location-specialist.md

    Workflow Description: ${WORKFLOW_DESCRIPTION}

    Determine the appropriate location using the deepest directory that encompasses the workflow scope.

    Return ONLY these exact lines:
    LOCATION: <path>
    TOPIC_NUMBER: <NNN>
    TOPIC_NAME: <snake_case_name>
  "
}
```

STEP 4: Parse location-specialist output

```bash
# Extract location metadata from agent response
LOCATION=$(echo "$AGENT_OUTPUT" | grep "LOCATION:" | cut -d: -f2- | xargs)
TOPIC_NUM=$(echo "$AGENT_OUTPUT" | grep "TOPIC_NUMBER:" | cut -d: -f2 | xargs)
TOPIC_NAME=$(echo "$AGENT_OUTPUT" | grep "TOPIC_NAME:" | cut -d: -f2- | xargs)

# Validate required fields
if [ -z "$LOCATION" ] || [ -z "$TOPIC_NUM" ] || [ -z "$TOPIC_NAME" ]; then
  echo "❌ ERROR: Location-specialist failed to provide required metadata"
  echo "   LOCATION: $LOCATION"
  echo "   TOPIC_NUM: $TOPIC_NUM"
  echo "   TOPIC_NAME: $TOPIC_NAME"
  echo ""
  echo "Workflow TERMINATED."
  exit 1
fi

echo "Project Location: $LOCATION"
echo "Topic Number: $TOPIC_NUM"
echo "Topic Name: $TOPIC_NAME"
echo ""
```
```

**New Content (replacement)**:
```markdown
STEP 3: Source utility libraries

Load project detection and topic management utilities.

```bash
# Source utility libraries (absolute paths from CLAUDE_CONFIG)
CLAUDE_LIB_DIR="${CLAUDE_CONFIG}/.claude/lib"

if [ ! -f "${CLAUDE_LIB_DIR}/detect-project-dir.sh" ]; then
  echo "❌ ERROR: detect-project-dir.sh not found at ${CLAUDE_LIB_DIR}"
  echo "   This is a critical dependency for location detection."
  exit 1
fi

if [ ! -f "${CLAUDE_LIB_DIR}/topic-utils.sh" ]; then
  echo "❌ ERROR: topic-utils.sh not found at ${CLAUDE_LIB_DIR}"
  echo "   This utility library is required (created in Phase 1)."
  echo "   Run Phase 1 of optimization plan before Phase 2."
  exit 1
fi

# Source libraries
source "${CLAUDE_LIB_DIR}/detect-project-dir.sh"
source "${CLAUDE_LIB_DIR}/topic-utils.sh"

echo "✓ Utility libraries loaded successfully"
```

STEP 4: Detect project root and specs directory

Determine the project root using existing detection utilities and locate the specs directory.

```bash
# Project root is already set by detect-project-dir.sh (sourced above)
PROJECT_ROOT="${CLAUDE_PROJECT_DIR}"

if [ -z "$PROJECT_ROOT" ]; then
  echo "❌ ERROR: CLAUDE_PROJECT_DIR not set"
  echo "   detect-project-dir.sh should have exported this variable."
  exit 1
fi

echo "Project Root: $PROJECT_ROOT"

# Determine specs directory (prefer .claude/specs, fallback to specs)
if [ -d "${PROJECT_ROOT}/.claude/specs" ]; then
  SPECS_ROOT="${PROJECT_ROOT}/.claude/specs"
  echo "Using existing specs directory: $SPECS_ROOT"
elif [ -d "${PROJECT_ROOT}/specs" ]; then
  SPECS_ROOT="${PROJECT_ROOT}/specs"
  echo "Using existing specs directory: $SPECS_ROOT"
else
  # Create .claude/specs as default
  SPECS_ROOT="${PROJECT_ROOT}/.claude/specs"
  echo "Creating new specs directory: $SPECS_ROOT"
  mkdir -p "$SPECS_ROOT"

  if [ ! -d "$SPECS_ROOT" ]; then
    echo "❌ ERROR: Failed to create specs directory at $SPECS_ROOT"
    exit 1
  fi

  echo "✓ Specs directory created successfully"
fi

echo ""
```

STEP 5: Calculate topic metadata using utilities

Use deterministic bash functions to calculate topic number and sanitize topic name.

```bash
# Calculate next topic number (deterministic: find max, increment)
TOPIC_NUM=$(get_next_topic_number "$SPECS_ROOT")

if [ -z "$TOPIC_NUM" ]; then
  echo "❌ ERROR: get_next_topic_number failed to return a topic number"
  exit 1
fi

# Validate topic number format (must be 3 digits)
if ! [[ "$TOPIC_NUM" =~ ^[0-9]{3}$ ]]; then
  echo "❌ ERROR: Invalid topic number format: '$TOPIC_NUM'"
  echo "   Expected: 3-digit zero-padded number (e.g., 001, 042, 127)"
  exit 1
fi

echo "Next Topic Number: $TOPIC_NUM"

# Sanitize workflow description to topic name
TOPIC_NAME=$(sanitize_topic_name "$WORKFLOW_DESCRIPTION")

if [ -z "$TOPIC_NAME" ]; then
  echo "❌ ERROR: sanitize_topic_name failed to generate a valid topic name"
  echo "   Workflow Description: $WORKFLOW_DESCRIPTION"
  exit 1
fi

# Validate topic name (must be lowercase alphanumeric + underscores)
if ! [[ "$TOPIC_NAME" =~ ^[a-z0-9_]+$ ]]; then
  echo "❌ ERROR: Invalid topic name format: '$TOPIC_NAME'"
  echo "   Expected: lowercase alphanumeric with underscores only"
  exit 1
fi

echo "Topic Name: $TOPIC_NAME"

# Construct topic directory path
TOPIC_PATH="${SPECS_ROOT}/${TOPIC_NUM}_${TOPIC_NAME}"

echo "Topic Directory: $TOPIC_PATH"
echo ""
```

STEP 6: Create topic directory structure

Create the complete directory structure using the utility function with verification.

```bash
# Create directory structure (6 subdirectories: reports, plans, summaries, debug, scripts, outputs)
if ! create_topic_structure "$TOPIC_PATH"; then
  echo "❌ ERROR: create_topic_structure failed for $TOPIC_PATH"
  echo "   Check directory permissions and disk space."
  exit 1
fi

# Explicit verification of all 6 required subdirectories
REQUIRED_SUBDIRS=("reports" "plans" "summaries" "debug" "scripts" "outputs")
MISSING_SUBDIRS=()

for subdir in "${REQUIRED_SUBDIRS[@]}"; do
  if [ ! -d "$TOPIC_PATH/$subdir" ]; then
    MISSING_SUBDIRS+=("$subdir")
  fi
done

if [ ${#MISSING_SUBDIRS[@]} -gt 0 ]; then
  echo "❌ ERROR: Incomplete directory structure at $TOPIC_PATH"
  echo "   Missing subdirectories: ${MISSING_SUBDIRS[*]}"
  exit 1
fi

echo "✓ Topic directory structure created successfully"
echo "  Base: $TOPIC_PATH"
echo "  Subdirectories: ${REQUIRED_SUBDIRS[*]}"
echo ""
```

STEP 7: Generate location context for downstream phases

Construct the location context object with absolute paths (maintains compatibility with existing Phase 1-6 code).

```bash
# Generate location context (YAML format for downstream phase compatibility)
# CRITICAL: All paths MUST be absolute for subagent compatibility
LOCATION_CONTEXT=$(cat <<EOF
topic_number: $TOPIC_NUM
topic_name: $TOPIC_NAME
topic_path: $TOPIC_PATH
artifact_paths:
  reports: $TOPIC_PATH/reports
  plans: $TOPIC_PATH/plans
  summaries: $TOPIC_PATH/summaries
  debug: $TOPIC_PATH/debug
  scripts: $TOPIC_PATH/scripts
  outputs: $TOPIC_PATH/outputs
project_root: $PROJECT_ROOT
specs_root: $SPECS_ROOT
EOF
)

# Export for downstream phases
export TOPIC_PATH TOPIC_NUM TOPIC_NAME PROJECT_ROOT SPECS_ROOT

echo "LOCATION_DETECTED: $TOPIC_PATH"
echo ""
echo "Location Context:"
echo "$LOCATION_CONTEXT"
echo ""
```
```

**Implementation Notes**:
1. **Absolute paths**: All paths use `$CLAUDE_CONFIG` and `$CLAUDE_PROJECT_DIR` for portability
2. **Error handling**: Every operation has validation and error messages
3. **Verification**: Directory creation is verified before proceeding
4. **Compatibility**: Location context format matches agent output exactly
5. **Logging**: Adds structured output for monitoring

**Code Differences Summary**:
- **Lines removed**: 47 (agent invocation + parsing)
- **Lines added**: ~120 (utility sourcing + validation + directory creation + context generation)
- **Net change**: +73 lines (more explicit error handling and verification)

### Step 4: Add Monitoring and Logging Infrastructure

**Objective**: Track optimization impact and enable data-driven decisions

**File**: `/home/benjamin/.config/.claude/commands/supervise.md`
**Location**: After STEP 7 (location context generation)

**New Content (insert)**:
```markdown
STEP 8: Log location detection metrics

Record location detection performance for monitoring dashboard.

```bash
# Log location detection metrics (for optimization tracking)
LOG_FILE="${CLAUDE_CONFIG}/.claude/data/logs/location-detection.log"
LOG_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Calculate token count (estimate: 7.5k-11k for bash utilities)
# Note: Actual token count is 0 for utilities (no AI invocation)
# We log estimated savings vs baseline (75.6k agent tokens)
TOKEN_ESTIMATE="~0 (utility functions)"
BASELINE_TOKENS="75600"
TOKEN_SAVINGS="100%"

# Calculate execution time (track Phase 0 duration)
PHASE_0_END_TIME=$(date +%s%N)
PHASE_0_DURATION_NS=$((PHASE_0_END_TIME - PHASE_0_START_TIME))
PHASE_0_DURATION_SEC=$(echo "scale=3; $PHASE_0_DURATION_NS / 1000000000" | bc)

# Log entry format: timestamp | command | method | topic | tokens | time | path
LOG_ENTRY="${LOG_TIMESTAMP} | /supervise | utility-functions | ${TOPIC_NUM}_${TOPIC_NAME} | ${TOKEN_ESTIMATE} (baseline: ${BASELINE_TOKENS}, savings: ${TOKEN_SAVINGS}) | ${PHASE_0_DURATION_SEC}s | ${TOPIC_PATH}"

echo "$LOG_ENTRY" >> "$LOG_FILE"

echo "✓ Metrics logged to location-detection.log"
echo ""
```
```

**Additional Code (in STEP 1)**:
```bash
# Add to STEP 1: Parse workflow description (after workflow validation)
# Start timing Phase 0 for performance monitoring
PHASE_0_START_TIME=$(date +%s%N)
```

**Verification**:
- [ ] PHASE_0_START_TIME captured at beginning of Phase 0
- [ ] Log entry written to location-detection.log after directory creation
- [ ] Log format matches monitoring dashboard expectations

### Step 5: Update Downstream Phase References

**Objective**: Ensure Phases 1-6 continue to work with new location context format

**Verification Required**:
The new location context format MUST match the expected format in downstream phases.

**Test Plan**:
1. Search for references to TOPIC_PATH, TOPIC_NUM, TOPIC_NAME in Phases 1-6
2. Verify all references expect exported environment variables (not parsed from agent output)
3. Confirm artifact_paths structure matches existing usage

**Commands**:
```bash
# Search for location context usage in supervise.md
cd /home/benjamin/.config
grep -n "TOPIC_PATH\|TOPIC_NUM\|TOPIC_NAME\|artifact_paths" .claude/commands/supervise.md | head -30

# Check for any agent output parsing that might break
grep -n "AGENT_OUTPUT\|location-specialist" .claude/commands/supervise.md
```

**Expected Outcome**:
- Phases 1-6 use exported environment variables (TOPIC_PATH, etc.)
- NO references to AGENT_OUTPUT parsing outside Phase 0
- artifact_paths structure used consistently

**If Incompatibilities Found**:
- Document each incompatibility
- Update affected phases to use exported variables
- Add to testing specification

### Step 6: Add Feature Flag for Safe Rollback

**Objective**: Enable quick rollback to agent-based approach if issues detected

**File**: `/home/benjamin/.config/.claude/commands/supervise.md`
**Location**: Before Phase 0 implementation (after STEP 2: Detect workflow scope)

**New Content (insert)**:
```markdown
STEP 2.5: Check location detection method (feature flag)

Determine whether to use utility functions or agent-based detection.

```bash
# Feature flag: USE_LOCATION_UTILITIES (default: true)
# Set to false to revert to location-specialist agent without code changes
USE_LOCATION_UTILITIES="${USE_LOCATION_UTILITIES:-true}"

if [ "$USE_LOCATION_UTILITIES" = "false" ]; then
  echo "⚠ Location utilities disabled via feature flag"
  echo "  Using location-specialist agent (legacy method)"
  echo ""
  # SKIP to legacy agent implementation (preserved below)
  USE_LEGACY_LOCATION_DETECTION=true
else
  echo "✓ Using optimized utility-based location detection"
  echo ""
  USE_LEGACY_LOCATION_DETECTION=false
fi
```
```

**Legacy Agent Code Preservation**:
```markdown
### Legacy Location Detection (preserved for rollback)

If USE_LOCATION_UTILITIES=false, this section executes instead of STEP 3-7.

```bash
if [ "$USE_LEGACY_LOCATION_DETECTION" = "true" ]; then
  # Original STEP 3-4 code (agent invocation + parsing)
  # ... [preserve original lines 397-443] ...

  # Skip to STEP 5 (original step numbers)
fi
```
```

**Rollback Procedure**:
```bash
# To rollback without code changes:
export USE_LOCATION_UTILITIES=false
/supervise "test workflow"

# To rollback permanently:
# Edit supervise.md and change default:
# USE_LOCATION_UTILITIES="${USE_LOCATION_UTILITIES:-false}"
```

**Verification**:
- [ ] Feature flag defaults to true (utilities enabled)
- [ ] Setting flag to false reverts to agent-based detection
- [ ] Legacy agent code preserved in separate section
- [ ] Both paths produce identical location context format

### Step 7: Final Integration and Validation

**Objective**: Ensure refactored Phase 0 integrates correctly with full /supervise workflow

**Validation Steps**:

1. **Syntax Validation**:
```bash
# Validate bash syntax in modified sections
bash -n /home/benjamin/.config/.claude/commands/supervise.md
# Note: May fail due to embedded YAML, but checks bash blocks
```

2. **Variable Export Verification**:
```bash
# Ensure all required variables are exported for downstream phases
grep -A 200 "^## Phase 0:" /home/benjamin/.config/.claude/commands/supervise.md | \
  grep "export" | grep -E "TOPIC_PATH|TOPIC_NUM|TOPIC_NAME|PROJECT_ROOT|SPECS_ROOT"
```

Expected exports:
```bash
export TOPIC_PATH TOPIC_NUM TOPIC_NAME PROJECT_ROOT SPECS_ROOT
```

3. **Path Format Validation**:
```bash
# Verify all paths are absolute (start with /)
grep -A 200 "^## Phase 0:" /home/benjamin/.config/.claude/commands/supervise.md | \
  grep -E "TOPIC_PATH|SPECS_ROOT|PROJECT_ROOT" | \
  grep -v "^\s*#" | \
  grep -E '=.*/' | head -10
```

All path assignments should use absolute paths (no relative paths like `./` or `../`).

4. **Error Handling Coverage**:
```bash
# Count error handling blocks in Phase 0
grep -A 200 "^## Phase 0:" /home/benjamin/.config/.claude/commands/supervise.md | \
  grep -c "ERROR:"
```

Expected: ≥8 error handlers (library loading, directory creation, validation, etc.).

**Validation Checklist**:
- [ ] All bash syntax valid in modified sections
- [ ] All required variables exported (TOPIC_PATH, TOPIC_NUM, TOPIC_NAME, PROJECT_ROOT, SPECS_ROOT)
- [ ] All paths are absolute (no relative paths)
- [ ] ≥8 error handlers present in Phase 0
- [ ] Feature flag mechanism functional
- [ ] Logging infrastructure in place
- [ ] Backup created and verified

## Testing Specification

### Unit Testing (Isolated Phase 0 Testing)

**Objective**: Test Phase 0 refactor in isolation before full workflow testing

**Test Script**: `.claude/tests/test_phase0_utilities.sh`

```bash
#!/usr/bin/env bash
# Test Phase 0 utility-based location detection

set -euo pipefail

TESTS_PASSED=0
TESTS_FAILED=0
TEST_OUTPUT_DIR="/tmp/supervise_phase0_tests"

# Setup test environment
setup_test_env() {
  rm -rf "$TEST_OUTPUT_DIR"
  mkdir -p "$TEST_OUTPUT_DIR"
  export CLAUDE_CONFIG="/home/benjamin/.config"
  export CLAUDE_PROJECT_DIR="$TEST_OUTPUT_DIR"
}

# Cleanup test environment
cleanup_test_env() {
  rm -rf "$TEST_OUTPUT_DIR"
}

# Test 1: Utility libraries load successfully
test_library_loading() {
  echo "Test 1: Library Loading"

  source "${CLAUDE_CONFIG}/.claude/lib/detect-project-dir.sh"
  source "${CLAUDE_CONFIG}/.claude/lib/topic-utils.sh"

  if [ $? -eq 0 ]; then
    echo "  ✓ Libraries loaded successfully"
    ((TESTS_PASSED++))
  else
    echo "  ✗ Library loading failed"
    ((TESTS_FAILED++))
  fi
}

# Test 2: Project root detection
test_project_root_detection() {
  echo "Test 2: Project Root Detection"

  if [ -n "$CLAUDE_PROJECT_DIR" ]; then
    echo "  ✓ CLAUDE_PROJECT_DIR set: $CLAUDE_PROJECT_DIR"
    ((TESTS_PASSED++))
  else
    echo "  ✗ CLAUDE_PROJECT_DIR not set"
    ((TESTS_FAILED++))
  fi
}

# Test 3: Specs directory creation
test_specs_directory_creation() {
  echo "Test 3: Specs Directory Creation"

  SPECS_ROOT="${CLAUDE_PROJECT_DIR}/.claude/specs"
  mkdir -p "$SPECS_ROOT"

  if [ -d "$SPECS_ROOT" ]; then
    echo "  ✓ Specs directory created: $SPECS_ROOT"
    ((TESTS_PASSED++))
  else
    echo "  ✗ Specs directory creation failed"
    ((TESTS_FAILED++))
  fi
}

# Test 4: Topic number calculation (empty directory)
test_topic_number_empty() {
  echo "Test 4: Topic Number Calculation (Empty)"

  SPECS_ROOT="${CLAUDE_PROJECT_DIR}/.claude/specs"
  TOPIC_NUM=$(get_next_topic_number "$SPECS_ROOT")

  if [ "$TOPIC_NUM" = "001" ]; then
    echo "  ✓ Correct topic number for empty directory: $TOPIC_NUM"
    ((TESTS_PASSED++))
  else
    echo "  ✗ Incorrect topic number: $TOPIC_NUM (expected 001)"
    ((TESTS_FAILED++))
  fi
}

# Test 5: Topic number calculation (with existing topics)
test_topic_number_increment() {
  echo "Test 5: Topic Number Calculation (Increment)"

  SPECS_ROOT="${CLAUDE_PROJECT_DIR}/.claude/specs"
  mkdir -p "${SPECS_ROOT}/005_existing_topic"

  TOPIC_NUM=$(get_next_topic_number "$SPECS_ROOT")

  if [ "$TOPIC_NUM" = "006" ]; then
    echo "  ✓ Correct topic number increment: $TOPIC_NUM"
    ((TESTS_PASSED++))
  else
    echo "  ✗ Incorrect topic number: $TOPIC_NUM (expected 006)"
    ((TESTS_FAILED++))
  fi
}

# Test 6: Topic name sanitization
test_topic_name_sanitization() {
  echo "Test 6: Topic Name Sanitization"

  WORKFLOW_DESC="Research: OAuth2 Authentication (Multi-Factor)"
  TOPIC_NAME=$(sanitize_topic_name "$WORKFLOW_DESC")

  if [[ "$TOPIC_NAME" =~ ^[a-z0-9_]+$ ]]; then
    echo "  ✓ Topic name sanitized correctly: $TOPIC_NAME"
    ((TESTS_PASSED++))
  else
    echo "  ✗ Invalid topic name format: $TOPIC_NAME"
    ((TESTS_FAILED++))
  fi
}

# Test 7: Directory structure creation
test_directory_structure_creation() {
  echo "Test 7: Directory Structure Creation"

  SPECS_ROOT="${CLAUDE_PROJECT_DIR}/.claude/specs"
  TOPIC_PATH="${SPECS_ROOT}/006_test_topic"

  if create_topic_structure "$TOPIC_PATH"; then
    # Verify all 6 subdirectories
    REQUIRED_SUBDIRS=("reports" "plans" "summaries" "debug" "scripts" "outputs")
    ALL_EXIST=true

    for subdir in "${REQUIRED_SUBDIRS[@]}"; do
      if [ ! -d "$TOPIC_PATH/$subdir" ]; then
        ALL_EXIST=false
        echo "  ✗ Missing subdirectory: $subdir"
      fi
    done

    if [ "$ALL_EXIST" = true ]; then
      echo "  ✓ All 6 subdirectories created successfully"
      ((TESTS_PASSED++))
    else
      ((TESTS_FAILED++))
    fi
  else
    echo "  ✗ Directory structure creation failed"
    ((TESTS_FAILED++))
  fi
}

# Test 8: Absolute path verification
test_absolute_paths() {
  echo "Test 8: Absolute Path Verification"

  SPECS_ROOT="${CLAUDE_PROJECT_DIR}/.claude/specs"
  TOPIC_PATH="${SPECS_ROOT}/006_test_topic"

  if [[ "$TOPIC_PATH" = /* ]]; then
    echo "  ✓ Topic path is absolute: $TOPIC_PATH"
    ((TESTS_PASSED++))
  else
    echo "  ✗ Topic path is relative: $TOPIC_PATH"
    ((TESTS_FAILED++))
  fi
}

# Run all tests
run_tests() {
  echo "================================"
  echo "Phase 0 Utilities Test Suite"
  echo "================================"
  echo ""

  setup_test_env

  test_library_loading
  test_project_root_detection
  test_specs_directory_creation
  test_topic_number_empty
  test_topic_number_increment
  test_topic_name_sanitization
  test_directory_structure_creation
  test_absolute_paths

  cleanup_test_env

  echo ""
  echo "================================"
  echo "Test Results"
  echo "================================"
  echo "  Passed: $TESTS_PASSED"
  echo "  Failed: $TESTS_FAILED"
  echo "  Total: $((TESTS_PASSED + TESTS_FAILED))"
  echo ""

  if [ $TESTS_FAILED -eq 0 ]; then
    echo "✓ All tests passed!"
    return 0
  else
    echo "✗ Some tests failed"
    return 1
  fi
}

# Execute tests
run_tests
```

**Expected Results**:
```
================================
Phase 0 Utilities Test Suite
================================

Test 1: Library Loading
  ✓ Libraries loaded successfully
Test 2: Project Root Detection
  ✓ CLAUDE_PROJECT_DIR set: /tmp/supervise_phase0_tests
Test 3: Specs Directory Creation
  ✓ Specs directory created: /tmp/supervise_phase0_tests/.claude/specs
Test 4: Topic Number Calculation (Empty)
  ✓ Correct topic number for empty directory: 001
Test 5: Topic Number Calculation (Increment)
  ✓ Correct topic number increment: 006
Test 6: Topic Name Sanitization
  ✓ Topic name sanitized correctly: research_oauth2_authentication_multifactor
Test 7: Directory Structure Creation
  ✓ All 6 subdirectories created successfully
Test 8: Absolute Path Verification
  ✓ Topic path is absolute: /tmp/supervise_phase0_tests/.claude/specs/006_test_topic

================================
Test Results
================================
  Passed: 8
  Failed: 0
  Total: 8

✓ All tests passed!
```

### Integration Testing (Phase 0 + Downstream Phases)

**Objective**: Verify Phase 0 refactor doesn't break Phases 1-6

**Test Cases**:

#### Test Case 1: Research-Only Workflow
```bash
/supervise "research authentication patterns"

# Expected behavior:
# - Phase 0 creates topic directory using utilities
# - Phase 1 (research) receives correct TOPIC_PATH
# - Research reports saved to correct location
# - Workflow completes successfully
```

**Verification**:
- [ ] Topic directory created: `.claude/specs/[NNN]_authentication_patterns/`
- [ ] All 6 subdirectories exist
- [ ] Phase 1 starts with correct TOPIC_PATH
- [ ] Research reports created in `[TOPIC]/reports/`

#### Test Case 2: Full Implementation Workflow
```bash
/supervise "implement user profile management feature"

# Expected behavior:
# - Phase 0 creates topic directory
# - Phases 1-2 (research, planning) use correct paths
# - Phase 3 (implementation) receives correct artifact paths
# - Phase 6 (documentation) saves summary to correct location
```

**Verification**:
- [ ] Topic directory: `.claude/specs/[NNN]_user_profile_management/`
- [ ] Research reports in correct location
- [ ] Implementation plan in correct location
- [ ] Summary created in correct location
- [ ] All phases reference same TOPIC_PATH

#### Test Case 3: Edge Case - Special Characters in Description
```bash
/supervise "Fix: OAuth2 Token Refresh (Race Condition) - URGENT!"

# Expected behavior:
# - Topic name sanitized correctly: "fix_oauth2_token_refresh_race_condition_urgent"
# - Directory created without issues
# - Workflow proceeds normally
```

**Verification**:
- [ ] Topic name contains only lowercase alphanumeric + underscores
- [ ] No special characters in directory name
- [ ] Directory created successfully
- [ ] Workflow completes without errors

#### Test Case 4: Concurrent Workflows (Race Condition Test)
```bash
# Terminal 1:
/supervise "research feature A" &

# Terminal 2 (immediately after):
/supervise "research feature B" &

# Wait for both to complete
wait

# Expected behavior:
# - Both workflows get unique topic numbers
# - No directory collisions
# - Both complete successfully
```

**Verification**:
- [ ] Two distinct topic directories created
- [ ] Sequential topic numbers (no duplicates)
- [ ] Both workflows complete successfully
- [ ] No race condition errors in logs

### Performance Testing

**Objective**: Validate 85-95% token reduction and 20x speedup claims

**Baseline Measurement** (before optimization):
```bash
# Measure agent-based Phase 0 (if rollback available)
export USE_LOCATION_UTILITIES=false
time /supervise "test workflow for baseline measurement"

# Record:
# - Execution time: ~25 seconds
# - Token usage: ~75,600 tokens (from API logs)
# - Cost: ~$0.68 (Sonnet 4.5)
```

**Optimized Measurement** (after optimization):
```bash
# Measure utility-based Phase 0
export USE_LOCATION_UTILITIES=true
time /supervise "test workflow for optimized measurement"

# Record:
# - Execution time: <1 second (target)
# - Token usage: 0 tokens (no AI invocation)
# - Cost: $0.00
```

**Performance Metrics**:
| Metric | Baseline | Optimized | Improvement |
|--------|----------|-----------|-------------|
| Execution Time | 25.2s | <1s | 20x+ speedup |
| Token Usage | 75,600 | 0 (utilities) | 100% reduction |
| AI Cost | $0.68 | $0.00 | 100% reduction |
| Phase 0 Tokens | 75,600 | 7,500-11,000 (total) | 85-95% reduction |

**Note**: Token count for optimized version includes bash command execution tokens (7.5-11k), but AI reasoning tokens are 0.

### Regression Testing

**Objective**: Ensure no existing functionality broken by refactor

**Test Matrix**:

| Test Case | Description | Pass Criteria |
|-----------|-------------|---------------|
| RT-1 | Simple research workflow | Topic created, Phase 1 completes |
| RT-2 | Complex implementation workflow | All phases 0-6 complete successfully |
| RT-3 | Debug-only workflow | Phase 0 + Phase 5 work correctly |
| RT-4 | Existing topic detection | Does not create duplicate topics |
| RT-5 | Multi-subdirectory verification | All 6 subdirs created every time |
| RT-6 | Absolute path propagation | All phases receive absolute paths |
| RT-7 | Feature flag rollback | USE_LOCATION_UTILITIES=false works |
| RT-8 | Logging infrastructure | Metrics logged to location-detection.log |

**Execution**:
```bash
# Run regression test suite
.claude/tests/test_supervise_regression.sh

# Expected output:
# RT-1: ✓ PASS
# RT-2: ✓ PASS
# RT-3: ✓ PASS
# RT-4: ✓ PASS
# RT-5: ✓ PASS
# RT-6: ✓ PASS
# RT-7: ✓ PASS
# RT-8: ✓ PASS
#
# Regression Tests: 8/8 PASSED
```

## Integration Verification Procedures

### Pre-Integration Checklist

Before considering Phase 2 complete, verify ALL of the following:

#### Code Quality Checks
- [ ] Bash syntax validated (no syntax errors in modified sections)
- [ ] ShellCheck compliance for new bash blocks
- [ ] All variable references use proper quoting ("$VAR" not $VAR)
- [ ] Error handling present for all external operations (mkdir, source, etc.)
- [ ] Feature flag mechanism functional (USE_LOCATION_UTILITIES)

#### Functional Verification
- [ ] Utility libraries (topic-utils.sh, detect-project-dir.sh) source successfully
- [ ] Project root detection works (CLAUDE_PROJECT_DIR set)
- [ ] Specs directory detection/creation works
- [ ] Topic number calculation correct (empty dir, existing topics, gaps)
- [ ] Topic name sanitization correct (special chars, length, case)
- [ ] Directory structure creation complete (all 6 subdirectories)
- [ ] Location context format matches expected YAML structure
- [ ] All required variables exported (TOPIC_PATH, TOPIC_NUM, TOPIC_NAME, etc.)

#### Integration Verification
- [ ] Phase 1 (research) receives correct TOPIC_PATH
- [ ] Phase 2 (planning) uses correct artifact_paths
- [ ] Phase 3 (implementation) accesses correct directories
- [ ] Phase 5 (debug) can write to debug/ subdirectory
- [ ] Phase 6 (documentation) can write summary to summaries/
- [ ] No downstream phases reference AGENT_OUTPUT (removed variable)

#### Performance Verification
- [ ] Phase 0 execution time <1 second (measured)
- [ ] No AI tokens consumed in Phase 0 (verified in logs)
- [ ] Metrics logged to location-detection.log
- [ ] Log format parseable by monitoring dashboard

#### Safety Verification
- [ ] Backup created (supervise.md.backup_phase2_TIMESTAMP)
- [ ] Feature flag enables rollback without code changes
- [ ] Legacy agent code preserved (if using hybrid approach)
- [ ] Error messages clear and actionable

### Post-Integration Validation

After Phase 2 refactor is deployed, monitor for 24-48 hours:

#### Monitoring Checklist (First 24 Hours)
- [ ] Run 10 diverse test workflows
- [ ] Verify all 10 create correct directory structures
- [ ] Check location-detection.log for any errors
- [ ] Compare token usage to baseline (should be 0 for Phase 0)
- [ ] Verify execution time <1s for all tests
- [ ] No user-reported issues with topic creation

#### Monitoring Checklist (24-48 Hours)
- [ ] Review production usage metrics (if applicable)
- [ ] Identify any edge cases that failed
- [ ] Update edge case handling if needed
- [ ] Gather user feedback on workflow performance
- [ ] Compare cost savings to projections

#### Success Criteria for Sign-Off
All of the following MUST be true to consider Phase 2 complete:

1. **Functionality**: 100% of test workflows create correct directory structures
2. **Performance**: Average Phase 0 execution time <1s (vs 25.2s baseline)
3. **Token Reduction**: 0 AI tokens used in Phase 0 (vs 75.6k baseline)
4. **Compatibility**: All downstream phases (1-6) work without modification
5. **Safety**: Rollback mechanism verified functional
6. **Monitoring**: Metrics logging working correctly
7. **Quality**: No regressions detected in regression test suite

## Rollback Procedures

### When to Rollback

Trigger immediate rollback if ANY of the following occur:

#### Critical Failures (Immediate Rollback)
- Incorrect topic directory location (wrong path)
- Missing subdirectories in created structure
- Downstream phases fail due to missing/incorrect paths
- Data loss or corruption in artifact directories
- Concurrent workflow race conditions causing duplicate topic numbers

#### Quality Failures (Rollback After Investigation)
- >5% failure rate in directory creation
- Execution time exceeds 2 seconds (vs <1s target)
- Special character handling breaks directory creation
- Edge cases cause workflow termination

### Rollback Method 1: Feature Flag (Instant Rollback)

**Use Case**: Quick rollback without code changes (production emergency)

**Procedure**:
```bash
# Step 1: Set feature flag to disable utilities
export USE_LOCATION_UTILITIES=false

# Step 2: Verify rollback worked
/supervise "test rollback workflow"

# Step 3: Check that agent-based detection is used
grep "location-specialist agent" .claude/data/logs/location-detection.log | tail -1

# Step 4: Update default in supervise.md (if permanent rollback)
# Edit line: USE_LOCATION_UTILITIES="${USE_LOCATION_UTILITIES:-false}"
```

**Verification**:
- [ ] Workflows use agent-based detection
- [ ] Directory creation works correctly
- [ ] Downstream phases function normally
- [ ] Log shows "agent" method instead of "utility-functions"

**Time to Rollback**: <1 minute (environment variable change)

### Rollback Method 2: File Restoration (Full Rollback)

**Use Case**: Complete revert to pre-Phase 2 state (if feature flag insufficient)

**Procedure**:
```bash
# Step 1: Identify backup file
ls -lt /home/benjamin/.config/.claude/commands/supervise.md.backup_phase2_* | head -1

# Step 2: Restore from backup
BACKUP_FILE=$(ls -t /home/benjamin/.config/.claude/commands/supervise.md.backup_phase2_* | head -1)
cp "$BACKUP_FILE" /home/benjamin/.config/.claude/commands/supervise.md

# Step 3: Verify restoration
diff "$BACKUP_FILE" /home/benjamin/.config/.claude/commands/supervise.md
# Should show no differences

# Step 4: Test restored version
/supervise "test restoration workflow"

# Step 5: Document rollback reason
echo "$(date): Rolled back Phase 2 refactor - Reason: [DOCUMENT REASON]" >> \
  /home/benjamin/.config/.claude/data/logs/rollback-history.log
```

**Verification**:
- [ ] supervise.md restored to pre-Phase 2 state
- [ ] Workflows use original agent-based detection
- [ ] All functionality works as before Phase 2
- [ ] Rollback reason documented

**Time to Rollback**: <5 minutes (file copy + verification)

### Rollback Method 3: Hybrid Approach (Partial Rollback)

**Use Case**: Keep utilities for simple cases, use agent for complex cases

**Procedure**:
```bash
# Step 1: Implement complexity heuristic (see Phase 5 of parent plan)
# Add to supervise.md after STEP 2:

needs_complex_location_analysis() {
  local workflow_desc="$1"

  # Complex workflows: multi-system refactors, migrations
  if echo "$workflow_desc" | grep -Eiq "migrate|refactor.*system|multi.*module"; then
    return 0  # true: use agent
  fi

  # Simple workflows: use utility functions
  return 1  # false: use utilities
}

# Step 2: Add conditional logic
if needs_complex_location_analysis "$WORKFLOW_DESCRIPTION"; then
  echo "Complex workflow detected - using location-specialist agent"
  # Execute legacy agent code
else
  echo "Simple workflow detected - using utility functions"
  # Execute utility-based code
fi
```

**Verification**:
- [ ] Simple workflows use utilities (90%+)
- [ ] Complex workflows use agent (5-10%)
- [ ] Both paths produce correct results
- [ ] Overall token reduction maintained (75-85%)

**Time to Implement**: 1-2 hours (requires code modification)

### Post-Rollback Actions

After any rollback:

1. **Root Cause Analysis**:
   - Document specific failure cases
   - Identify whether issue is with utilities, integration, or edge cases
   - Determine if fix is possible or architecture change needed

2. **Fix Development**:
   - Update topic-utils.sh to handle edge cases
   - Improve error handling in Phase 0 code
   - Add additional validation checks

3. **Regression Test Update**:
   - Add failed cases to regression test suite
   - Ensure fix prevents recurrence
   - Verify fix doesn't break other cases

4. **Redeployment Plan**:
   - Re-run complete test suite with fixes
   - Deploy with extra monitoring
   - Gradual rollout (canary deployment if possible)

## Error Handling and Edge Cases

### Error Handling Matrix

| Error Condition | Detection Method | Recovery Action | User Message |
|----------------|------------------|-----------------|--------------|
| topic-utils.sh not found | File existence check | Exit with error | "topic-utils.sh not found. Run Phase 1 first." |
| detect-project-dir.sh not found | File existence check | Exit with error | "detect-project-dir.sh missing. Critical dependency." |
| CLAUDE_PROJECT_DIR not set | Variable check | Exit with error | "Project root detection failed." |
| Specs directory creation fails | mkdir return code + directory check | Exit with error | "Cannot create specs directory. Check permissions." |
| Topic number calculation fails | Function return value check | Exit with error | "Topic number calculation failed." |
| Topic name sanitization fails | Function return value check | Exit with error | "Topic name sanitization failed." |
| Topic number format invalid | Regex validation | Exit with error | "Invalid topic number format: [value]" |
| Topic name format invalid | Regex validation | Exit with error | "Invalid topic name format: [value]" |
| Directory structure creation fails | Function return code | Exit with error | "Failed to create topic structure." |
| Subdirectory verification fails | Directory existence check | Exit with error | "Incomplete directory structure. Missing: [list]" |
| Concurrent topic number collision | Directory existence check (retry logic) | Retry with next number (max 10) | "Topic directory exists, retrying..." |
| Disk space exhausted | mkdir failure + df check | Exit with error | "Disk space exhausted. Cannot create directories." |
| Permission denied | mkdir failure | Exit with error | "Permission denied. Check directory permissions." |

### Edge Case Handling

#### Edge Case 1: Empty Workflow Description
```bash
WORKFLOW_DESCRIPTION=""

# Detection:
if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description required"
  exit 1
fi

# Already handled in STEP 1 - no changes needed
```

#### Edge Case 2: Very Long Workflow Description (>200 characters)
```bash
WORKFLOW_DESCRIPTION="Research and implement a comprehensive multi-tenant authentication and authorization system with role-based access control, OAuth2 integration, session management, password reset functionality, two-factor authentication, and comprehensive audit logging capabilities for enterprise deployment"

# Handling in sanitize_topic_name:
# - Truncates to 50 characters automatically
# - Topic name: "research_and_implement_a_comprehensive_multitena"

# Expected behavior: Works correctly, no error
```

#### Edge Case 3: Workflow Description with Special Characters
```bash
WORKFLOW_DESCRIPTION="Fix: OAuth2 Token Refresh (Race Condition) - URGENT! #127"

# Handling in sanitize_topic_name:
# - Removes special characters: #():!-
# - Converts spaces to underscores
# - Topic name: "fix_oauth2_token_refresh_race_condition_urgent_127"

# Expected behavior: Sanitized correctly
```

#### Edge Case 4: Non-Sequential Existing Topic Numbers
```bash
# Existing topics: 001, 003, 007, 012 (gaps in sequence)

# Handling in get_next_topic_number:
# - Finds max: 012
# - Returns: 013 (ignores gaps)

# Expected behavior: Sequential numbering continues from max
```

#### Edge Case 5: Concurrent /supervise Invocations
```bash
# Terminal 1: /supervise "feature A" (starts, calculates topic 013)
# Terminal 2: /supervise "feature B" (starts immediately, also calculates 013)

# Race condition risk:
# - Both try to create .claude/specs/013_feature/

# Current handling: First wins, second fails with "mkdir: cannot create directory"

# Improved handling (add to create_topic_structure):
for retry in {1..10}; do
  if mkdir "$TOPIC_PATH" 2>/dev/null; then
    break  # Successfully created
  else
    # Directory exists, increment topic number and retry
    TOPIC_NUM=$(printf "%03d" $((10#$TOPIC_NUM + 1)))
    TOPIC_PATH="${SPECS_ROOT}/${TOPIC_NUM}_${TOPIC_NAME}"
  fi
done
```

**Recommendation**: Add retry logic to Phase 1 (topic-utils.sh) in create_topic_structure function.

#### Edge Case 6: Specs Directory Does Not Exist (First Use)
```bash
# Project has no .claude/specs or specs directory

# Handling in STEP 5:
# - Checks for existing directories
# - Creates .claude/specs if neither exists
# - Verifies creation before proceeding

# Expected behavior: Creates directory automatically
```

#### Edge Case 7: Relative Path in CLAUDE_PROJECT_DIR
```bash
# User set: export CLAUDE_PROJECT_DIR="./my-project"

# Risk: Relative paths break when subagents change directories

# Detection:
if [[ ! "$PROJECT_ROOT" = /* ]]; then
  echo "WARNING: CLAUDE_PROJECT_DIR is relative: $PROJECT_ROOT"
  echo "Converting to absolute path..."
  PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
  export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"
fi

# Mitigation: Convert to absolute path automatically
```

**Recommendation**: Add absolute path verification after project root detection.

## Performance Validation Criteria

### Token Usage Targets

| Metric | Baseline | Target | Actual | Status |
|--------|----------|--------|--------|--------|
| Phase 0 AI Tokens | 75,600 | 0 | [TBD] | Pending |
| Phase 0 Total Tokens | 75,600 | 7,500-11,000 | [TBD] | Pending |
| Token Reduction | 0% | 85-95% | [TBD] | Pending |
| Context Window Usage | 38% | <6% | [TBD] | Pending |

**Measurement Method**:
```bash
# Before (baseline):
grep "Phase 0" .claude/data/logs/token-usage.log | tail -1

# After (optimized):
grep "Phase 0" .claude/data/logs/token-usage.log | tail -1

# Calculate reduction:
# Reduction % = ((Baseline - Optimized) / Baseline) * 100
```

### Execution Time Targets

| Metric | Baseline | Target | Actual | Status |
|--------|----------|--------|--------|--------|
| Phase 0 Duration | 25.2s | <1s | [TBD] | Pending |
| Speedup Factor | 1x | 20x+ | [TBD] | Pending |

**Measurement Method**:
```bash
# Instrument Phase 0 with timing:
PHASE_0_START=$(date +%s%N)
# ... Phase 0 code ...
PHASE_0_END=$(date +%s%N)
PHASE_0_DURATION=$((($PHASE_0_END - $PHASE_0_START) / 1000000))  # milliseconds

echo "Phase 0 Duration: ${PHASE_0_DURATION}ms"
```

### Cost Targets

| Metric | Baseline | Target | Actual | Status |
|--------|----------|--------|--------|--------|
| Cost per Invocation | $0.68 | $0.00 | [TBD] | Pending |
| Monthly Cost (100 invocations) | $68.00 | $0.00 | [TBD] | Pending |
| Annual Savings | $0 | $816 | [TBD] | Pending |

**Measurement Method**:
```bash
# Calculate cost from token usage:
# Sonnet 4.5: $3/MTok input, $15/MTok output
# Baseline: 75.6k tokens * $3/MTok = $0.227
# (Note: Original calculation may include multiple API calls)

# Optimized: 0 AI tokens = $0.00
```

### Success Criteria Summary

Phase 2 is considered successful ONLY if ALL of the following are met:

#### Functional Success Criteria (100% Required)
- [ ] All 8 unit tests pass (test_phase0_utilities.sh)
- [ ] All 4 integration tests pass (research, implementation, edge cases, concurrent)
- [ ] All 8 regression tests pass (RT-1 through RT-8)
- [ ] 100% directory creation success rate (6 subdirectories every time)
- [ ] 100% downstream phase compatibility (no breaking changes)

#### Performance Success Criteria (90% Required)
- [ ] ≥85% token reduction (target: 85-95%)
- [ ] ≥15x speedup (target: 20x+)
- [ ] <1.5s average Phase 0 execution time (target: <1s)
- [ ] 0 AI tokens consumed in Phase 0

#### Quality Success Criteria (95% Required)
- [ ] ≥95% test pass rate across all test categories
- [ ] <5% false positive rate (utilities used when agent needed)
- [ ] <2% edge case failure rate
- [ ] 100% absolute path compliance

#### Safety Success Criteria (100% Required)
- [ ] Rollback mechanism verified functional (feature flag test)
- [ ] Backup created and verified restorable
- [ ] No data loss or corruption in any test
- [ ] Error messages clear and actionable

## Documentation Updates

### Files to Update

#### 1. supervise.md (Primary Changes)
**File**: `/home/benjamin/.config/.claude/commands/supervise.md`

**Changes**:
- Phase 0 header (lines 343-350)
- STEP 3-7 implementation (lines 397-520)
- Feature flag mechanism (new, after STEP 2)
- Logging instrumentation (new, after STEP 7)

**Total Lines Changed**: ~130 lines (47 removed, 120 added, net +73)

#### 2. location-specialist.md (Documentation Update)
**File**: `/home/benjamin/.config/.claude/agents/location-specialist.md`

**Changes** (documentation only, not in this phase):
- Add note about utility-based optimization
- Update frontmatter with model: haiku-4.5 (Phase 0 of parent plan)
- Add reference to hybrid approach (Phase 5 of parent plan)

**Note**: This file is NOT modified in Phase 2 (only in Phase 0 and Phase 5 of parent plan).

#### 3. Phase 2 Completion Documentation
**File**: `/home/benjamin/.config/.claude/specs/076_orchestrate_supervise_comparison/plans/002_optimize_supervise_location_detection.md`

**Update**: Mark Phase 2 checkbox as complete
```markdown
### Phase 2: Refactor /supervise Phase 0 to Use Utilities

**Status**: ~~Pending~~ Completed
**Completion Date**: [DATE]

#### Completion Summary
- Token reduction achieved: [X%]
- Speedup achieved: [X]x
- Test pass rate: [X%]
- Issues encountered: [LIST]
- Rollback events: [COUNT]
```

#### 4. Monitoring Documentation
**File**: `/home/benjamin/.config/.claude/docs/guides/monitoring-location-detection.md` (new)

**Content**:
```markdown
# Location Detection Monitoring Guide

## Overview
This guide explains how to monitor the location detection optimization implemented in Phase 2 of the supervise refactor.

## Log Files

### location-detection.log
**Path**: `.claude/data/logs/location-detection.log`

**Format**:
```
YYYY-MM-DD HH:MM:SS | command | method | topic | tokens | time | path
```

**Example**:
```
2025-10-23 14:32:15 | /supervise | utility-functions | 082_auth_patterns | ~0 (baseline: 75600, savings: 100%) | 0.742s | /home/user/.claude/specs/082_auth_patterns
```

## Monitoring Commands

### View Recent Location Detections
```bash
tail -10 .claude/data/logs/location-detection.log
```

### Calculate Average Token Savings
```bash
awk -F'|' '/utility-functions/ {count++} END {print count " workflows used utilities"}' \
  .claude/data/logs/location-detection.log
```

### Calculate Average Execution Time
```bash
awk -F'|' '/utility-functions/ {gsub(/[^0-9.]/, "", $6); sum+=$6; count++} END {print sum/count "s average"}' \
  .claude/data/logs/location-detection.log
```

## Dashboard

Run the monitoring dashboard:
```bash
.claude/scripts/location_detection_dashboard.sh
```

See Phase 3 of optimization plan for dashboard implementation.
```

## Appendices

### Appendix A: Complete Code Listing (New STEP 3-7)

**Complete replacement content for supervise.md lines 397-520**:

```markdown
STEP 3: Source utility libraries

Load project detection and topic management utilities.

```bash
# Source utility libraries (absolute paths from CLAUDE_CONFIG)
CLAUDE_LIB_DIR="${CLAUDE_CONFIG}/.claude/lib"

if [ ! -f "${CLAUDE_LIB_DIR}/detect-project-dir.sh" ]; then
  echo "❌ ERROR: detect-project-dir.sh not found at ${CLAUDE_LIB_DIR}"
  echo "   This is a critical dependency for location detection."
  exit 1
fi

if [ ! -f "${CLAUDE_LIB_DIR}/topic-utils.sh" ]; then
  echo "❌ ERROR: topic-utils.sh not found at ${CLAUDE_LIB_DIR}"
  echo "   This utility library is required (created in Phase 1)."
  echo "   Run Phase 1 of optimization plan before Phase 2."
  exit 1
fi

# Source libraries
source "${CLAUDE_LIB_DIR}/detect-project-dir.sh"
source "${CLAUDE_LIB_DIR}/topic-utils.sh"

echo "✓ Utility libraries loaded successfully"
```

STEP 4: Detect project root and specs directory

Determine the project root using existing detection utilities and locate the specs directory.

```bash
# Project root is already set by detect-project-dir.sh (sourced above)
PROJECT_ROOT="${CLAUDE_PROJECT_DIR}"

if [ -z "$PROJECT_ROOT" ]; then
  echo "❌ ERROR: CLAUDE_PROJECT_DIR not set"
  echo "   detect-project-dir.sh should have exported this variable."
  exit 1
fi

# Ensure absolute path (convert relative paths)
if [[ ! "$PROJECT_ROOT" = /* ]]; then
  echo "⚠ WARNING: CLAUDE_PROJECT_DIR is relative: $PROJECT_ROOT"
  echo "  Converting to absolute path..."
  PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
  export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"
fi

echo "Project Root: $PROJECT_ROOT"

# Determine specs directory (prefer .claude/specs, fallback to specs)
if [ -d "${PROJECT_ROOT}/.claude/specs" ]; then
  SPECS_ROOT="${PROJECT_ROOT}/.claude/specs"
  echo "Using existing specs directory: $SPECS_ROOT"
elif [ -d "${PROJECT_ROOT}/specs" ]; then
  SPECS_ROOT="${PROJECT_ROOT}/specs"
  echo "Using existing specs directory: $SPECS_ROOT"
else
  # Create .claude/specs as default
  SPECS_ROOT="${PROJECT_ROOT}/.claude/specs"
  echo "Creating new specs directory: $SPECS_ROOT"
  mkdir -p "$SPECS_ROOT"

  if [ ! -d "$SPECS_ROOT" ]; then
    echo "❌ ERROR: Failed to create specs directory at $SPECS_ROOT"
    exit 1
  fi

  echo "✓ Specs directory created successfully"
fi

echo ""
```

STEP 5: Calculate topic metadata using utilities

Use deterministic bash functions to calculate topic number and sanitize topic name.

```bash
# Calculate next topic number (deterministic: find max, increment)
TOPIC_NUM=$(get_next_topic_number "$SPECS_ROOT")

if [ -z "$TOPIC_NUM" ]; then
  echo "❌ ERROR: get_next_topic_number failed to return a topic number"
  exit 1
fi

# Validate topic number format (must be 3 digits)
if ! [[ "$TOPIC_NUM" =~ ^[0-9]{3}$ ]]; then
  echo "❌ ERROR: Invalid topic number format: '$TOPIC_NUM'"
  echo "   Expected: 3-digit zero-padded number (e.g., 001, 042, 127)"
  exit 1
fi

echo "Next Topic Number: $TOPIC_NUM"

# Sanitize workflow description to topic name
TOPIC_NAME=$(sanitize_topic_name "$WORKFLOW_DESCRIPTION")

if [ -z "$TOPIC_NAME" ]; then
  echo "❌ ERROR: sanitize_topic_name failed to generate a valid topic name"
  echo "   Workflow Description: $WORKFLOW_DESCRIPTION"
  exit 1
fi

# Validate topic name (must be lowercase alphanumeric + underscores)
if ! [[ "$TOPIC_NAME" =~ ^[a-z0-9_]+$ ]]; then
  echo "❌ ERROR: Invalid topic name format: '$TOPIC_NAME'"
  echo "   Expected: lowercase alphanumeric with underscores only"
  exit 1
fi

echo "Topic Name: $TOPIC_NAME"

# Construct topic directory path
TOPIC_PATH="${SPECS_ROOT}/${TOPIC_NUM}_${TOPIC_NAME}"

echo "Topic Directory: $TOPIC_PATH"
echo ""
```

STEP 6: Create topic directory structure

Create the complete directory structure using the utility function with verification.

```bash
# Create directory structure (6 subdirectories: reports, plans, summaries, debug, scripts, outputs)
if ! create_topic_structure "$TOPIC_PATH"; then
  echo "❌ ERROR: create_topic_structure failed for $TOPIC_PATH"
  echo "   Check directory permissions and disk space."
  exit 1
fi

# Explicit verification of all 6 required subdirectories
REQUIRED_SUBDIRS=("reports" "plans" "summaries" "debug" "scripts" "outputs")
MISSING_SUBDIRS=()

for subdir in "${REQUIRED_SUBDIRS[@]}"; do
  if [ ! -d "$TOPIC_PATH/$subdir" ]; then
    MISSING_SUBDIRS+=("$subdir")
  fi
done

if [ ${#MISSING_SUBDIRS[@]} -gt 0 ]; then
  echo "❌ ERROR: Incomplete directory structure at $TOPIC_PATH"
  echo "   Missing subdirectories: ${MISSING_SUBDIRS[*]}"
  exit 1
fi

echo "✓ Topic directory structure created successfully"
echo "  Base: $TOPIC_PATH"
echo "  Subdirectories: ${REQUIRED_SUBDIRS[*]}"
echo ""
```

STEP 7: Generate location context for downstream phases

Construct the location context object with absolute paths (maintains compatibility with existing Phase 1-6 code).

```bash
# Generate location context (YAML format for downstream phase compatibility)
# CRITICAL: All paths MUST be absolute for subagent compatibility
LOCATION_CONTEXT=$(cat <<EOF
topic_number: $TOPIC_NUM
topic_name: $TOPIC_NAME
topic_path: $TOPIC_PATH
artifact_paths:
  reports: $TOPIC_PATH/reports
  plans: $TOPIC_PATH/plans
  summaries: $TOPIC_PATH/summaries
  debug: $TOPIC_PATH/debug
  scripts: $TOPIC_PATH/scripts
  outputs: $TOPIC_PATH/outputs
project_root: $PROJECT_ROOT
specs_root: $SPECS_ROOT
EOF
)

# Export for downstream phases
export TOPIC_PATH TOPIC_NUM TOPIC_NAME PROJECT_ROOT SPECS_ROOT

echo "LOCATION_DETECTED: $TOPIC_PATH"
echo ""
echo "Location Context:"
echo "$LOCATION_CONTEXT"
echo ""
```

STEP 8: Log location detection metrics

Record location detection performance for monitoring dashboard.

```bash
# Log location detection metrics (for optimization tracking)
LOG_FILE="${CLAUDE_CONFIG}/.claude/data/logs/location-detection.log"
LOG_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Calculate token count (estimate: 7.5k-11k for bash utilities)
# Note: Actual token count is 0 for utilities (no AI invocation)
# We log estimated savings vs baseline (75.6k agent tokens)
TOKEN_ESTIMATE="~0 (utility functions)"
BASELINE_TOKENS="75600"
TOKEN_SAVINGS="100%"

# Calculate execution time (track Phase 0 duration)
PHASE_0_END_TIME=$(date +%s%N)
PHASE_0_DURATION_NS=$((PHASE_0_END_TIME - PHASE_0_START_TIME))
PHASE_0_DURATION_SEC=$(echo "scale=3; $PHASE_0_DURATION_NS / 1000000000" | bc)

# Log entry format: timestamp | command | method | topic | tokens | time | path
LOG_ENTRY="${LOG_TIMESTAMP} | /supervise | utility-functions | ${TOPIC_NUM}_${TOPIC_NAME} | ${TOKEN_ESTIMATE} (baseline: ${BASELINE_TOKENS}, savings: ${TOKEN_SAVINGS}) | ${PHASE_0_DURATION_SEC}s | ${TOPIC_PATH}"

echo "$LOG_ENTRY" >> "$LOG_FILE"

echo "✓ Metrics logged to location-detection.log"
echo ""
```

STEP 9: Pre-calculate ALL artifact paths

```bash
# Research phase paths (calculate for max 4 topics)
REPORT_PATHS=()
for i in 1 2 3 4; do
  REPORT_PATHS+=("${TOPIC_PATH}/reports/$(printf '%03d' $i)_topic${i}.md")
done
OVERVIEW_PATH="${TOPIC_PATH}/reports/${TOPIC_NUM}_overview.md"

# Planning phase paths
PLAN_PATH="${TOPIC_PATH}/plans/001_${TOPIC_NAME}_plan.md"

# Implementation phase paths
IMPL_ARTIFACTS="${TOPIC_PATH}/artifacts/"

# Debug phase paths
DEBUG_REPORT="${TOPIC_PATH}/debug/001_debug_analysis.md"

# Documentation phase paths
SUMMARY_PATH="${TOPIC_PATH}/summaries/${TOPIC_NUM}_${TOPIC_NAME}_summary.md"

# Export all paths for use in subsequent phases
export OVERVIEW_PATH PLAN_PATH
export IMPL_ARTIFACTS DEBUG_REPORT SUMMARY_PATH

echo "Pre-calculated Artifact Paths:"
echo "  Research Reports: ${#REPORT_PATHS[@]} paths"
echo "  Overview: $OVERVIEW_PATH"
echo "  Plan: $PLAN_PATH"
echo "  Implementation: $IMPL_ARTIFACTS"
echo "  Debug: $DEBUG_REPORT"
echo "  Summary: $SUMMARY_PATH"
echo ""
```

STEP 10: Initialize tracking arrays

```bash
# Track successful report paths for Phase 1
SUCCESSFUL_REPORT_PATHS=()
SUCCESSFUL_REPORT_COUNT=0

# Track phase status
TESTS_PASSING="unknown"
IMPLEMENTATION_OCCURRED="false"

echo "Phase 0 Complete: Ready for Phase 1 (Research)"
echo ""
```
```

### Appendix B: Utility Function Reference

**File**: `.claude/lib/topic-utils.sh` (created in Phase 1)

**Required Functions**:

#### get_next_topic_number()
```bash
# Usage: get_next_topic_number <specs_root>
# Returns: 3-digit zero-padded topic number (e.g., "001", "042")
# Example: TOPIC_NUM=$(get_next_topic_number "/path/to/specs")
```

#### sanitize_topic_name()
```bash
# Usage: sanitize_topic_name <raw_description>
# Returns: Sanitized lowercase alphanumeric + underscore topic name
# Example: TOPIC_NAME=$(sanitize_topic_name "Research: OAuth2 Auth")
```

#### create_topic_structure()
```bash
# Usage: create_topic_structure <topic_path>
# Returns: 0 on success, 1 on failure
# Creates: 6 subdirectories (reports, plans, summaries, debug, scripts, outputs)
# Example: create_topic_structure "/path/to/specs/042_feature" || exit 1
```

### Appendix C: Testing Checklist

**Use this checklist to verify Phase 2 completion**:

#### Pre-Implementation Checks
- [ ] Phase 1 completed (topic-utils.sh exists and tested)
- [ ] Backup created (supervise.md.backup_phase2_TIMESTAMP)
- [ ] Test environment prepared (/tmp/supervise_phase2_tests/)
- [ ] Utility libraries validated (ShellCheck passed)

#### Implementation Checks
- [ ] Phase 0 header updated (lines 343-350)
- [ ] STEP 3-7 replaced (lines 397-520)
- [ ] Feature flag added (USE_LOCATION_UTILITIES)
- [ ] Logging instrumentation added (STEP 8)
- [ ] Timing instrumentation added (PHASE_0_START_TIME)

#### Unit Testing Checks
- [ ] test_phase0_utilities.sh created
- [ ] All 8 unit tests pass
- [ ] Utility functions work in isolation
- [ ] Edge cases handled correctly

#### Integration Testing Checks
- [ ] Research-only workflow tested
- [ ] Full implementation workflow tested
- [ ] Special characters edge case tested
- [ ] Concurrent workflows tested (race condition)

#### Performance Testing Checks
- [ ] Phase 0 execution time measured (<1s)
- [ ] Token usage verified (0 AI tokens)
- [ ] Baseline comparison documented
- [ ] Performance targets met (≥85% reduction, ≥15x speedup)

#### Regression Testing Checks
- [ ] All 8 regression tests pass
- [ ] No downstream phase breakage
- [ ] Absolute paths verified
- [ ] Location context format unchanged

#### Safety Testing Checks
- [ ] Feature flag rollback tested
- [ ] File restoration rollback tested
- [ ] Error messages verified clear
- [ ] Rollback procedures documented

#### Documentation Checks
- [ ] supervise.md updated
- [ ] Phase 2 completion documented in parent plan
- [ ] Monitoring guide created
- [ ] Rollback procedures documented

#### Sign-Off Criteria
- [ ] All functional tests pass (100%)
- [ ] Performance targets met (≥90%)
- [ ] Quality metrics achieved (≥95%)
- [ ] Safety verified (100%)
- [ ] Documentation complete
- [ ] Ready for production deployment

---

## Completion Summary

**This specification provides**:
- 300+ lines of detailed implementation guidance
- Complete code listings for all modified sections
- Comprehensive testing strategy (unit, integration, performance, regression)
- Error handling for 13+ edge cases
- 3 rollback methods with step-by-step procedures
- Performance validation criteria with measurable targets
- Integration verification procedures
- Monitoring infrastructure design

**Next Steps After Phase 2 Completion**:
1. Execute Phase 3 (Monitoring Infrastructure) of parent plan
2. Execute Phase 4 (Comprehensive Testing) of parent plan
3. Consider Phase 5 (Hybrid Approach) if edge cases identified
4. Plan Phase 6 (System-Wide Standardization) after production validation

**Estimated Effort**: 2-3 hours (as specified in parent plan)
**Risk Level**: Medium (mitigated by comprehensive testing and rollback mechanisms)
**Priority**: HIGH (enables 85-95% token reduction for /supervise command)
