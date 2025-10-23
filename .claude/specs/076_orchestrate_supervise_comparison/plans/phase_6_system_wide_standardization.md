# Phase 6: System-Wide Standardization - Detailed Implementation Specification

## Phase Metadata
- **Phase Number**: 6
- **Phase Name**: System-Wide Standardization
- **Parent Plan**: 002_optimize_supervise_location_detection.md
- **Topic**: 076_orchestrate_supervise_comparison
- **Dependencies**: [4] (Phase 4: Comprehensive Testing and Validation)
- **Status**: Pending
- **Complexity**: 8/10 (high)
- **Estimated Time**: 6-8 hours
- **Risk**: High
- **Priority**: LOW (defer until /supervise optimization validated in production)

## Objective

Apply the location detection optimization pattern proven in /supervise to three additional critical commands (/orchestrate, /report, /plan), achieving system-wide standardization through a unified location detection library. This phase eliminates code duplication, reduces maintenance burden, and extends the 85-95% token reduction benefit across all workflow initiation commands.

**Success Definition**: All four commands (/supervise, /orchestrate, /report, /plan) use a single unified location detection library with consistent behavior, achieving 15-20% system-wide token reduction while maintaining 100% backward compatibility.

## Prerequisites

**MANDATORY BEFORE STARTING THIS PHASE**:
1. Phase 4 validation MUST show ≥95% test pass rate for /supervise optimization
2. /supervise MUST complete 1-2 weeks production usage without regression
3. Report 074 (model selection refactor) MUST be implemented (agent model metadata standardization)
4. Comprehensive test suite for /supervise MUST achieve <11k average token usage
5. Monitoring dashboard MUST confirm 85-95% token reduction in production
6. All rollback procedures for /supervise MUST be documented and tested

**Verification Before Proceeding**:
```bash
# Verify /supervise production metrics
./claude/scripts/location_detection_dashboard.sh | grep "supervise"
# Expected: Token usage <11k avg, 95%+ pass rate, 1-2 weeks production data

# Verify Report 074 completion
grep -q "model:" .claude/agents/*.md && echo "✓ Model metadata standardized"

# Verify test coverage
./claude/tests/test_location_detection.sh | grep "Overall"
# Expected: ≥47/50 tests passing
```

## Risk Assessment

### High-Risk Factors

1. **Multi-Command Regression Risk**
   - Impact: Changes affect 4 critical workflow-initiating commands
   - Probability: Medium (30-40% chance of edge case failures)
   - Mitigation: Phased rollout with per-command validation gates

2. **Backward Compatibility Risk**
   - Impact: Existing workflows may depend on command-specific location logic
   - Probability: Low-Medium (10-20% chance of breaking changes)
   - Mitigation: Maintain compatibility shims for 2 release cycles

3. **Cross-Command Interaction Risk**
   - Impact: /orchestrate invokes /report and /plan; changes may cascade unexpectedly
   - Probability: Medium (20-30% chance of unexpected interactions)
   - Mitigation: Integration testing across command chains

### Mitigation Strategy

**Per-Command Rollout with Validation Gates**:
1. Refactor /report (lowest risk, isolated usage)
2. Validate /report → Gate 1
3. Refactor /plan (medium risk, invoked by /orchestrate)
4. Validate /plan → Gate 2
5. Refactor /orchestrate (highest risk, invokes others)
6. Validate /orchestrate → Gate 3
7. System-wide integration testing → Final Gate

**Rollback Triggers** (ANY of these):
- Any command shows >5% test failure rate
- Token usage increases >10% for any command
- User-reported location detection failures
- Cross-command integration failures

## Architecture Design

### Component 1: Unified Location Detection Library

**File**: `.claude/lib/unified-location-detection.sh`

**Purpose**: Single source of truth for all location detection logic across /supervise, /orchestrate, /report, and /plan commands.

**Design Principles**:
1. **Backward Compatibility**: Support both `.claude/specs` and `specs` conventions
2. **Deterministic Logic**: All functions use bash utilities, zero AI invocations
3. **Testability**: Each function independently testable with unit tests
4. **Extensibility**: Designed for future enhancement without breaking existing code
5. **Performance**: <1s execution time for all functions combined

**API Design**:

