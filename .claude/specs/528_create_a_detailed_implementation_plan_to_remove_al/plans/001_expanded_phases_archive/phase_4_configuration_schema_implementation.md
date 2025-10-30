# Phase 4: Configuration Schema Implementation

## Phase Metadata
- **Phase Number**: 4
- **Dependencies**: Phase 3 (Location Library Consolidation)
- **Complexity**: High (9.5/10)
- **Estimated Duration**: 6-8 hours
- **Risk Level**: Medium-High

## Objective

Implement centralized JSON configuration system and standardize function signatures across all claude-config.sh operations. This phase establishes the foundational configuration layer that eliminates hardcoded values, enables environment-based overrides, and provides consistent error handling patterns.

**Core Goals**:
1. Create .claude/config.json schema with complete field documentation
2. Implement JSON parsing with jq in claude-config.sh initialization
3. Migrate all hardcoded values from libraries to centralized configuration
4. Standardize function signatures with consistent error codes and fail-fast validation
5. Integrate with error-handling.sh for proper error classification

## Architecture Design

### Configuration Schema Structure

The .claude/config.json file follows a hierarchical organization:

```json
{
  "version": "1.0.0",
  "project": {
    "name": "Claude Code",
    "root": "${CLAUDE_PROJECT_DIR}",
    "specs_location": ".claude/specs",
    "legacy_specs_location": "specs"
  },
  "artifacts": {
    "types": [
      "debug",
      "scripts",
      "outputs",
      "artifacts",
      "backups",
      "data",
      "logs",
      "notes",
      "reports",
      "plans"
    ],
    "gitignore_policy": {
      "committed": ["debug"],
      "ignored": [
        "scripts",
        "outputs",
        "artifacts",
        "backups",
        "data",
        "logs",
        "notes",
        "reports",
        "plans"
      ]
    }
  },
  "naming_conventions": {
    "topic_number_format": "[0-9]{3}",
    "topic_number_regex": "^[0-9][0-9][0-9]$",
    "max_topic_name_length": 50,
    "topic_name_pattern": "^[a-z0-9_]+$",
    "artifact_naming": "{number}_{name}.{ext}",
    "artifact_number_format": "[0-9]{3}"
  },
  "error_handling": {
    "exit_codes": {
      "success": 0,
      "transient": 2,
      "permanent": 3,
      "fatal": 4
    },
    "retry_policy": {
      "max_retries": 3,
      "backoff_multiplier": 2,
      "initial_delay_seconds": 1
    },
    "fail_fast": true,
    "validation_mode": "strict"
  },
  "environment_overrides": {
    "CLAUDE_PROJECT_DIR": "Absolute path to project root",
    "CLAUDE_SPECS_ROOT": "Absolute path to specs directory",
    "CLAUDE_CONFIG_FILE": "Path to alternative config.json",
    "CLAUDE_VALIDATION_MODE": "strict|lenient",
    "CLAUDE_FAIL_FAST": "true|false"
  },
  "verification_checkpoints": {
    "directory_creation": true,
    "file_creation": true,
    "configuration_loading": true,
    "path_resolution": true
  }
}
```

### Schema Field Documentation

**Version Control** (`version`):
- Semantic versioning for config schema
- Used for migration validation
- Breaking changes increment major version

**Project Configuration** (`project`):
- `name`: Project display name
- `root`: Project root path (supports `${VARIABLE}` interpolation)
- `specs_location`: Primary specs directory (.claude/specs preferred)
- `legacy_specs_location`: Fallback for legacy projects

**Artifact Management** (`artifacts`):
- `types`: Exhaustive list of valid artifact types
- `gitignore_policy`: Separates committed vs ignored artifacts
- Used by artifact-creation.sh for validation

**Naming Conventions** (`naming_conventions`):
- `topic_number_format`: POSIX regex for topic numbers (NNN)
- `topic_number_regex`: Strict validation pattern
- `max_topic_name_length`: Enforced during sanitization (50 chars)
- `topic_name_pattern`: Valid characters for sanitized names
- `artifact_naming`: Template for artifact file names

