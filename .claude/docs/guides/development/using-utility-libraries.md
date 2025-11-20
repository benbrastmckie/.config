# Using Utility Libraries

Task-focused guide for using `.claude/lib/` utility libraries in commands and agents. This guide helps you decide when to use libraries vs agents and provides practical usage patterns.

## Purpose

This guide answers:
- When should I use a utility library vs invoking an agent?
- How do I source and call library functions in my command?
- What are common patterns for error handling with libraries?
- How do I handle jq dependency for JSON parsing?

For API reference with function signatures, see [Library API Reference](../reference/library-api/overview.md).

---

## When to Use Libraries vs Agents

### Use Utility Libraries When

**Deterministic Operations** (No AI reasoning needed):
- Location detection from user input
- Topic name sanitization
- Directory structure creation
- Plan file parsing
- Metadata extraction from structured files

**Performance Critical Paths**:
- Workflow initialization (create topic directories)
- Checkpoint save/load operations
- Log file writes
- JSON/YAML parsing

**Reusable Patterns Across Commands**:
- All commands need location detection → Use `unified-location-detection.sh`
- All commands need logging → Use `unified-logger.sh`
- Multiple commands parse plans → Use `plan-core-bundle.sh`

**Context Window Optimization**:
- Libraries use 0 tokens (pure bash)
- Agents use 15k-75k tokens per invocation
- Example: `unified-location-detection.sh` saves 65k tokens vs `location-specialist` agent

### Use Agents When

**AI Reasoning Required**:
- Codebase exploration ("find all authentication patterns")
- Root cause analysis ("why is this bug happening?")
- Code generation
- Complex planning decisions

**Ambiguity Resolution**:
- Unclear user requirements
- Multiple valid implementation approaches
- Need to ask clarifying questions

**Large-Scale Analysis**:
- Analyzing entire directories of code
- Cross-file dependency analysis requiring understanding
- Architectural decision-making

See [Skills vs Subagents Decision Guide](skills-vs-subagents-decision.md) for detailed decision framework.

---

## Basic Usage Pattern

### 1. Source the Library

Always use absolute paths from `CLAUDE_CONFIG`:

```bash
#!/usr/bin/env bash

# Get Claude config directory
CLAUDE_CONFIG="${CLAUDE_CONFIG:-${HOME}/.config}"

# Source the library
source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"
```

### 2. Call Library Functions

```bash
# Call function with arguments
LOCATION_JSON=$(perform_location_detection "research authentication patterns")
```

### 3. Extract Results

```bash
# Preferred: Use jq for JSON parsing
if command -v jq &>/dev/null; then
  TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
  REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
else
  # Fallback: Use sed/grep for parsing
  TOPIC_PATH=$(echo "$LOCATION_JSON" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  REPORTS_DIR=$(echo "$LOCATION_JSON" | grep -o '"reports": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
fi
```

### 4. Add Verification Checkpoint

```bash
# MANDATORY VERIFICATION per standards
if [ ! -d "$TOPIC_PATH" ]; then
  echo "ERROR: Location detection failed - directory not created"
  exit 1
fi
```

---

## Common Patterns

### Pattern 1: Location Detection for Workflow Commands

**Use Case**: `/report`, `/plan`, `/orchestrate` need standardized location detection

**Before** (ad-hoc, 50+ lines per command):
```bash
# Old pattern (duplicated across commands)
TOPIC_NAME=$(echo "$USER_INPUT" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | sed 's/[^a-z0-9_]//g')
MAX_NUM=$(ls -1d specs/[0-9][0-9][0-9]_* 2>/dev/null | sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | sort -n | tail -1)
TOPIC_NUM=$(printf "%03d" $((10#$MAX_NUM + 1)))
TOPIC_PATH="specs/${TOPIC_NUM}_${TOPIC_NAME}"
mkdir -p "$TOPIC_PATH"/{reports,plans,summaries,debug,scripts,outputs}
```

**After** (unified library, 10 lines):
```bash
# New pattern (single source of truth)
source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"

LOCATION_JSON=$(perform_location_detection "$USER_INPUT")
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')

# Verification
if [ ! -d "$TOPIC_PATH" ]; then
  echo "ERROR: Location detection failed"
  exit 1
fi
```