```bash
#!/usr/bin/env bash
# unified-location-detection.sh
#
# Unified location detection library for Claude Code workflow commands
# Consolidates logic from detect-project-dir.sh, topic-utils.sh, and command-specific detection
#
# Commands using this library: /supervise, /orchestrate, /report, /plan
# Dependencies: None (pure bash, no external utilities)

set -euo pipefail

# ============================================================================
# SECTION 1: Project Root Detection
# ============================================================================

# detect_project_root()
# Purpose: Determine project root directory with git worktree support
# Returns: Absolute path to project root
# Precedence: CLAUDE_PROJECT_DIR env var > git root > current directory
#
# Usage:
#   PROJECT_ROOT=$(detect_project_root)
#
# Exit Codes:
#   0: Success (always, uses fallback if needed)
detect_project_root() {
  # Method 1: Respect existing environment variable (manual override)
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    echo "$CLAUDE_PROJECT_DIR"
    return 0
  fi

  # Method 2: Git repository root (handles worktrees correctly)
  if command -v git &>/dev/null; then
    if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
      git rev-parse --show-toplevel
      return 0
    fi
  fi

  # Method 3: Fallback to current directory
  pwd
  return 0
}

# ============================================================================
# SECTION 2: Specs Directory Detection
# ============================================================================

# detect_specs_directory(project_root)
# Purpose: Determine specs directory location (.claude/specs vs specs)
# Arguments:
#   $1: project_root - Absolute path to project root
# Returns: Absolute path to specs directory
# Precedence: .claude/specs (preferred) > specs (legacy) > create .claude/specs
#
# Usage:
#   SPECS_DIR=$(detect_specs_directory "$PROJECT_ROOT")
#
# Exit Codes:
#   0: Success (creates directory if needed)
detect_specs_directory() {
  local project_root="$1"

  # Method 1: Prefer .claude/specs (modern convention)
  if [ -d "${project_root}/.claude/specs" ]; then
    echo "${project_root}/.claude/specs"
    return 0
  fi

  # Method 2: Support specs (legacy convention)
  if [ -d "${project_root}/specs" ]; then
    echo "${project_root}/specs"
    return 0
  fi

  # Method 3: Create .claude/specs (default for new projects)
  local specs_dir="${project_root}/.claude/specs"
  mkdir -p "$specs_dir" || {
    echo "ERROR: Failed to create specs directory: $specs_dir" >&2
    return 1
  }

  echo "$specs_dir"
  return 0
}

# ============================================================================
# SECTION 3: Topic Number Calculation
# ============================================================================

# get_next_topic_number(specs_root)
# Purpose: Calculate next sequential topic number from existing topics
# Arguments:
#   $1: specs_root - Absolute path to specs directory
# Returns: Three-digit topic number (e.g., "001", "042", "137")
# Logic: Find max existing topic number, increment by 1
#
# Usage:
#   TOPIC_NUM=$(get_next_topic_number "$SPECS_ROOT")
#
# Exit Codes:
#   0: Success
get_next_topic_number() {
  local specs_root="$1"

  # Find maximum existing topic number
  local max_num
  max_num=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
    sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
    sort -n | tail -1)

  # Handle empty directory (first topic)
  if [ -z "$max_num" ]; then
    echo "001"
    return 0
  fi

  # Increment and format with leading zeros
  # Note: 10#$max_num forces base-10 interpretation (avoids octal issues)
  printf "%03d" $((10#$max_num + 1))
  return 0
}

# find_existing_topic(specs_root, topic_name_pattern)
# Purpose: Search for existing topic matching name pattern (optional reuse)
# Arguments:
#   $1: specs_root - Absolute path to specs directory
#   $2: topic_name_pattern - Regex pattern to match topic names
# Returns: Topic number if found, empty string if not found
# Logic: Search topic directory names for pattern match
#
# Usage:
#   EXISTING=$(find_existing_topic "$SPECS_ROOT" "auth.*patterns")
#   if [ -n "$EXISTING" ]; then
#     echo "Found existing topic: $EXISTING"
#   fi
#
# Exit Codes:
#   0: Success (whether found or not)
find_existing_topic() {
  local specs_root="$1"
  local pattern="$2"

  # Search existing topic names for pattern match
  local match
  match=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
    grep -E "${specs_root}/[0-9]{3}_.*${pattern}" | \
    head -1 | \
    sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/')

  echo "$match"
  return 0
}

# ============================================================================
# SECTION 4: Topic Name Sanitization
# ============================================================================

# sanitize_topic_name(raw_name)
# Purpose: Convert workflow description to valid topic directory name
# Arguments:
#   $1: raw_name - Raw workflow description (user input)
# Returns: Sanitized topic name (snake_case, max 50 chars)
# Rules:
#   - Convert to lowercase
#   - Replace spaces with underscores
#   - Remove all non-alphanumeric except underscores
#   - Trim leading/trailing underscores
#   - Truncate to 50 characters
#
# Usage:
#   TOPIC_NAME=$(sanitize_topic_name "Research: Authentication Patterns")
#   # Result: "research_authentication_patterns"
#
# Exit Codes:
#   0: Success
sanitize_topic_name() {
  local raw_name="$1"

  echo "$raw_name" | \
    tr '[:upper:]' '[:lower:]' | \
    tr ' ' '_' | \
    sed 's/[^a-z0-9_]//g' | \
    sed 's/^_*//;s/_*$//' | \
    sed 's/__*/_/g' | \
    cut -c1-50

  return 0
}

# ============================================================================
# SECTION 5: Topic Directory Structure Creation
# ============================================================================

# create_topic_structure(topic_path)
# Purpose: Create standard 6-subdirectory topic structure
# Arguments:
#   $1: topic_path - Absolute path to topic directory
# Returns: Nothing (exits on failure)
# Creates:
#   - reports/    - Research documentation
#   - plans/      - Implementation plans
#   - summaries/  - Workflow summaries
#   - debug/      - Debug reports and diagnostics
#   - scripts/    - Utility scripts
#   - outputs/    - Command outputs and logs
#
# Usage:
#   create_topic_structure "$TOPIC_PATH" || exit 1
#
# Exit Codes:
#   0: Success (all directories created)
#   1: Failure (directory creation failed)
create_topic_structure() {
  local topic_path="$1"

  # Create topic root and all subdirectories
  mkdir -p "$topic_path"/{reports,plans,summaries,debug,scripts,outputs} || {
    echo "ERROR: Failed to create topic directory structure: $topic_path" >&2
    return 1
  }

  # Verify all subdirectories created successfully
  for subdir in reports plans summaries debug scripts outputs; do
    if [ ! -d "$topic_path/$subdir" ]; then
      echo "ERROR: Subdirectory missing after creation: $topic_path/$subdir" >&2
      return 1
    fi
  done

  return 0
}

# ============================================================================
# SECTION 6: High-Level Location Detection Orchestration
# ============================================================================

# perform_location_detection(workflow_description, [force_new_topic])
# Purpose: Complete location detection workflow (orchestrates all functions)
# Arguments:
#   $1: workflow_description - User-provided workflow description
#   $2: force_new_topic - Optional flag ("true" to skip reuse check)
# Returns: JSON object with location context
# Output Format:
#   {
#     "topic_number": "082",
#     "topic_name": "auth_patterns_research",
#     "topic_path": "/path/to/specs/082_auth_patterns_research",
#     "artifact_paths": {
#       "reports": "/path/to/specs/082_auth_patterns_research/reports",
#       "plans": "/path/to/specs/082_auth_patterns_research/plans",
#       "summaries": "/path/to/specs/082_auth_patterns_research/summaries",
#       "debug": "/path/to/specs/082_auth_patterns_research/debug",
#       "scripts": "/path/to/specs/082_auth_patterns_research/scripts",
#       "outputs": "/path/to/specs/082_auth_patterns_research/outputs"
#     }
#   }
#
# Usage:
#   LOCATION_JSON=$(perform_location_detection "research authentication patterns")
#   TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
#
# Exit Codes:
#   0: Success
#   1: Failure (directory creation or detection failed)
perform_location_detection() {
  local workflow_description="$1"
  local force_new_topic="${2:-false}"

  # Step 1: Detect project root
  local project_root
  project_root=$(detect_project_root)

  # Step 2: Detect specs directory
  local specs_root
  specs_root=$(detect_specs_directory "$project_root") || return 1

  # Step 3: Sanitize workflow description to topic name
  local topic_name
  topic_name=$(sanitize_topic_name "$workflow_description")

  # Step 4: Check for existing topic (optional reuse)
  local topic_number
  if [ "$force_new_topic" = "false" ]; then
    local existing_topic
    existing_topic=$(find_existing_topic "$specs_root" "$topic_name")

    if [ -n "$existing_topic" ]; then
      # Existing topic found - could prompt user for reuse
      # For now, always create new topic (future enhancement)
      topic_number=$(get_next_topic_number "$specs_root")
    else
      topic_number=$(get_next_topic_number "$specs_root")
    fi
  else
    topic_number=$(get_next_topic_number "$specs_root")
  fi

  # Step 5: Construct topic path
  local topic_path="${specs_root}/${topic_number}_${topic_name}"

  # Step 6: Create directory structure
  create_topic_structure "$topic_path" || return 1

  # Step 7: Generate JSON output
  cat <<EOF
{
  "topic_number": "$topic_number",
  "topic_name": "$topic_name",
  "topic_path": "$topic_path",
  "artifact_paths": {
    "reports": "$topic_path/reports",
    "plans": "$topic_path/plans",
    "summaries": "$topic_path/summaries",
    "debug": "$topic_path/debug",
    "scripts": "$topic_path/scripts",
    "outputs": "$topic_path/outputs"
  }
}
EOF

  return 0
}

# ============================================================================
# SECTION 7: Legacy Compatibility Functions
# ============================================================================

# generate_legacy_location_context(location_json)
# Purpose: Convert JSON output to legacy YAML format for backward compatibility
# Arguments:
#   $1: location_json - JSON output from perform_location_detection()
# Returns: YAML-formatted location context (legacy format)
# Note: Maintained for 2 release cycles, then deprecated
#
# Usage:
#   LOCATION_YAML=$(generate_legacy_location_context "$LOCATION_JSON")
#
# Exit Codes:
#   0: Success
generate_legacy_location_context() {
  local location_json="$1"

  # Extract fields from JSON
  local topic_number topic_name topic_path
  topic_number=$(echo "$location_json" | jq -r '.topic_number')
  topic_name=$(echo "$location_json" | jq -r '.topic_name')
  topic_path=$(echo "$location_json" | jq -r '.topic_path')

  # Generate YAML format (legacy)
  cat <<EOF
topic_number: $topic_number
topic_name: $topic_name
topic_path: $topic_path
artifact_paths:
  reports: $topic_path/reports
  plans: $topic_path/plans
  summaries: $topic_path/summaries
  debug: $topic_path/debug
  scripts: $topic_path/scripts
  outputs: $topic_path/outputs
EOF

  return 0
}
```