**Error Handling** (`error_handling`):
- `exit_codes`: Standard codes for error classification
  - 0: Success
  - 2: Transient (retry possible)
  - 3: Permanent (code fix required)
  - 4: Fatal (system-level issue)
- `retry_policy`: Exponential backoff configuration
- `fail_fast`: Disable graceful degradation (strict mode)
- `validation_mode`: strict (default) or lenient (testing)

**Environment Overrides** (`environment_overrides`):
- Documents all supported environment variables
- Values in this section are for documentation only
- Actual override logic implemented in claude-config.sh

**Verification Checkpoints** (`verification_checkpoints`):
- Enables/disables mandatory verification after operations
- Follows Verification and Fallback pattern from CLAUDE.md
- All checkpoints enabled by default (production safety)

## Implementation Tasks

### Task Group 1: Schema Creation and Validation (2 hours)

- [ ] Create .claude/config.json with complete schema (see Architecture Design above)
- [ ] Validate JSON syntax with jq: `jq empty .claude/config.json`
- [ ] Document each field in inline comments (if jq supports) or separate schema.md
- [ ] Create validation function `validate_config_schema()` in claude-config.sh:
  - Check required fields exist (version, project.root, artifacts.types)
  - Validate field types (strings, arrays, objects, booleans)
  - Verify exit codes are integers in range [0-255]
  - Ensure artifact types list is non-empty
  - Validate regex patterns are valid POSIX extended regex
- [ ] Test schema validation with intentionally malformed configs
- [ ] Add schema version check (current version: 1.0.0)
- [ ] Create migration path for future schema changes

**Validation Function Specification**:
```bash
# validate_config_schema()
# Purpose: Validate .claude/config.json structure and values
# Arguments: None (reads from $CONFIG_FILE global)
# Returns: 0 if valid, 3 if invalid (permanent error)
# Side Effects: Logs validation errors to stderr
#
# Validation Checks:
#   1. JSON syntax valid (jq parse succeeds)
#   2. Required fields present (version, project, artifacts, error_handling)
#   3. Field types correct (strings, integers, arrays as expected)
#   4. Exit codes in valid range (0-255)
#   5. Artifact types list non-empty
#   6. Regex patterns compile successfully
#
# Example:
#   CONFIG_FILE=".claude/config.json"
#   validate_config_schema || exit 3
validate_config_schema() {
  # Implementation goes here
}
```

### Task Group 2: JSON Parsing Integration (1.5 hours)

- [ ] Add jq dependency check to claude-config.sh initialization:
  - Check if jq is available: `command -v jq >/dev/null`
  - If missing, exit with EXIT_FATAL (4) and error message
  - Document jq as required dependency in library header
- [ ] Implement configuration loading function `load_configuration()`:
  - Locate config file (precedence: $CLAUDE_CONFIG_FILE > .claude/config.json)
  - Validate schema with `validate_config_schema()`
  - Parse JSON with jq
  - Export configuration to global variables
  - Handle variable interpolation (${CLAUDE_PROJECT_DIR})
- [ ] Export configuration to environment:
  - `CLAUDE_ARTIFACT_TYPES` (array exported as space-separated string)
  - `CLAUDE_TOPIC_NUMBER_REGEX`
  - `CLAUDE_MAX_TOPIC_NAME_LENGTH`
  - `CLAUDE_EXIT_SUCCESS`, `CLAUDE_EXIT_TRANSIENT`, `CLAUDE_EXIT_PERMANENT`, `CLAUDE_EXIT_FATAL`
  - `CLAUDE_FAIL_FAST` (boolean as "true"/"false")
  - `CLAUDE_VALIDATION_MODE` ("strict"/"lenient")
- [ ] Test configuration loading with various scenarios:
  - Default config.json
  - Custom config via CLAUDE_CONFIG_FILE
  - Missing config.json (should create default)
  - Malformed JSON (should fail with EXIT_FATAL)