**Benefits**:
- 80% code reduction (50 lines → 10 lines)
- Single source of truth (1 tested implementation vs 4 duplicates)
- Automatic updates (fix bug once, all commands benefit)

---

### Pattern 2: Hierarchical Research with Subdirectories

**Use Case**: `/research` command creates numbered subdirectories for parallel research agents

**Implementation**:
```bash
source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"

# Step 1: Detect topic location
LOCATION_JSON=$(perform_location_detection "$USER_INPUT")
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
TOPIC_NAME=$(echo "$LOCATION_JSON" | jq -r '.topic_name')

# Step 2: Create research subdirectory
RESEARCH_SUBDIR=$(create_research_subdirectory "$TOPIC_PATH" "$TOPIC_NAME")

# Verification
if [ ! -d "$RESEARCH_SUBDIR" ]; then
  echo "ERROR: Research subdirectory creation failed"
  exit 1
fi

# Step 3: Create subtopic reports in subdirectory
SUBTOPIC_1_PATH="${RESEARCH_SUBDIR}/001_oauth_analysis.md"
SUBTOPIC_2_PATH="${RESEARCH_SUBDIR}/002_jwt_patterns.md"
```

**Directory Structure Created**:
```
specs/082_authentication_patterns/
├── reports/
│   └── 001_authentication_patterns/  ← Research subdirectory
│       ├── 001_oauth_analysis.md     ← Subtopic 1
│       └── 002_jwt_patterns.md       ← Subtopic 2
├── plans/
├── summaries/
├── debug/
├── scripts/
└── outputs/
```

---

### Pattern 3: Plan Parsing for Implementation

**Use Case**: `/implement` needs to extract phases and tasks from plan file

**Implementation**:
```bash
source "${CLAUDE_CONFIG}/.claude/lib/plan/plan-core-bundle.sh"

PLAN_PATH="$1"

# Parse plan metadata
PLAN_METADATA=$(get_plan_metadata "$PLAN_PATH")
TOTAL_PHASES=$(echo "$PLAN_METADATA" | jq -r '.phases')

# Iterate through phases
for phase_num in $(seq 1 "$TOTAL_PHASES"); do
  # Extract phase info
  PHASE_INFO=$(extract_phase_info "$PLAN_PATH" "$phase_num")
  PHASE_NAME=$(echo "$PHASE_INFO" | jq -r '.name')
  TASKS=$(echo "$PHASE_INFO" | jq -r '.tasks[]')

  echo "Implementing Phase $phase_num: $PHASE_NAME"

  # Implement tasks
  for task in $TASKS; do
    echo "  - $task"
    # ... implementation logic ...
  done
done
```

---

### Pattern 4: Metadata Extraction for Context Optimization

**Use Case**: `/orchestrate` passes report metadata to subagents (not full 5000-token content)

**Implementation**:
```bash
source "${CLAUDE_CONFIG}/.claude/lib/workflow/metadata-extraction.sh"

REPORT_PATH="specs/082_auth/reports/001_oauth_patterns.md"

# Extract metadata (50 tokens) instead of reading full report (5000 tokens)
METADATA=$(extract_report_metadata "$REPORT_PATH")

TITLE=$(echo "$METADATA" | jq -r '.title')
SUMMARY=$(echo "$METADATA" | jq -r '.summary')  # 50-word max
RECOMMENDATIONS=$(echo "$METADATA" | jq -r '.recommendations[]')

# Pass metadata to subagent (not full report content)
cat > agent_prompt.txt <<EOF
Based on report "$TITLE", implement the following:

Summary: $SUMMARY

Recommendations:
$(echo "$RECOMMENDATIONS" | sed 's/^/- /')

Report path: $REPORT_PATH
(Read full report if you need additional details)
EOF
```

**Context Reduction**: 5000 tokens → 250 tokens (95% reduction)

---

### Pattern 5: Checkpoint-Based Resumable Workflows

**Use Case**: `/implement` saves progress and resumes after failures