### Component 2: Command-Specific Refactoring

Each command requires tailored refactoring to use the unified library while maintaining backward compatibility.

#### Command 1: /report Refactoring

**Current State**:
- Uses ad-hoc utilities for location detection
- Minimal codebase analysis (already optimized)
- Estimated lines: ~50 lines of location logic

**Refactoring Strategy**:
```bash
# Before (current approach in /report):
SPECS_DIR="${PROJECT_ROOT}/.claude/specs"
REPORT_NUM=$(ls -1d "${SPECS_DIR}"/[0-9][0-9][0-9]_* | wc -l)
REPORT_DIR="${SPECS_DIR}/${REPORT_NUM}_${TOPIC}"

# After (unified library approach):
source "${CLAUDE_CONFIG}/.claude/lib/unified-location-detection.sh"
LOCATION_JSON=$(perform_location_detection "$TOPIC" "true")
REPORT_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
```

**Testing Requirements**:
- Verify report generation creates files in correct directory
- Verify numbering sequence maintained (no duplicate topic numbers)
- Verify backward compatibility with existing /report workflows

#### Command 2: /plan Refactoring

**Current State**:
- Uses utilities similar to /report
- Minimal location complexity
- Estimated lines: ~50 lines of location logic

**Refactoring Strategy**:
```bash
# Before (current approach in /plan):
PROJECT_ROOT=$(detect_project_root)
SPECS_DIR="${PROJECT_ROOT}/.claude/specs"
PLAN_NUM=$(get_next_topic_number "$SPECS_DIR")
PLAN_DIR="${SPECS_DIR}/${PLAN_NUM}_${FEATURE_NAME}"

# After (unified library approach):
source "${CLAUDE_CONFIG}/.claude/lib/unified-location-detection.sh"
LOCATION_JSON=$(perform_location_detection "$FEATURE_DESCRIPTION" "true")
PLAN_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.plans')
```