**Configuration Loading Specification**:
```bash
# load_configuration()
# Purpose: Load and parse .claude/config.json
# Arguments: None
# Returns: 0 on success, 4 on fatal error
# Side Effects: Exports configuration to global variables
#
# Precedence:
#   1. $CLAUDE_CONFIG_FILE (manual override)
#   2. ${PROJECT_ROOT}/.claude/config.json (default)
#   3. Create default config if missing (only in lenient mode)
#
# Example:
#   load_configuration || exit $?
#   echo "Exit codes: $CLAUDE_EXIT_SUCCESS, $CLAUDE_EXIT_TRANSIENT"
load_configuration() {
  # Implementation goes here
}
```

<!-- PROGRESS CHECKPOINT -->
After completing Task Groups 1-2:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
- [ ] Run: `source .claude/lib/claude-config.sh && load_configuration && validate_config_schema`
- [ ] Expected: No errors, configuration exported to environment
<!-- END PROGRESS CHECKPOINT -->

### Task Group 3: Hardcoded Value Migration (2 hours)

- [ ] **Migrate artifact types from artifact-creation.sh**:
  - Current location: artifact-creation.sh lines 30-32 (case statement)
  - New pattern: Read from `$CLAUDE_ARTIFACT_TYPES` environment variable
  - Update validation logic to use config array instead of hardcoded case
  - Test: Verify all 10 artifact types still validated correctly
- [ ] **Migrate topic number format from topic-utils.sh**:
  - Current location: topic-utils.sh lines 22-25 (sed pattern `[0-9][0-9][0-9]`)
  - New pattern: Use `$CLAUDE_TOPIC_NUMBER_REGEX` for validation
  - Update `get_next_topic_number()` to use config regex
  - Test: Verify topic number generation still works (001, 002, ...)
- [ ] **Migrate max topic name length**:
  - Current location: topic-utils.sh line 54 (`cut -c1-50`)
  - New pattern: Use `$CLAUDE_MAX_TOPIC_NAME_LENGTH`
  - Update `sanitize_topic_name()` function
  - Test: Verify long topic names truncated to config limit
- [ ] **Migrate specs directory locations**:
  - Current location: unified-location-detection.sh lines 91-99
  - New pattern: Read from `project.specs_location` and `project.legacy_specs_location`
  - Update `detect_specs_directory()` function
  - Test: Verify .claude/specs preferred over specs/
- [ ] **Migrate error exit codes**:
  - Current location: error-handling.sh (implicit codes 0/2/3/4)
  - New pattern: Use named constants from config
  - Update all functions returning exit codes
  - Test: Verify error classification matches config codes
- [ ] Document migration in CHANGELOG.md:
  - List all migrated values
  - Show before/after code examples
  - Note breaking changes (if any)

**Migration Pattern Example**:

Before (artifact-creation.sh):
```bash
case "$artifact_type" in
  debug|scripts|outputs|artifacts|backups|data|logs|notes|reports|plans)
    ;;
  *)
    echo "Error: Invalid artifact type '$artifact_type'" >&2
    return 1
    ;;
esac
```

After (using config):
```bash
# Load valid artifact types from configuration
IFS=' ' read -ra VALID_TYPES <<< "$CLAUDE_ARTIFACT_TYPES"

# Validate artifact type against config
local valid=false
for type in "${VALID_TYPES[@]}"; do
  if [ "$artifact_type" = "$type" ]; then
    valid=true
    break
  fi
done

if [ "$valid" = "false" ]; then
  echo "Error: Invalid artifact type '$artifact_type'" >&2
  echo "Valid types: $CLAUDE_ARTIFACT_TYPES" >&2
  return $CLAUDE_EXIT_PERMANENT
fi
```

### Task Group 4: Environment Variable Override System (1.5 hours)

- [ ] Implement override precedence logic in `load_configuration()`:
  - 1st priority: Environment variables (CLAUDE_PROJECT_DIR, etc.)
  - 2nd priority: config.json values
  - 3rd priority: Hardcoded defaults (fail-safe values)
- [ ] Add support for these overrides:
  - `CLAUDE_PROJECT_DIR`: Override project root detection
  - `CLAUDE_SPECS_ROOT`: Override specs directory location
  - `CLAUDE_CONFIG_FILE`: Use alternative config.json
  - `CLAUDE_VALIDATION_MODE`: Override strict/lenient mode
  - `CLAUDE_FAIL_FAST`: Override fail-fast behavior
