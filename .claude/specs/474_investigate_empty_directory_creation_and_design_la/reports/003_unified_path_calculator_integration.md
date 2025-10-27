# Unified Path Calculator Integration Research

## Overview

The unified path calculator in the Claude Code system provides comprehensive path calculation and directory management utilities through the `unified-location-detection.sh` library. This research investigated the separation between path calculation and directory creation, focusing on how lazy directory creation can be integrated while preserving the existing path calculator functionality.

**Key Finding**: The path calculator already implements lazy directory creation through the `ensure_artifact_directory()` function. The separation of concerns is clean: path calculation happens first via `perform_location_detection()`, then directory creation happens on-demand via `ensure_artifact_directory()` when files are written.

**Current State**: The system transitioned from eager directory creation (creating all 6 subdirectories upfront) to lazy directory creation (creating only the topic root, with subdirectories created on-demand). This eliminated 400-500 empty directories across the codebase.

## Research Findings

### Path Calculator Components

The unified path calculator consists of several modular functions in `/home/benjamin/.config/.claude/lib/unified-location-detection.sh`:

#### 1. Project Root Detection (Lines 42-60)
```bash
detect_project_root()
```
**Purpose**: Determines the project root directory with git worktree support
**Precedence**: `CLAUDE_PROJECT_DIR` env var > git root > current directory
**Returns**: Absolute path to project root
**Dependencies**: None (uses git if available, fallbacks gracefully)

#### 2. Specs Directory Detection (Lines 79-111)
```bash
detect_specs_directory(project_root)
```
**Purpose**: Locates or creates the specs directory
**Precedence**: `.claude/specs` (preferred) > `specs` (legacy) > create `.claude/specs`
**Override**: `CLAUDE_SPECS_ROOT` environment variable for test isolation
**Returns**: Absolute path to specs directory
**Dependencies**: Requires project root from `detect_project_root()`

#### 3. Topic Number Calculation (Lines 129-148)
```bash
get_next_topic_number(specs_root)
```
**Purpose**: Calculate next sequential topic number from existing topics
**Logic**: Finds max existing topic number (pattern: `NNN_*`), increments by 1
**Returns**: Three-digit topic number (e.g., "001", "042", "137")
**Handle Empty**: Returns "001" for empty specs directory
**Dependencies**: Requires specs root from `detect_specs_directory()`

#### 4. Topic Name Sanitization (Lines 204-216)
```bash
sanitize_topic_name(raw_name)
```
**Purpose**: Convert workflow description to valid directory name
**Rules**:
- Convert to lowercase
- Replace spaces with underscores
- Remove non-alphanumeric (except underscores)
- Trim leading/trailing underscores
- Collapse multiple underscores
- Truncate to 50 characters
**Example**: "Research: Authentication Patterns" → "research_authentication_patterns"
**Dependencies**: None (pure string transformation)

### Path Calculation vs Directory Creation Separation

The system demonstrates clear separation of concerns:

#### Path Calculation Phase
**Function**: `perform_location_detection(workflow_description, force_new_topic)` (Lines 321-378)

**What it calculates**:
- Topic number (e.g., "474")
- Topic name (sanitized, e.g., "investigate_empty_directory_creation")
- Topic path (e.g., `/home/benjamin/.config/.claude/specs/474_investigate_empty_directory_creation`)
- Artifact paths (reports, plans, summaries, debug, scripts, outputs subdirectories)

**What it creates**:
- **Only the topic root directory** (e.g., `specs/474_investigate_empty_directory_creation/`)
- **Does NOT create subdirectories** (reports/, plans/, etc.)

**Output Format**: JSON object with all calculated paths
```json
{
  "topic_number": "474",
  "topic_name": "investigate_empty_directory_creation",
  "topic_path": "/home/benjamin/.config/.claude/specs/474_investigate_empty_directory_creation",
  "artifact_paths": {
    "reports": "/path/to/specs/474_topic/reports",
    "plans": "/path/to/specs/474_topic/plans",
    "summaries": "/path/to/specs/474_topic/summaries",
    "debug": "/path/to/specs/474_topic/debug",
    "scripts": "/path/to/specs/474_topic/scripts",
    "outputs": "/path/to/specs/474_topic/outputs"
  }
}
```