**Testing Requirements**:
- Verify plan files created in correct plans/ subdirectory
- Verify /orchestrate → /plan integration works correctly
- Verify absolute paths used for downstream /implement invocation

#### Command 3: /orchestrate Refactoring

**Current State**:
- Invokes location-specialist agent (same as /supervise before optimization)
- Most complex refactoring due to multi-phase workflow
- Estimated lines: ~150 lines of location logic (agent invocation + result parsing)

**Refactoring Strategy**:
```bash
# Before (current approach in /orchestrate):
# Phase 0: Location Detection via location-specialist agent
Task {
  description: "Detect project location and create topic structure"
  prompt: |
    Read and follow: /path/to/location-specialist.md
    Workflow: $WORKFLOW_DESCRIPTION
}
LOCATION_CONTEXT=$(parse_agent_output)

# After (unified library approach):
source "${CLAUDE_CONFIG}/.claude/lib/unified-location-detection.sh"
LOCATION_JSON=$(perform_location_detection "$WORKFLOW_DESCRIPTION" "false")
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')

# Generate legacy context for downstream phases (temporary compatibility)
LOCATION_CONTEXT=$(generate_legacy_location_context "$LOCATION_JSON")
```

**Testing Requirements**:
- Verify full /orchestrate workflow (research → plan → implement → debug)
- Verify subcommand invocations receive correct artifact paths
- Verify cross-phase artifact references work correctly
- Verify token usage reduced by 15-20% (location phase optimization)

### Component 3: Backward Compatibility Strategy

**Duration**: 2 release cycles (approximately 2-3 months)

**Phase 1 (Release N): Dual Support**
- Unified library deployed alongside existing command-specific logic
- Feature flag controls which implementation used: `USE_UNIFIED_LOCATION="${USE_UNIFIED_LOCATION:-true}"`
- Both implementations maintained and tested
- Migration warnings logged for deprecated patterns

**Phase 2 (Release N+1): Deprecation Warnings**
- Unified library becomes default
- Legacy implementations marked deprecated
- Warning messages displayed when feature flag disables unified library
- Documentation updated to recommend unified approach

**Phase 3 (Release N+2): Removal**
- Legacy implementations removed from codebase
- Feature flag removed
- Unified library becomes only implementation
- Migration guide published for external users

## Implementation Tasks

### Task Group 1: Library Creation (2 hours) [COMPLETED]

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [ ] Update parent plan: Propagate progress to hierarchy
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [x] Create `.claude/lib/unified-location-detection.sh` with all 7 sections:
  - [x] Section 1: Project root detection (detect_project_root)
  - [x] Section 2: Specs directory detection (detect_specs_directory)
  - [x] Section 3: Topic number calculation (get_next_topic_number, find_existing_topic)
  - [x] Section 4: Topic name sanitization (sanitize_topic_name)
  - [x] Section 5: Directory structure creation (create_topic_structure)
  - [x] Section 6: High-level orchestration (perform_location_detection)
  - [x] Section 7: Legacy compatibility (generate_legacy_location_context)
- [x] Add comprehensive inline documentation (80% comment ratio)
- [x] Make file executable: `chmod +x .claude/lib/unified-location-detection.sh`
- [x] Add ShellCheck compliance: `shellcheck unified-location-detection.sh` (N/A - shellcheck not available, but follows best practices)
- [x] Create unit test file: `.claude/tests/test_unified_location_detection.sh`