**Implementation**:
```bash
source "${CLAUDE_CONFIG}/.claude/lib/workflow/checkpoint-utils.sh"

PLAN_FILE="$1"
CHECKPOINT_NAME="implement_$(basename "$PLAN_FILE" .md)"

# Try to load existing checkpoint
if CHECKPOINT=$(load_checkpoint "$CHECKPOINT_NAME"); then
  echo "Resuming from checkpoint..."
  CURRENT_PHASE=$(echo "$CHECKPOINT" | jq -r '.current_phase')
  COMPLETED_TASKS=$(echo "$CHECKPOINT" | jq -r '.completed_tasks[]')
else
  echo "Starting fresh implementation..."
  CURRENT_PHASE=1
  COMPLETED_TASKS=""
fi

# Implement phases
for phase in $(seq "$CURRENT_PHASE" "$TOTAL_PHASES"); do
  echo "Implementing Phase $phase..."

  # ... implementation logic ...

  # Save checkpoint after each phase
  CHECKPOINT_DATA=$(cat <<EOF
{
  "current_phase": $((phase + 1)),
  "completed_tasks": $(echo "$COMPLETED_TASKS" | jq -R . | jq -s .)
}
EOF
)
  save_checkpoint "$CHECKPOINT_NAME" "$CHECKPOINT_DATA"
done
```

---

### Pattern 6: Structured Logging with Rotation

**Use Case**: `/implement` logs adaptive planning decisions for audit trail

**Implementation**:
```bash
source "${CLAUDE_CONFIG}/.claude/lib/core/unified-logger.sh"

# Log informational message
log_info "Starting implementation of plan: $PLAN_FILE"

# Log with JSON context
CONTEXT=$(cat <<EOF
{
  "plan": "$PLAN_FILE",
  "phase": $CURRENT_PHASE,
  "complexity": $COMPLEXITY_SCORE
}
EOF
)
log_info "Phase $CURRENT_PHASE complexity score: $COMPLEXITY_SCORE" "$CONTEXT"

# Log error
if ! run_tests; then
  ERROR_CONTEXT=$(cat <<EOF
{
  "phase": $CURRENT_PHASE,
  "test_command": "$TEST_COMMAND",
  "exit_code": $?
}
EOF
)
  log_error "Test failure in Phase $CURRENT_PHASE" "$ERROR_CONTEXT"
  exit 1
fi

# Query logs later
query_logs "Phase.*complexity" "2025-10-20T00:00:00/2025-10-23T23:59:59"
```

**Log Location**: `.claude/data/logs/unified-logger.log`

**Rotation**: 10MB max, 5 files retained

---

## Error Handling Patterns

### Pattern A: Exit on Error (Strict Mode)

**Use Case**: Critical operations where failure must stop execution

```bash
# Enable strict error handling
set -euo pipefail

source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"

# Function fails → script exits immediately
LOCATION_JSON=$(perform_location_detection "$USER_INPUT")
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
```

### Pattern B: Graceful Degradation

**Use Case**: Optional features where failure shouldn't stop execution

```bash
source "${CLAUDE_CONFIG}/.claude/lib/workflow/metadata-extraction.sh"

# Try to extract metadata, use fallback if fails
if METADATA=$(extract_report_metadata "$REPORT_PATH" 2>/dev/null); then
  SUMMARY=$(echo "$METADATA" | jq -r '.summary')
else
  echo "WARNING: Could not extract metadata, using full report" >&2
  SUMMARY="(Full report content - metadata extraction failed)"
fi
```

### Pattern C: Retry with Fallback

**Use Case**: Network-dependent or flaky operations

```bash
source "${CLAUDE_CONFIG}/.claude/lib/# json-utils.sh (removed)"

# Try jq, fall back to sed parsing
if command -v jq &>/dev/null; then
  TOPIC_PATH=$(echo "$JSON" | jq -r '.topic_path')
else
  echo "WARNING: jq not found, using sed fallback (less robust)" >&2
  TOPIC_PATH=$(echo "$JSON" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
fi
```

### Pattern D: Standardized Error Handling

**Use Case**: Consistent error handling across commands

```bash
source "${CLAUDE_CONFIG}/.claude/lib/core/error-handling.sh"

# Function fails → standardized error handling with recovery
if ! create_topic_structure "$TOPIC_PATH"; then
  handle_error 1 "Failed to create topic structure: $TOPIC_PATH" \
    "rm -rf '$TOPIC_PATH'"  # Recovery: clean up partial creation
fi
```

---

## Handling jq Dependency