**Key Design**: The artifact_paths are **calculated but not created**. This enables lazy directory creation.

#### Directory Creation Phase (Lazy Pattern)

**Function**: `ensure_artifact_directory(file_path)` (Lines 239-250)

**Purpose**: Create parent directory for an artifact file just-in-time
**Trigger**: Called immediately before writing a file with the Write tool
**Idempotent**: Safe to call multiple times for same path
**Returns**: 0 on success, 1 on failure

**Implementation**:
```bash
ensure_artifact_directory() {
  local file_path="$1"
  local parent_dir=$(dirname "$file_path")

  # Idempotent: succeeds whether directory exists or not
  [ -d "$parent_dir" ] || mkdir -p "$parent_dir" || {
    echo "ERROR: Failed to create directory: $parent_dir" >&2
    return 1
  }

  return 0
}
```

**Usage Pattern in Commands**:
```bash
# Step 1: Calculate all paths (no directory creation)
LOCATION_JSON=$(perform_location_detection "$RESEARCH_TOPIC" "false")
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')

# Step 2: Later, before writing file, create directory on-demand
REPORT_PATH="${REPORTS_DIR}/001_analysis.md"
ensure_artifact_directory "$REPORT_PATH" || exit 1

# Step 3: Write file (directory guaranteed to exist now)
echo "content" > "$REPORT_PATH"
```

### Topic Structure Creation (Root Only)

**Function**: `create_topic_structure(topic_path)` (Lines 271-287)

**Current Implementation (Lazy)**:
- Creates **ONLY** the topic root directory (e.g., `specs/474_topic/`)
- **Does NOT** create subdirectories (reports/, plans/, summaries/, debug/, scripts/, outputs/)
- Subdirectories created on-demand via `ensure_artifact_directory()`

**Historical Context**: Previously created all 6 subdirectories eagerly, resulting in 400-500 empty directories across the codebase. Refactored to lazy creation pattern in spec 440 (empty directory creation analysis).

**Verification**: Function verifies topic root exists after creation, returns 1 if verification fails.

### Command Integration Patterns

All workflow commands follow the same integration pattern:

#### /report Command (Lines 84-95)
```bash
# Source unified library
source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/unified-location-detection.sh"

# Perform location detection (calculates paths, creates topic root)
LOCATION_JSON=$(perform_location_detection "$RESEARCH_TOPIC" "false")

# Extract topic path from JSON output
if command -v jq &>/dev/null; then
  TOPIC_DIR=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
  TOPIC_NAME=$(echo "$LOCATION_JSON" | jq -r '.topic_name')
else
  # Fallback without jq
  TOPIC_DIR=$(echo "$LOCATION_JSON" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
fi
```

#### /plan Command (Lines 482-493)
```bash
# Use unified location detection library for new topics
LOCATION_JSON=$(perform_location_detection "$FEATURE_DESCRIPTION" "false")

# Extract topic path from JSON output
if command -v jq &>/dev/null; then
  TOPIC_DIR=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
  PLANS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.plans')
else
  # Fallback without jq
  TOPIC_DIR=$(echo "$LOCATION_JSON" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
fi
```

#### /orchestrate Command (Lines 428-439)
```bash
# Perform location detection using unified library
LOCATION_JSON=$(perform_location_detection "$WORKFLOW_DESCRIPTION" "false")

# Extract values from JSON output
if command -v jq &>/dev/null; then
  TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
  TOPIC_NUMBER=$(echo "$LOCATION_JSON" | jq -r '.topic_number')
  TOPIC_NAME=$(echo "$LOCATION_JSON" | jq -r '.topic_name')
  ARTIFACT_REPORTS=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
  ARTIFACT_PLANS=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.plans')
fi
```

**Common Pattern**:
1. Source `unified-location-detection.sh` library
2. Call `perform_location_detection()` with workflow description
3. Parse JSON output to extract needed paths (topic_path, artifact_paths)
4. Later, before writing files, call `ensure_artifact_directory()` with file path
5. Write file using Write tool