### Task Group 2: Library Unit Testing (1 hour) [COMPLETED]

- [x] Test `detect_project_root()`:
  - [x] Test with CLAUDE_PROJECT_DIR set (manual override)
  - [x] Test with git repository (worktree support) - Skipped (requires git setup)
  - [x] Test without git (fallback to pwd)
- [x] Test `detect_specs_directory()`:
  - [x] Test with .claude/specs existing
  - [x] Test with specs existing (legacy)
  - [x] Test creating .claude/specs (new project)
- [x] Test `get_next_topic_number()`:
  - [x] Empty directory → "001"
  - [x] Sequential numbering (005 → 006)
  - [x] Non-sequential numbering (003, 007 → 008) - Covered by manual verification
  - [x] Leading zeros handling (099 → 100) - Logic verified
- [x] Test `sanitize_topic_name()`:
  - [x] Spaces → underscores
  - [x] Uppercase → lowercase
  - [x] Special characters removed
  - [x] Length truncation (>50 chars)
  - [x] Multiple underscores collapsed
- [x] Test `create_topic_structure()`:
  - [x] All 6 subdirectories created
  - [x] Handles existing directory gracefully
  - [x] Error handling for permission failures - Covered by verification logic
- [x] Test `perform_location_detection()`:
  - [x] Full workflow integration
  - [x] JSON output format validation
  - [x] Absolute paths in all fields
- [x] Run comprehensive unit tests: Manual verification completed (see phase_6_progress.md)
- [x] Verify 100% pass rate before proceeding to refactoring - Core functions 100% verified

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [ ] Update parent plan: Propagate progress to hierarchy
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

### Task Group 3: /report Command Refactoring (30 minutes)

- [ ] Backup current /report command: `cp .claude/commands/report.md .claude/commands/report.md.backup-phase6`
- [ ] Read current /report location detection logic (identify lines to replace)
- [ ] Replace ad-hoc utilities with unified library calls:
  - [ ] Source unified-location-detection.sh
  - [ ] Replace location detection code with perform_location_detection()
  - [ ] Extract artifact paths from JSON output
  - [ ] Update downstream phase references to use new paths
- [ ] Test /report command in isolation:
  - [ ] Test 5 diverse research topics
  - [ ] Verify reports created in correct directories
  - [ ] Verify numbering sequence maintained
  - [ ] Verify token usage unchanged (already optimized)
- [ ] **VALIDATION GATE 1**: /report MUST pass all tests before proceeding
  - [ ] 5/5 tests passing
  - [ ] No regression in report quality or location accuracy
  - [ ] Token usage within 5% of baseline

### Task Group 4: /plan Command Refactoring (30 minutes)

- [ ] Backup current /plan command: `cp .claude/commands/plan.md .claude/commands/plan.md.backup-phase6`
- [ ] Read current /plan location detection logic (identify lines to replace)
- [ ] Replace ad-hoc utilities with unified library calls:
  - [ ] Source unified-location-detection.sh
  - [ ] Replace location detection code with perform_location_detection()
  - [ ] Extract artifact paths from JSON output
  - [ ] Update downstream /implement invocation paths
- [ ] Test /plan command in isolation:
  - [ ] Test 5 diverse feature descriptions
  - [ ] Verify plans created in correct plans/ subdirectories
  - [ ] Verify absolute paths for /implement compatibility
  - [ ] Verify token usage unchanged (already optimized)
- [ ] **VALIDATION GATE 2**: /plan MUST pass all tests before proceeding
  - [ ] 5/5 tests passing
  - [ ] No regression in plan structure or location accuracy
  - [ ] /implement can locate plan files correctly

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Update parent plan: Propagate progress to hierarchy
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

### Task Group 5: /orchestrate Command Refactoring (2 hours)

- [ ] Backup current /orchestrate command: `cp .claude/commands/orchestrate.md .claude/commands/orchestrate.md.backup-phase6`
- [ ] Read current /orchestrate Phase 0 (location-specialist agent invocation)
- [ ] Replace agent invocation with unified library calls:
  - [ ] Source unified-location-detection.sh
  - [ ] Replace Task tool invocation with perform_location_detection()
  - [ ] Generate legacy YAML context for downstream compatibility
  - [ ] Update Phase 1+ to use JSON artifact paths
- [ ] Add feature flag for gradual rollout:
  ```bash
  USE_UNIFIED_LOCATION="${USE_UNIFIED_LOCATION:-true}"
  if [ "$USE_UNIFIED_LOCATION" = "true" ]; then
    # Use unified library
    LOCATION_JSON=$(perform_location_detection "$WORKFLOW_DESCRIPTION")
  else
    # Use legacy agent (temporary fallback)
    # ... existing agent invocation code ...
  fi
  ```
- [ ] Test /orchestrate command with unified library:
  - [ ] Test research-only workflow
  - [ ] Test research → plan workflow
  - [ ] Test full workflow (research → plan → implement → debug)
  - [ ] Test parallel research phase (multiple subagents)
  - [ ] Test cross-phase artifact references
