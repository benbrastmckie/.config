# Deprecated Tests Analysis Report

**Created**: 2025-11-22
**Research Focus**: Identify tests, libraries, and agents that should be removed

## Executive Summary

The `.claude/tests/topic-naming/` directory contains multiple tests for `sanitize_topic_name()` functionality that was deprecated in favor of LLM-based naming with the `topic-naming-agent`. These tests are either:
1. **Broken** - Due to incorrect path resolution (`PROJECT_ROOT/.claude/lib` which becomes `.claude/.claude/lib`)
2. **Testing deprecated functionality** - Testing `sanitize_topic_name()` with enhanced features that were never implemented in the actual library
3. **No longer used in production** - The feature has been replaced by LLM-based naming

---

## Core Findings

### 1. Deprecated Functionality: `sanitize_topic_name()`

**Current State in Libraries**:

| Library | Function Status | Notes |
|---------|----------------|-------|
| `lib/plan/topic-utils.sh` | **NO `sanitize_topic_name()`** | Only has `validate_topic_name_format()`, `get_next_topic_number()`, etc. |
| `lib/core/unified-location-detection.sh:364` | **Basic fallback only** | Simple sanitization: lowercase, underscores, remove special chars, truncate to 50 chars |

**The Problem**: Tests in `tests/topic-naming/` reference an **enhanced `sanitize_topic_name()`** function with:
- Artifact reference stripping (`strip_artifact_references()`)
- Extended stopword filtering
- Reduced length limit (35 chars)
- Planning term filtering

**These features were NEVER implemented** in the actual library. The tests were written for a planned feature that was replaced by the LLM-based `topic-naming-agent`.

### 2. Broken Path Resolution

All tests in `tests/topic-naming/` use this pattern:
```bash
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/.claude/lib/plan/topic-utils.sh"
```

When run from `.claude/tests/topic-naming/`:
- `$SCRIPT_DIR` = `.claude/tests/topic-naming`
- `$PROJECT_ROOT` = `.claude` (goes up 2 levels)
- Path attempted: `.claude/.claude/lib/plan/topic-utils.sh` **DOES NOT EXIST**

**All tests in this directory fail with "Cannot load topic-utils library"**

### 3. Current Topic Naming Architecture

The current system uses:

1. **Topic Naming Agent** (`.claude/agents/topic-naming-agent.md`)
   - Haiku LLM-based semantic name generation
   - Writes name to temp file, returns `TOPIC_NAME_GENERATED:` signal

2. **Fallback to `no_name_error`**
   - If agent fails, commands use literal `no_name_error` as topic name
   - Error logged to centralized error log

3. **Validation via `validate_topic_name_format()`**
   - Located in `lib/plan/topic-utils.sh`
   - Validates format: `^[a-z0-9_]{5,40}$`, no consecutive underscores

---

## Tests Recommended for Removal

### Category A: Tests for Deprecated `sanitize_topic_name()` Features

These tests test enhanced `sanitize_topic_name()` functionality that was never implemented:

| Test File | Issue | Recommendation |
|-----------|-------|----------------|
| `test_topic_name_sanitization.sh` | Tests `sanitize_topic_name()` and `strip_artifact_references()` - neither exists in topic-utils.sh | **REMOVE** |
| `test_topic_naming.sh` | Tests enhanced stopword removal, path extraction, length limits - not implemented | **REMOVE** |
| `test_directory_naming_integration.sh` | Tests `sanitize_topic_name()` + `create_topic_structure()` integration | **REMOVE** |
| `test_semantic_slug_commands.sh` | Tests `sanitize_topic_name()` from unified-location-detection.sh (wrong library) | **REMOVE** |

### Category B: Tests with Broken Path Resolution

These tests have correct logic but broken paths:

| Test File | Issue | Recommendation |
|-----------|-------|----------------|
| `test_topic_naming_agent.sh` | Path bug, but tests `validate_topic_name_format()` - **FIX PATH** | **FIX** (path correction) |
| `test_topic_naming_fallback.sh` | Path bug, but tests `validate_topic_name_format()` boundary conditions | **FIX** (path correction) |
| `test_topic_naming_integration.sh` | Path bug, but tests agent file structure and integration | **FIX** (path correction) |

### Category C: Tests That Should Be Retained (After Fixes)