### Research Subdirectory Support

**Function**: `create_research_subdirectory(topic_path, research_name)` (Lines 448-521)

**Purpose**: Create numbered subdirectory within topic's reports/ for hierarchical research
**Pattern**: `{topic_path}/reports/{NNN_research_name}/`
**Numbering**: Automatically calculates next number (001, 002, 003, etc.)
**Use Case**: `/research` command for multi-report hierarchical research

**Example**:
```bash
RESEARCH_SUBDIR=$(create_research_subdirectory "$TOPIC_PATH" "auth_patterns")
# Returns: /specs/474_topic/reports/001_auth_patterns/
```

**Lazy Creation Support**: Creates reports/ parent directory if it doesn't exist (lines 473-479)

### Dependencies Between Functions

The path calculator has a clear dependency chain:

```
detect_project_root()
  └─> detect_specs_directory(project_root)
       └─> get_next_topic_number(specs_root)
       └─> sanitize_topic_name(raw_name)
            └─> perform_location_detection() [orchestrates all above]
                 └─> create_topic_structure(topic_path)
                      └─> ensure_artifact_directory(file_path) [later, on-demand]
```

**Key Insight**: No function depends on subdirectories existing. All functions operate on paths calculated from topic root and artifact type.

### Path Information Available to Commands

After calling `perform_location_detection()`, commands have access to:

1. **Topic Number**: Three-digit sequential number
2. **Topic Name**: Sanitized snake_case name
3. **Topic Path**: Full absolute path to topic root
4. **Artifact Paths**: Full absolute paths to all 6 subdirectories (calculated, not created)

**Commands can then**:
- Construct full file paths (e.g., `${REPORTS_DIR}/001_analysis.md`)
- Pass file paths to `ensure_artifact_directory()` before writing
- Use Write tool with confidence that directory exists

**No directory existence checks needed**: `ensure_artifact_directory()` is idempotent and handles all cases.

## Recommendations

### 1. Continue Using Current Lazy Directory Creation Pattern

**Status**: Already implemented correctly
**Rationale**: The current separation is optimal:
- Path calculation provides all information needed (no filesystem checks required)
- Directory creation deferred until file write operations
- Zero empty directories created
- Idempotent design (safe to call multiple times)

**No Action Required**: System already implements best practices.

### 2. Document ensure_artifact_directory() Usage Pattern

**Priority**: Medium
**Location**: `/home/benjamin/.config/.claude/docs/guides/using-utility-libraries.md`

**Recommended Content**:
```markdown
## Lazy Directory Creation Pattern

Commands should use `ensure_artifact_directory()` before writing files:

\`\`\`bash
# Step 1: Calculate paths (no directories created)
LOCATION_JSON=$(perform_location_detection "$TOPIC" "false")
REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')

# Step 2: Construct file path
REPORT_PATH="${REPORTS_DIR}/001_analysis.md"

# Step 3: Ensure directory exists (creates on-demand)
ensure_artifact_directory "$REPORT_PATH" || exit 1

# Step 4: Write file (directory guaranteed to exist)
echo "content" > "$REPORT_PATH"
\`\`\`

**Why This Pattern?**
- Eliminates empty directories (only creates when files written)
- Idempotent (safe to call multiple times)
- Graceful error handling (returns 1 on failure)
```

### 3. Add Test Coverage for Path Calculator

**Priority**: Low
**Rationale**: Ensure lazy directory creation behavior preserved during future refactors

**Test Cases**:
1. `perform_location_detection()` creates only topic root (not subdirectories)
2. `ensure_artifact_directory()` creates parent directory on-demand
3. Multiple calls to `ensure_artifact_directory()` are idempotent
4. Verify no empty subdirectories after location detection
5. Verify subdirectories created when files written

**Test File**: `/home/benjamin/.config/.claude/tests/test_unified_location_detection.sh` (already exists, verify coverage)

### 4. Leverage JSON Output for Command Simplification

**Priority**: Low
**Opportunity**: Commands currently extract paths individually from JSON