Many libraries return JSON for structured data. Handle jq dependency gracefully:

### Recommended Pattern

```bash
# Always check for jq and provide sed fallback
if command -v jq &>/dev/null; then
  # Preferred: Use jq (robust, readable)
  TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
  REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
else
  # Fallback: Use sed/grep (less robust, works without jq)
  TOPIC_PATH=$(echo "$LOCATION_JSON" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  REPORTS_DIR=$(echo "$LOCATION_JSON" | grep -o '"reports": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
fi
```

### When jq is Critical

If jq is required (complex nested JSON), fail with helpful message:

```bash
if ! command -v jq &>/dev/null; then
  echo "ERROR: This command requires jq for JSON parsing" >&2
  echo "Install: sudo apt-get install jq  # Debian/Ubuntu" >&2
  echo "Install: brew install jq          # macOS" >&2
  exit 1
fi
```

---

## Performance Characteristics

### Token Usage Comparison

| Approach | Token Usage | Example |
|----------|-------------|---------|
| **Agent invocation** | 15k-75k tokens | location-specialist agent: 75.6k |
| **Utility library** | 0 tokens | unified-location-detection.sh: 0 |
| **Savings** | 85-100% | 65k token reduction for /orchestrate |

### Execution Time Comparison

| Approach | Execution Time | Example |
|----------|---------------|---------|
| **Agent invocation** | 20-30s | location-specialist agent: 25.2s |
| **Utility library** | <1s | unified-location-detection.sh: <1s |
| **Speedup** | 20-30x | 25x faster for /orchestrate Phase 0 |

### When Performance Matters

**High-Frequency Operations**:
- Workflow initialization (every command invocation)
- Checkpoint saves (every phase completion)
- Log writes (continuous)

**Solution**: Always use libraries for these operations

**Low-Frequency Operations**:
- Codebase exploration (once per plan creation)
- Root cause analysis (rare, debug workflows only)

**Solution**: Agents acceptable (AI reasoning needed anyway)

---

## Testing Library Integration

### Unit Testing Libraries

Test library functions in isolation:

```bash
#!/usr/bin/env bash
# test_unified_location_detection.sh

source .claude/lib/core/unified-location-detection.sh

# Test 1: Topic name sanitization
test_sanitize_topic_name() {
  local result
  result=$(sanitize_topic_name "Research: OAuth 2.0 Patterns")

  if [ "$result" != "research_oauth_20_patterns" ]; then
    echo "FAIL: Expected 'research_oauth_20_patterns', got '$result'"
    return 1
  fi

  echo "PASS: Topic name sanitization"
  return 0
}

# Test 2: Location detection creates directories
test_location_detection() {
  local result
  result=$(perform_location_detection "test topic" "true")

  local topic_path
  topic_path=$(echo "$result" | jq -r '.topic_path')

  if [ ! -d "$topic_path" ]; then
    echo "FAIL: Topic directory not created: $topic_path"
    return 1
  fi

  echo "PASS: Location detection"
  rm -rf "$topic_path"  # Cleanup
  return 0
}

# Run tests
test_sanitize_topic_name || exit 1
test_location_detection || exit 1

echo "All tests passed"
```

### Integration Testing Commands

Test commands that use libraries:

```bash
#!/usr/bin/env bash
# test_report_command.sh

# Test 1: /report creates correct directory structure
test_report_directory_creation() {
  local result
  result=$(/report "test authentication patterns" 2>&1)

  # Verify reports directory created
  if ! echo "$result" | grep -q "specs/.*_test_authentication_patterns/reports"; then
    echo "FAIL: Report directory not created"
    return 1
  fi

  echo "PASS: /report directory creation"
  return 0
}

test_report_directory_creation || exit 1
```

---

## Troubleshooting

### Issue: "command not found" when sourcing library

**Cause**: Incorrect library path

**Solution**: Use absolute path from `CLAUDE_CONFIG`:
```bash
# Wrong
source unified-location-detection.sh

# Correct
source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"
```

### Issue: JSON parsing fails without jq

**Cause**: jq not installed, sed fallback not implemented

**Solution**: Add sed fallback pattern:
```bash
if command -v jq &>/dev/null; then
  TOPIC_PATH=$(echo "$JSON" | jq -r '.topic_path')
else
  TOPIC_PATH=$(echo "$JSON" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
fi
```