- [ ] Document override behavior in function docstrings
- [ ] Test all override scenarios:
  - Override project root: `CLAUDE_PROJECT_DIR=/tmp/test source claude-config.sh`
  - Override config file: `CLAUDE_CONFIG_FILE=/custom/config.json source claude-config.sh`
  - Override validation mode: `CLAUDE_VALIDATION_MODE=lenient source claude-config.sh`
  - Mixed overrides: Multiple environment variables at once
- [ ] Create test script: `.claude/tests/test_config_overrides.sh`

**Override Implementation Pattern**:
```bash
# In load_configuration()

# 1. Load config.json values
local config_project_root=$(jq -r '.project.root' "$CONFIG_FILE")

# 2. Apply environment variable overrides (highest priority)
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
elif [ -n "$config_project_root" ]; then
  # Handle variable interpolation
  PROJECT_ROOT=$(eval echo "$config_project_root")
else
  # Fallback default (fail-safe)
  PROJECT_ROOT=$(pwd)
fi

# 3. Export for downstream use
export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"
```

<!-- PROGRESS CHECKPOINT -->
After completing Task Groups 3-4:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
- [ ] Run: `.claude/tests/test_config_overrides.sh`
- [ ] Expected: All override tests pass
<!-- END PROGRESS CHECKPOINT -->

### Task Group 5: Function Signature Standardization (2 hours)

- [ ] **Standardize return values**: All path functions return absolute paths to stdout
  - Update `detect_project_root()`: Already returns to stdout ✓
  - Update `detect_specs_directory()`: Already returns to stdout ✓
  - Update `get_next_topic_number()`: Returns to stdout ✓
  - Update `sanitize_topic_name()`: Returns to stdout ✓
  - Update `create_topic_structure()`: Returns 0/1 (no stdout) ✓
  - Verify consistency: No functions mix stdout and return codes
- [ ] **Standardize error codes**: Use config constants instead of literals
  - Replace `return 1` → `return $CLAUDE_EXIT_PERMANENT`
  - Replace `exit 1` → `exit $CLAUDE_EXIT_FATAL`
  - Add transient error returns where appropriate (retry-able failures)
  - Document error codes in function docstrings
- [ ] **Implement strict argument validation**:
  - All functions check required arguments are non-empty
  - Invalid arguments fail immediately (no silent fallbacks)
  - Use `[ -z "$arg" ]` checks at function start
  - Return $CLAUDE_EXIT_PERMANENT for invalid arguments
- [ ] **Apply `set -euo pipefail` error mode**:
  - Add to top of claude-config.sh (after shebang and comments)
  - Remove compatibility relaxations (no `set +e` patterns)
  - Test with intentional errors to verify immediate failure
- [ ] Update all function docstrings to document:
  - Arguments (required/optional, type, validation rules)
  - Return values (stdout vs return code)
  - Exit codes (all possible codes with meanings)
  - Side effects (environment variables, file creation)

**Standardized Function Template**:
```bash
# function_name(arg1, arg2)
# Purpose: Brief description of what function does
# Arguments:
#   $1: arg1 - Description (required, string, non-empty)
#   $2: arg2 - Description (optional, integer, default: 0)
# Returns: Description of stdout output
# Exit Codes:
#   0 (CLAUDE_EXIT_SUCCESS): Success
#   2 (CLAUDE_EXIT_TRANSIENT): Transient failure (retry possible)
#   3 (CLAUDE_EXIT_PERMANENT): Permanent failure (code fix required)
#   4 (CLAUDE_EXIT_FATAL): Fatal system error
# Side Effects: List any file creation, environment changes, etc.
#
# Example:
#   result=$(function_name "value1" 42) || exit $?
#   echo "Result: $result"
function_name() {
  local arg1="${1:-}"
  local arg2="${2:-0}"

  # Strict argument validation (fail fast)
  if [ -z "$arg1" ]; then
    echo "ERROR: arg1 is required" >&2
    return $CLAUDE_EXIT_PERMANENT
  fi

  # Function implementation
  # ...

  # Return result to stdout
  echo "$result"
  return $CLAUDE_EXIT_SUCCESS
}
```

### Task Group 6: Verification Checkpoints (1 hour)