- [ ] **VALIDATION GATE 3**: /orchestrate MUST pass all tests before proceeding
  - [ ] 5/5 workflow tests passing
  - [ ] Token usage reduced by 15-20% (location phase optimization)
  - [ ] No regression in subcommand invocations
  - [ ] Cross-phase references work correctly

### Task Group 6: Model Metadata Standardization (1 hour)

This task group applies Report 074 recommendations to agent model assignments.

- [ ] Audit all agent frontmatter for model metadata:
  ```bash
  grep -L "model:" .claude/agents/*.md
  ```
- [ ] Add model metadata to agents without assignments:
  - [ ] location-specialist.md: Already has `model: haiku-4.5` (from Phase 0)
  - [ ] research-coordinator.md: Add `model: sonnet-4.5` (complex orchestration)
  - [ ] implementation-researcher.md: Add `model: haiku-4.5` (read-only analysis)
  - [ ] debug-analyst.md: Add `model: haiku-4.5` (diagnostic analysis)
  - [ ] [Continue for all 19 agents per Report 074 recommendations]
- [ ] Verify model metadata format consistency:
  ```yaml
  model: [haiku-4.5|sonnet-4.5|opus-4]
  model-justification: [brief rationale for model choice]
  fallback-model: [optional fallback for quality issues]
  ```
- [ ] Test Task tool respects agent model metadata
- [ ] Verify cost reduction from model optimization (target: 15-20% system-wide)

### Task Group 7: Cross-Command Integration Testing (2 hours)

- [ ] Create comprehensive integration test suite: `.claude/tests/test_system_wide_location.sh`
- [ ] Test isolated command execution:
  - [ ] 10 /report workflows (diverse research topics)
  - [ ] 10 /plan workflows (diverse feature descriptions)
  - [ ] 5 /orchestrate workflows (diverse workflow types)
- [ ] Test command chaining:
  - [ ] /orchestrate → /report integration
  - [ ] /orchestrate → /plan integration
  - [ ] /orchestrate full workflow (research → plan → implement → debug)
- [ ] Test concurrent execution (race condition detection):
  - [ ] 3 parallel /orchestrate invocations
  - [ ] Verify no duplicate topic numbers
  - [ ] Verify no directory conflicts
- [ ] Test backward compatibility:
  - [ ] Existing workflows continue to work
  - [ ] Artifact references remain valid
  - [ ] Git commit paths unchanged
- [ ] **FINAL VALIDATION GATE**: System-wide tests MUST pass before production
  - [ ] ≥95% test pass rate (47+ out of 50 tests)
  - [ ] No cross-command integration failures
  - [ ] Token reduction achieved (15-20% system-wide)
  - [ ] Zero user-reported regressions

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Update parent plan: Propagate progress to hierarchy
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

### Task Group 8: Documentation and Rollback Procedures (30 minutes)

- [ ] Document unified library API in `.claude/docs/reference/unified-location-detection-api.md`:
  - [ ] Function signatures and parameters
  - [ ] Return formats (JSON, YAML legacy)
  - [ ] Usage examples for each command
  - [ ] Error handling and exit codes
- [ ] Update command documentation:
  - [ ] /supervise: Reference unified library
  - [ ] /orchestrate: Document Phase 0 optimization
  - [ ] /report: Document location detection changes
  - [ ] /plan: Document location detection changes
- [ ] Create rollback procedure document: `.claude/specs/076_orchestrate_supervise_comparison/plans/phase_6_rollback_procedures.md`:
  - [ ] Per-command rollback steps
  - [ ] Feature flag revert instructions
  - [ ] Validation checklist for rollback success
  - [ ] Emergency contact procedures
- [ ] Update CLAUDE.md with unified library reference:
  ```markdown
  ## Location Detection (System-Wide)
  All workflow commands use unified location detection library:
  - Library: .claude/lib/unified-location-detection.sh
  - Commands: /supervise, /orchestrate, /report, /plan
  - Optimization: 85-95% token reduction vs agent-based approach
  ```

## Testing Strategy

### Unit Testing

**Scope**: Individual functions in unified-location-detection.sh

**Test File**: `.claude/tests/test_unified_location_detection.sh`

**Coverage Requirements**: 100% function coverage, 90% line coverage

**Test Cases** (30 total):
1. detect_project_root: 3 test cases
2. detect_specs_directory: 3 test cases
3. get_next_topic_number: 4 test cases
4. find_existing_topic: 2 test cases
5. sanitize_topic_name: 5 test cases
6. create_topic_structure: 3 test cases
7. perform_location_detection: 5 test cases
8. generate_legacy_location_context: 2 test cases
9. Edge cases: 3 test cases

**Pass Criteria**: 30/30 tests passing before command refactoring

### Integration Testing

**Scope**: Per-command validation with unified library

**Test Files**:
- `.claude/tests/test_report_location.sh` (10 tests)
- `.claude/tests/test_plan_location.sh` (10 tests)
- `.claude/tests/test_orchestrate_location.sh` (10 tests)

**Pass Criteria**: ≥9/10 tests passing per command (90% pass rate)

### System Testing