### Issue: Function returns empty string

**Cause**: Error suppressed by `2>/dev/null` or command substitution

**Solution**: Check exit code explicitly:
```bash
# Wrong (errors hidden)
RESULT=$(some_function "$ARG")

# Correct (errors visible)
if ! RESULT=$(some_function "$ARG"); then
  echo "ERROR: Function failed"
  exit 1
fi
```

### Issue: Directory verification fails after creation

**Cause**: Asynchronous I/O or filesystem delays

**Solution**: Add brief delay before verification:
```bash
create_topic_structure "$TOPIC_PATH" || exit 1

# Brief delay for filesystem sync (rare, but happens on network mounts)
sleep 0.1

if [ ! -d "$TOPIC_PATH" ]; then
  echo "ERROR: Directory not found after creation"
  exit 1
fi
```

---

## Best Practices

### 1. Always Verify Side Effects

Libraries that create files/directories MUST have verification checkpoints:

```bash
# Create directory
create_topic_structure "$TOPIC_PATH" || exit 1

# MANDATORY VERIFICATION
if [ ! -d "$TOPIC_PATH" ]; then
  echo "ERROR: Directory creation failed"
  exit 1
fi
```

### 2. Use Absolute Paths

Always use absolute paths for file operations:

```bash
# Wrong (relative path)
TOPIC_PATH="specs/082_auth"

# Correct (absolute path)
TOPIC_PATH="${CLAUDE_CONFIG}/.claude/specs/082_auth"
```

### 3. Provide jq Fallback

Always support environments without jq:

```bash
if command -v jq &>/dev/null; then
  # jq parsing
else
  # sed/grep fallback
fi
```

### 4. Log Library Usage

Log when libraries are invoked for audit trail:

```bash
source "${CLAUDE_CONFIG}/.claude/lib/core/unified-logger.sh"

log_info "Performing location detection for: $USER_INPUT"
LOCATION_JSON=$(perform_location_detection "$USER_INPUT")
log_info "Topic path: $(echo "$LOCATION_JSON" | jq -r '.topic_path')"
```

### 5. Test Library Integration

Every command using libraries MUST have integration tests:

```bash
# .claude/tests/test_command_integration.sh
test_report_uses_unified_location() {
  # Test that /report uses unified-location-detection.sh correctly
  # Verify: topic directory structure, numbering, sanitization
}
```

---

## Migration Guide: Ad-Hoc Logic → Unified Library

### Step 1: Identify Duplicated Logic

Search for ad-hoc implementations:

```bash
# Find topic sanitization logic
grep -r "tr '[:upper:]' '[:lower:]'" .claude/commands/

# Find topic numbering logic
grep -r "ls -1d.*[0-9][0-9][0-9]_" .claude/commands/
```

### Step 2: Replace with Library Calls

**Before**:
```bash
TOPIC_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
MAX_NUM=$(ls -1d specs/[0-9][0-9][0-9]_* | sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | sort -n | tail -1)
TOPIC_PATH="specs/${MAX_NUM}_${TOPIC_NAME}"
mkdir -p "$TOPIC_PATH"/{reports,plans}
```

**After**:
```bash
source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"
LOCATION_JSON=$(perform_location_detection "$1")
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
```

### Step 3: Add Verification Checkpoint

```bash
if [ ! -d "$TOPIC_PATH" ]; then
  echo "ERROR: Location detection failed"
  exit 1
fi
```

### Step 4: Test Migration

```bash
# Run existing command tests
./.claude/tests/test_report_command.sh

# Run new integration tests
./.claude/tests/test_system_wide_location.sh
```

### Step 5: Create Backup

```bash
# Backup before migration
cp .claude/commands/report.md .claude/commands/report.md.backup-migration
```

---

## See Also

- [Library API Reference](../reference/library-api/overview.md) - Complete function signatures and return formats
- [Command Development Guide](command-development/command-development-fundamentals.md) - Creating commands with libraries
- [Skills vs Subagents Decision Guide](skills-vs-subagents-decision.md) - When to use libraries vs agents
- [Performance Measurement](performance-optimization.md) - Measuring library performance impact
- [Testing Patterns](testing-patterns.md) - Testing library integration