- [ ] Add verification checkpoints to directory creation operations:
  - `create_topic_structure()`: Verify directory exists after mkdir
  - `ensure_artifact_directory()`: Verify directory created successfully
  - Add fallback creation attempts (retry with alternative methods)
- [ ] Implement checkpoint verification pattern:
  - After directory creation: `[ -d "$dir" ] || fallback_create "$dir"`
  - After file creation: `[ -f "$file" ] || fallback_write "$file"`
  - Final verification: Fail with EXIT_FATAL if fallback also fails
- [ ] Add logging to verification checkpoints:
  - Success: "✓ CHECKPOINT VERIFIED: Directory created at $path"
  - Fallback: "⚠ CHECKPOINT FALLBACK: Retrying with alternative method"
  - Failure: "✗ CHECKPOINT FAILED: Unable to create directory after fallback"
- [ ] Test checkpoint failure scenarios:
  - Read-only filesystem: `mount -o ro /tmp/test`
  - Insufficient permissions: `chmod 000 /tmp/test`
  - Disk full simulation: Create large files until space exhausted

**Verification Checkpoint Pattern**:
```bash
# Create directory with mandatory verification
mkdir -p "$topic_path"

# CHECKPOINT: Verify with fallback
if [ ! -d "$topic_path" ]; then
  # Fallback: Try alternative creation method
  mkdir "$topic_path" 2>/dev/null || mkdir -m 755 "$topic_path"

  # Final verification (no more fallbacks)
  if [ ! -d "$topic_path" ]; then
    echo "✗ CHECKPOINT FAILED: Unable to create directory: $topic_path" >&2
    echo "FATAL: Directory creation failed after fallback" >&2
    return $CLAUDE_EXIT_FATAL
  fi

  echo "⚠ CHECKPOINT FALLBACK: Created directory with alternative method" >&2
fi

echo "✓ CHECKPOINT VERIFIED: Directory created at $topic_path" >&2
return $CLAUDE_EXIT_SUCCESS
```

### Task Group 7: error-handling.sh Integration (1 hour)

- [ ] Import error-handling.sh in claude-config.sh header:
  - Add: `source "${SCRIPT_DIR}/error-handling.sh"`
  - Verify error-handling.sh exports required functions
- [ ] Use `classify_error()` for error classification:
  - Wrap critical operations in error detection
  - Classify errors based on message content
  - Return appropriate exit codes based on classification
- [ ] Use `suggest_recovery()` for error messages:
  - Provide actionable recovery suggestions
  - Include suggestions in error output to stderr
- [ ] Implement retry logic for transient errors:
  - Use config values: `retry_policy.max_retries`, `retry_policy.backoff_multiplier`
  - Retry only for CLAUDE_EXIT_TRANSIENT errors
  - Exponential backoff between retries
- [ ] Test error handling integration:
  - Trigger transient error (e.g., locked file)
  - Verify retry behavior (should retry 3 times with backoff)
  - Trigger permanent error (e.g., invalid config)
  - Verify immediate failure (no retry)

**Error Classification Integration Example**:
```bash
# Attempt operation with error classification
error_output=$(create_topic_structure "$topic_path" 2>&1)
exit_code=$?

if [ $exit_code -ne 0 ]; then
  # Classify the error
  error_type=$(classify_error "$error_output")

  case "$error_type" in
    "transient")
      echo "Transient error detected: $error_output" >&2
      echo "Recovery: $(suggest_recovery "$error_type" "$error_output")" >&2
      return $CLAUDE_EXIT_TRANSIENT
      ;;
    "permanent")
      echo "Permanent error detected: $error_output" >&2
      echo "Recovery: $(suggest_recovery "$error_type" "$error_output")" >&2
      return $CLAUDE_EXIT_PERMANENT
      ;;
    "fatal")
      echo "Fatal error detected: $error_output" >&2
      echo "Recovery: $(suggest_recovery "$error_type" "$error_output")" >&2
      return $CLAUDE_EXIT_FATAL
      ;;
  esac
fi
```