| Test File | Current Status | After Fix |
|-----------|----------------|-----------|
| `test_topic_naming_agent.sh` | Broken path | Tests `validate_topic_name_format()` - valuable |
| `test_topic_naming_fallback.sh` | Broken path | Tests format validation edge cases - valuable |
| `test_topic_naming_integration.sh` | Broken path | Tests agent file structure - valuable |
| `test_atomic_topic_allocation.sh` | Unknown status | Likely uses correct library functions |
| `test_topic_slug_validation.sh` | Unknown status | Likely tests `validate_topic_name_format()` |
| `test_command_topic_allocation.sh` | Unknown status | Tests topic number allocation |
| `test_topic_filename_generation.sh` | Unknown status | Tests filename generation |

---

## Libraries Assessment

### Functions That Can Be Removed

**No library code needs removal.** The deprecated functionality (`sanitize_topic_name()`) in `unified-location-detection.sh` is:
1. Still used as a fallback in `perform_location_detection()`
2. Intentionally kept simple (not the enhanced version in tests)

### Functions That Are Current and Used

| Function | Library | Status |
|----------|---------|--------|
| `validate_topic_name_format()` | `lib/plan/topic-utils.sh` | **CURRENT** - used by commands to validate agent output |
| `get_next_topic_number()` | `lib/plan/topic-utils.sh` | **CURRENT** - used for topic allocation |
| `get_or_create_topic_number()` | `lib/plan/topic-utils.sh` | **CURRENT** - idempotent allocation |
| `create_topic_structure()` | `lib/plan/topic-utils.sh` | **CURRENT** - topic directory creation |
| `sanitize_topic_name()` | `lib/core/unified-location-detection.sh` | **FALLBACK ONLY** - simple sanitization |

---

## Agent Assessment

**No agents should be removed.** The `topic-naming-agent.md` is the current production system.

---

## Recommended Actions

### Phase 1: Remove Deprecated Tests (4 files)

```bash
# Tests for never-implemented features
rm tests/topic-naming/test_topic_name_sanitization.sh
rm tests/topic-naming/test_topic_naming.sh
rm tests/topic-naming/test_directory_naming_integration.sh
rm tests/topic-naming/test_semantic_slug_commands.sh
```

### Phase 2: Fix Path Resolution (3 files)

In these files, change:
```bash
# FROM (incorrect)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/.claude/lib/plan/topic-utils.sh"

# TO (correct)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/lib/plan/topic-utils.sh"
# OR
CLAUDE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$CLAUDE_DIR/lib/plan/topic-utils.sh"
```

Files to fix:
- `test_topic_naming_agent.sh`
- `test_topic_naming_fallback.sh`
- `test_topic_naming_integration.sh`

### Phase 3: Audit Remaining Tests

Review these files for path issues and relevance:
- `test_atomic_topic_allocation.sh`
- `test_topic_slug_validation.sh`
- `test_command_topic_allocation.sh`
- `test_topic_filename_generation.sh`

---

## Summary Table

| Item | Type | Action | Priority |
|------|------|--------|----------|
| `test_topic_name_sanitization.sh` | Test | REMOVE | High |
| `test_topic_naming.sh` | Test | REMOVE | High |
| `test_directory_naming_integration.sh` | Test | REMOVE | High |
| `test_semantic_slug_commands.sh` | Test | REMOVE | High |
| `test_topic_naming_agent.sh` | Test | FIX PATH | Medium |
| `test_topic_naming_fallback.sh` | Test | FIX PATH | Medium |
| `test_topic_naming_integration.sh` | Test | FIX PATH | Medium |
| `sanitize_topic_name()` | Library | RETAIN (fallback) | N/A |
| `topic-naming-agent.md` | Agent | RETAIN (current) | N/A |

---

## Conclusion

The `.claude/tests/topic-naming/` directory contains tests written for an enhanced `sanitize_topic_name()` implementation that was planned but replaced by the LLM-based `topic-naming-agent`. These tests:

1. **Never tested production code** - The enhanced features don't exist
2. **All fail due to path bugs** - Double `.claude` in path
3. **Should be removed** - 4 tests for deprecated features
4. **Or fixed** - 3 tests that validate current functionality with wrong paths

No library code or agents need removal. The cleanup focuses entirely on test files.