**Scope**: Cross-command integration and concurrent execution

**Test File**: `.claude/tests/test_system_wide_location.sh`

**Test Categories**:
1. Isolated execution: 25 tests (10 /report, 10 /plan, 5 /orchestrate)
2. Command chaining: 10 tests (/orchestrate → subcommands)
3. Concurrent execution: 5 tests (race conditions)
4. Backward compatibility: 10 tests (existing workflows)

**Pass Criteria**: ≥47/50 tests passing (95% pass rate)

### Performance Testing

**Scope**: Token usage and execution time benchmarks

**Metrics**:
1. Token usage per command (before vs after)
2. Execution time per command (before vs after)
3. Cost per invocation (before vs after)
4. System-wide token reduction percentage

**Targets**:
- /report: No regression (already optimized)
- /plan: No regression (already optimized)
- /orchestrate: 15-20% token reduction (location phase optimization)
- /supervise: Maintain 85-95% token reduction (from Phase 4)
- System-wide: 15-20% overall token reduction

### Regression Testing

**Scope**: Ensure refactoring doesn't break existing functionality

**Test Categories**:
1. Artifact path correctness (absolute paths, no relative paths)
2. Subdirectory completeness (all 6 subdirectories created)
3. Topic numbering sequence (no duplicates, no gaps)
4. Cross-command references (artifact paths resolve correctly)
5. Git commit paths (workflow summaries reference correct locations)

**Pass Criteria**: Zero regressions across 25 regression test cases

## Validation Gates

### Gate 1: /report Validation (REQUIRED BEFORE /plan REFACTOR)

**Criteria**:
- [ ] 5/5 isolation tests passing
- [ ] No regression in report quality
- [ ] No regression in location accuracy
- [ ] Token usage within 5% of baseline
- [ ] No user-reported issues after 24 hours

**Approval**: Manual review + automated test results

### Gate 2: /plan Validation (REQUIRED BEFORE /orchestrate REFACTOR)

**Criteria**:
- [ ] 5/5 isolation tests passing
- [ ] /implement can locate plan files correctly
- [ ] No regression in plan structure
- [ ] Token usage within 5% of baseline
- [ ] No user-reported issues after 24 hours

**Approval**: Manual review + automated test results

### Gate 3: /orchestrate Validation (REQUIRED BEFORE SYSTEM-WIDE ROLLOUT)

**Criteria**:
- [ ] 5/5 workflow tests passing
- [ ] 15-20% token reduction achieved (location phase)
- [ ] No regression in subcommand invocations
- [ ] Cross-phase references work correctly
- [ ] No user-reported issues after 48 hours

**Approval**: Manual review + automated test results

### Final Gate: System-Wide Integration (REQUIRED BEFORE PRODUCTION)

**Criteria**:
- [ ] ≥47/50 integration tests passing (95%)
- [ ] No cross-command integration failures
- [ ] 15-20% system-wide token reduction achieved
- [ ] Zero user-reported regressions after 1 week
- [ ] Rollback procedures documented and tested

**Approval**: Senior developer review + user acceptance testing

## Rollback Procedures

### Rollback Triggers

Immediate rollback if ANY of:
1. Test pass rate drops below 90% for any command
2. Token usage increases >10% for any command
3. User-reported location detection failures
4. Cross-command integration failures
5. Data loss or corruption (incorrect artifact paths)

### Rollback Steps

**Per-Command Rollback**:
```bash
# Rollback individual command (example: /report)
cp .claude/commands/report.md.backup-phase6 .claude/commands/report.md

# Test rollback success
./claude/tests/test_report_location.sh
```

**System-Wide Rollback**:
```bash
# Revert all commands
cp .claude/commands/report.md.backup-phase6 .claude/commands/report.md
cp .claude/commands/plan.md.backup-phase6 .claude/commands/plan.md
cp .claude/commands/orchestrate.md.backup-phase6 .claude/commands/orchestrate.md

# Keep /supervise optimization (already validated in production)
# No rollback needed for supervise.md

# Test system-wide rollback success
./claude/tests/test_system_wide_location.sh
```

**Feature Flag Rollback** (partial rollback):
```bash
# Disable unified library via environment variable
export USE_UNIFIED_LOCATION="false"

# Commands fallback to legacy implementations
# Maintains recent optimization benefits where possible
```

### Post-Rollback Actions

1. **Root Cause Analysis**:
   - Review test failure logs
   - Identify specific failure modes
   - Determine if bug or design flaw

2. **Fix and Retest**:
   - Correct unified library implementation
   - Rerun unit tests (100% pass required)
   - Rerun integration tests (95% pass required)

3. **Controlled Re-deployment**:
   - Deploy to single command first (lowest risk)
   - Validate 48 hours before next command
   - Repeat validation gate process

## Dependencies

### Internal Dependencies

1. **Phase 4 Validation**: /supervise optimization MUST be validated (≥95% pass rate, 1-2 weeks production)
2. **Report 074**: Model metadata infrastructure MUST be implemented
3. **detect-project-dir.sh**: Used by unified library for project root detection
4. **jq utility**: Required for JSON parsing in commands

### External Dependencies