<!-- PROGRESS CHECKPOINT -->
After completing Task Groups 5-7:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
- [ ] Run: `.claude/tests/run_all_tests.sh`
- [ ] Expected: Test passing rate ≥ baseline (58/77 minimum)
<!-- END PROGRESS CHECKPOINT -->

## Testing Strategy

### Unit Tests (test_config_system.sh)

Create comprehensive unit tests for configuration system:

```bash
#!/usr/bin/env bash
# test_config_system.sh - Unit tests for configuration system

test_config_schema_validation() {
  # Test 1: Valid config passes validation
  source .claude/lib/claude-config.sh
  load_configuration
  validate_config_schema
  assert_exit_code 0 "Valid config should pass validation"

  # Test 2: Missing required field fails validation
  local temp_config=$(mktemp)
  echo '{"version": "1.0.0"}' > "$temp_config"
  CLAUDE_CONFIG_FILE="$temp_config" load_configuration
  ! validate_config_schema
  assert_exit_code 3 "Missing required fields should fail"
  rm "$temp_config"

  # Test 3: Invalid JSON syntax fails
  echo '{invalid json}' > "$temp_config"
  ! CLAUDE_CONFIG_FILE="$temp_config" load_configuration
  assert_exit_code 4 "Invalid JSON should fail fatally"
  rm "$temp_config"
}

test_environment_overrides() {
  # Test override precedence
  CLAUDE_PROJECT_DIR="/tmp/override" load_configuration
  assert_equals "/tmp/override" "$CLAUDE_PROJECT_DIR"

  CLAUDE_VALIDATION_MODE="lenient" load_configuration
  assert_equals "lenient" "$CLAUDE_VALIDATION_MODE"
}

test_hardcoded_value_migration() {
  # Test artifact type validation uses config
  load_configuration
  local valid_types=($CLAUDE_ARTIFACT_TYPES)
  assert_contains "debug" "${valid_types[@]}"
  assert_contains "reports" "${valid_types[@]}"
  assert_equals 10 "${#valid_types[@]}" "Should have 10 artifact types"
}

test_error_code_standardization() {
  # Test functions return config error codes
  load_configuration

  # Success case
  result=$(detect_project_root)
  assert_exit_code 0 "Success should return CLAUDE_EXIT_SUCCESS"

  # Permanent error case (invalid argument)
  ! detect_specs_directory ""
  assert_exit_code 3 "Invalid argument should return CLAUDE_EXIT_PERMANENT"
}

# Run all tests
run_all_tests
```

### Integration Tests

- [ ] Test configuration loading in real command workflows:
  - Run `/plan` command with custom config
  - Run `/research` command with environment overrides
  - Verify all commands respect configuration settings
- [ ] Test error handling integration:
  - Trigger transient errors (retry should work)
  - Trigger permanent errors (should fail immediately)
  - Verify error messages include recovery suggestions
- [ ] Test verification checkpoints:
  - Create directories in read-only filesystem (should fail gracefully)
  - Test fallback creation methods
  - Verify logging output matches expected format

### Regression Tests

- [ ] Ensure baseline test suite still passes:
  - Run: `.claude/tests/run_all_tests.sh`
  - Baseline: 58/77 tests passing (75%)
  - Target: ≥58/77 after Phase 4 changes
- [ ] Verify no breaking changes to existing functions:
  - All functions maintain backward-compatible signatures
  - Return values unchanged (stdout vs return codes)
  - Error codes may change (document in CHANGELOG)

## Rollback Procedures

### Immediate Rollback (if tests fail)

```bash
# Identify last working commit
git log --oneline -5

# Revert Phase 4 commits
git revert <phase-4-start-commit>^..<latest-commit>

# Verify rollback
cd .claude/tests && ./run_all_tests.sh
# Expected: Tests return to baseline (58/77 passing)

# Remove config.json if created
rm -f .claude/config.json

# Document rollback reason
echo "Phase 4 rollback: [reason]" >> .claude/data/logs/migration.log
```

### Partial Rollback (specific task group)

If only one task group causes issues:

```bash
# Rollback specific task group commit
git log --oneline | grep "Task Group"
git revert <task-group-commit>

# Re-run tests
./run_all_tests.sh

# If successful, continue with remaining task groups
# If failure persists, perform full rollback
```