**Current Pattern** (verbose):
```bash
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
TOPIC_NUMBER=$(echo "$LOCATION_JSON" | jq -r '.topic_number')
ARTIFACT_REPORTS=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
```

**Potential Helper Function** (future enhancement):
```bash
# extract_location_fields(location_json, field1, field2, ...)
# Returns: Space-separated values for requested fields
extract_location_fields "$LOCATION_JSON" topic_path topic_number artifact_paths.reports
```

**Benefit**: Reduces command boilerplate, centralizes JSON parsing logic

### 5. Consider Adding Path Validation Utility

**Priority**: Very Low
**Use Case**: Commands that need to verify paths before operations (debugging)

**Potential Function**:
```bash
validate_artifact_path(file_path, expected_artifact_type)
# Validates that file_path is within expected artifact subdirectory
# Returns: 0 if valid, 1 if invalid
# Example: validate_artifact_path "/specs/474/reports/001.md" "reports"
```

**Benefit**: Catches path construction errors early (defensive programming)

## References

### Primary Library Files
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` - Complete path calculator and lazy directory creation implementation
  - Lines 42-60: `detect_project_root()` - Project root detection
  - Lines 79-111: `detect_specs_directory()` - Specs directory detection
  - Lines 129-148: `get_next_topic_number()` - Topic number calculation
  - Lines 204-216: `sanitize_topic_name()` - Topic name sanitization
  - Lines 239-250: `ensure_artifact_directory()` - Lazy directory creation
  - Lines 271-287: `create_topic_structure()` - Topic root creation
  - Lines 321-378: `perform_location_detection()` - High-level orchestration
  - Lines 448-521: `create_research_subdirectory()` - Research subdirectory support

### Supporting Library Files
- `/home/benjamin/.config/.claude/lib/topic-utils.sh` - Legacy topic utilities (pre-unification)
  - Lines 18-34: `get_next_topic_number()` - Original implementation
  - Lines 46-55: `sanitize_topic_name()` - Original implementation
  - Lines 63-90: `create_topic_structure()` - Original eager implementation (created all 6 subdirectories)
- `/home/benjamin/.config/.claude/lib/detect-project-dir.sh` - Legacy project detection (pre-unification)
  - Lines 28-39: Git repository detection
  - Lines 42-48: Fallback to current directory

### Command Integration Examples
- `/home/benjamin/.config/.claude/commands/report.md` - Lines 84-95: Location detection usage
- `/home/benjamin/.config/.claude/commands/plan.md` - Lines 482-493: Location detection usage
- `/home/benjamin/.config/.claude/commands/research.md` - Lines 85-96: Location detection usage
- `/home/benjamin/.config/.claude/commands/orchestrate.md` - Lines 428-439: Location detection usage
- `/home/benjamin/.config/.claude/commands/supervise.md` - Line 598: Topic structure creation (includes fallback mechanism)

### Related Research Reports
- `/home/benjamin/.config/.claude/specs/440_empty_directory_creation_analysis/reports/001_empty_directory_creation_analysis_research/003_lazy_directory_creation_implementation.md` - Complete analysis of lazy vs eager directory creation trade-offs, implementation patterns, and recommendations
  - Section: Current Directory Creation Pattern (lines 13-50) - Documents eager pattern that was replaced
  - Section: Lazy Initialization Pattern (lines 52-92) - Industry best practices
  - Section: Hybrid Approach (lines 166-219) - Recommended implementation (now realized in unified-location-detection.sh)

### Test Coverage
- `/home/benjamin/.config/.claude/tests/test_unified_location_detection.sh` - Integration tests for location detection library
- `/home/benjamin/.config/.claude/tests/test_empty_directory_detection.sh` - Tests verifying no empty directories created

### Documentation
- `/home/benjamin/.config/.claude/docs/reference/library-api.md` - Library API reference documentation
- `/home/benjamin/.config/.claude/docs/guides/using-utility-libraries.md` - Guide for using utility libraries in commands
- `/home/benjamin/.config/CLAUDE.md` - Section: Unified Location Detection (documents library usage for commands)