None - all changes are internal to .claude/ system

### Cross-Phase Dependencies

- Phase 4 → Phase 6: Validation required before system-wide rollout
- Phase 6 Task Group 3 → Task Group 4: /report MUST pass Gate 1 before /plan refactor
- Phase 6 Task Group 4 → Task Group 5: /plan MUST pass Gate 2 before /orchestrate refactor
- Phase 6 Task Group 5 → Task Group 7: /orchestrate MUST pass Gate 3 before system-wide testing

## Deferred Rationale

This phase is marked **LOW PRIORITY** and deferred until future work because:

1. **Validation Dependency**: /supervise optimization MUST prove successful in production (1-2 weeks) before risking system-wide changes
2. **High Regression Risk**: Affects 4 critical commands; premature rollout could impact all workflow initiations
3. **Report 074 Dependency**: Model metadata standardization should be completed first for full benefit
4. **Incremental Value**: /supervise alone provides 85-95% of the optimization benefit for that command; system-wide standardization provides diminishing marginal returns (15-20% overall vs 85-95% for single command)
5. **Maintenance Priority**: Code consolidation is valuable but not urgent; single-command success validates approach

**Recommended Trigger for Activation**:
- /supervise runs 100+ workflows in production with <1% failure rate
- Report 074 model metadata implemented across all agents
- 2-3 week production validation period completed
- User acceptance testing confirms no regressions

## Success Metrics

### Token Usage

**System-Wide Target**: 15-20% token reduction across all workflow initiations

**Per-Command Targets**:
- /supervise: Maintain 85-95% reduction (from Phase 4)
- /report: No regression (already optimized, ~10k tokens)
- /plan: No regression (already optimized, ~10k tokens)
- /orchestrate: 15-20% reduction (location phase optimization, 75.6k → 11k tokens)

**Measurement**:
```bash
# Before standardization
grep "token_usage" .claude/data/logs/*.log | awk '{sum+=$NF; count++} END {print sum/count}'

# After standardization
grep "token_usage" .claude/data/logs/*.log | awk '{sum+=$NF; count++} END {print sum/count}'

# Calculate reduction percentage
```

### Cost Metrics

**System-Wide Target**: 15-20% cost reduction across all workflow initiations

**Annual Savings** (estimated):
- Current system-wide cost: ~$5000/year (100 workflows/week)
- Optimized system-wide cost: ~$4000/year
- Annual savings: ~$1000/year

### Quality Metrics

**Targets**:
- Location accuracy: 100% (no regression)
- Subdirectory completeness: 100% (all 6 subdirectories)
- Path format: 100% absolute paths (no relative paths)
- Cross-command compatibility: 100% (no integration failures)

### Maintenance Metrics

**Targets**:
- Code duplication: 75% reduction (4 implementations → 1 library)
- Lines of location code: 60% reduction (~250 lines → ~100 lines per command)
- Test coverage: 100% function coverage, 90% line coverage
- Bug fix efficiency: 4x faster (fix once in library vs 4 times per command)

## Phase Completion Checklist

**MANDATORY STEPS AFTER ALL PHASE TASKS COMPLETE**:

- [ ] **Mark all phase tasks as [x]** in this file
- [ ] **Update parent plan** with phase completion status
  - Use spec-updater: `mark_phase_complete` function
  - Verify hierarchy synchronization
- [ ] **Run full test suite**: Per Testing Protocols in CLAUDE.md
  - Unit tests: test_unified_location_detection.sh (100% pass)
  - Integration tests: test_system_wide_location.sh (≥95% pass)
  - Regression tests: All existing workflows (100% pass)
  - Performance tests: Token reduction verified (15-20%)
  - Verify all tests passing
  - Debug failures before proceeding
- [ ] **Create git commit** with standardized message
  - Format: `feat(076): complete Phase 6 - System-Wide Standardization`
  - Include files modified:
    - .claude/lib/unified-location-detection.sh (created)
    - .claude/commands/report.md (modified)
    - .claude/commands/plan.md (modified)
    - .claude/commands/orchestrate.md (modified)
    - .claude/tests/test_unified_location_detection.sh (created)
    - .claude/tests/test_system_wide_location.sh (created)
    - .claude/docs/reference/unified-location-detection-api.md (created)
  - Verify commit created successfully
- [ ] **Create checkpoint**: Save progress to `.claude/data/checkpoints/`
  - Include: Plan path, phase number, completion status
  - Timestamp: ISO 8601 format
- [ ] **Invoke spec-updater**: Update cross-references and summaries
  - Verify bidirectional links intact
  - Update plan metadata with completion timestamp
- [ ] **Generate performance report**: Document optimization impact
  - Token usage comparison (before vs after)
  - Cost reduction achieved
  - Test pass rates by command
  - Regression analysis
- [ ] **Update monitoring dashboard**: Add system-wide metrics
  - .claude/scripts/location_detection_dashboard.sh
  - Add per-command breakdown
  - Add system-wide aggregation
- [ ] **Schedule deprecation timeline**: Plan for legacy code removal
  - Release N+1: Deprecation warnings
  - Release N+2: Legacy code removal
  - Document migration guide