## Success Criteria

### Primary Success Criteria

- [ ] .claude/config.json created and validated successfully
- [ ] All hardcoded values migrated to config.json (artifact types, naming conventions, error codes, specs locations)
- [ ] JSON parsing integrated into claude-config.sh initialization
- [ ] Environment variable overrides working correctly (5 variables tested)
- [ ] Function signatures standardized (consistent return values, error codes, argument validation)
- [ ] Verification checkpoints added to all directory creation operations
- [ ] error-handling.sh integration complete (error classification, retry logic, recovery suggestions)
- [ ] Test suite passing at ≥baseline rate (58/77 minimum)
- [ ] No production errors during 7-14 day verification window

### Secondary Success Criteria

- [ ] Configuration schema documented with inline comments or separate schema.md
- [ ] Migration documented in CHANGELOG.md with before/after examples
- [ ] Unit test suite created (test_config_system.sh with ≥15 tests)
- [ ] Integration tests passing (configuration in real command workflows)
- [ ] Rollback procedures tested and validated

### Quality Metrics

- [ ] Code coverage ≥80% for new configuration code
- [ ] Zero hardcoded values remain in claude-config.sh (all values from config.json)
- [ ] All functions have complete docstrings (arguments, return values, exit codes, side effects)
- [ ] Error messages actionable (include recovery suggestions)

## Phase Completion Checklist

**MANDATORY STEPS AFTER ALL PHASE TASKS COMPLETE**:

- [ ] **Mark all phase tasks as [x]** in this file
- [ ] **Update parent plan** with phase completion status
  - Use spec-updater: `mark_phase_complete` function
  - Verify hierarchy synchronization
- [ ] **Run full test suite**: `.claude/tests/run_all_tests.sh`
  - Verify all tests passing (≥58/77 baseline)
  - Debug failures before proceeding
- [ ] **Create git commit** with standardized message
  - Format: `feat(528): complete Phase 4 - Configuration Schema Implementation`
  - Include files modified in this phase:
    - .claude/config.json (new)
    - .claude/lib/claude-config.sh (modified)
    - .claude/lib/artifact-creation.sh (modified)
    - .claude/lib/topic-utils.sh (modified)
    - .claude/tests/test_config_system.sh (new)
  - Verify commit created successfully
- [ ] **Create checkpoint**: Save progress to `.claude/data/checkpoints/`
  - Include: Plan path, phase number 4, completion status
  - Timestamp: ISO 8601 format
- [ ] **Invoke spec-updater**: Update cross-references and summaries
  - Verify bidirectional links intact
  - Update plan metadata with completion timestamp
- [ ] **Begin 7-14 day verification window**:
  - Monitor test suite daily
  - Check for production errors
  - Document any issues in migration.log
  - If issues arise, execute rollback procedures

## Notes

### Configuration Design Rationale

**Why JSON over YAML/TOML**:
- jq is ubiquitous in bash environments
- JSON parsing is simpler and faster than YAML
- No additional dependencies required
- Standard format for data interchange

**Why Centralized Config**:
- Eliminates duplicate hardcoded values across 5+ libraries
- Enables environment-based overrides (dev/staging/prod)
- Facilitates testing (swap config files easily)
- Provides single source of truth for system behavior

**Why Fail-Fast Validation**:
- Catches configuration errors at startup (not during execution)
- Prevents silent failures and data corruption
- Aligns with Development Philosophy (quality over backward compatibility)
- Simplifies debugging (errors are immediate and obvious)

### Integration with Existing Patterns

This phase implements patterns documented in CLAUDE.md:

- **Verification and Fallback Pattern**: Mandatory checkpoints after directory creation
- **Checkpoint Recovery Pattern**: State preservation for resumable workflows
- **Error Handling Guidelines**: Standard exit codes and error classification
- **Development Philosophy**: Fail-fast over graceful degradation

### Future Enhancements

Post-Phase 4 improvements to consider:

- Configuration versioning and migration system
- Per-user config overrides (~/.claude/config.json)
- Configuration validation at runtime (not just startup)
- Hot-reload configuration without restarting
- Configuration telemetry (track which values are actually used)
