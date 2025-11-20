# Plan Command Error Analysis Research Report

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Broken library references and missing files after .claude/ refactoring
- **Report Type**: codebase analysis

## Executive Summary

The /plan command is failing due to broken library source references in the workflow library files. After a refactoring of the .claude/lib/ directory into subdirectories (core/, workflow/, plan/, etc.), several library files still contain incorrect relative path references. The primary issues are: (1) workflow-llm-classifier.sh and workflow-scope-detection.sh looking for detect-project-dir.sh in the wrong directory, and (2) workflow-init.sh's _source_lib() function constructing library paths without subdirectory paths.

## Findings

### Error Categories Identified

#### Category 1: Incorrect Relative Paths in Workflow Libraries

**Location**: `/home/benjamin/.config/.claude/lib/workflow/workflow-llm-classifier.sh:19`

```bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/detect-project-dir.sh"
```

**Issue**: This path resolves to `/home/benjamin/.config/.claude/lib/workflow/detect-project-dir.sh` but the file is actually at `/home/benjamin/.config/.claude/lib/core/detect-project-dir.sh`.

**Error Message**: `/home/benjamin/.config/.claude/lib/workflow/detect-project-dir.sh: No such file or directory`

---

**Location**: `/home/benjamin/.config/.claude/lib/workflow/workflow-scope-detection.sh:22`

```bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/detect-project-dir.sh"
```

**Issue**: Same problem - looking in workflow/ instead of core/.

---

#### Category 2: Missing Subdirectory Prefix in _source_lib()

**Location**: `/home/benjamin/.config/.claude/lib/workflow/workflow-init.sh:55-76`

The `_source_lib()` helper function constructs paths without subdirectory information:

```bash
_source_lib() {
  local library_name="$1"
  local required="${2:-required}"
  local lib_path="${CLAUDE_PROJECT_DIR}/.claude/lib/${library_name}"  # Line 58
  ...
}
```

**Calls with incorrect paths**:
- Line 167: `_source_lib "state-persistence.sh"` - should be `core/state-persistence.sh`
- Line 168: `_source_lib "workflow-state-machine.sh"` - should be `workflow/workflow-state-machine.sh`
- Line 171: `_source_lib "library-version-check.sh"` - should be `core/library-version-check.sh`
- Line 172: `_source_lib "error-handling.sh"` - should be `core/error-handling.sh`
- Line 173: `_source_lib "unified-location-detection.sh"` - should be `core/unified-location-detection.sh`
- Line 174: `_source_lib "workflow-initialization.sh"` - should be `workflow/workflow-initialization.sh`

Lines 300-301 have the same issue.

---

#### Category 3: workflow-initialization.sh Dependency Error

**Location**: `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh:27-41`

The error message from plan-output.md states:
```
ERROR: topic-utils.sh not found
Expected location: /home/benjamin/.config/.claude/lib/workflow/topic-utils.sh
```

**Analysis**: This error is misleading. Looking at the actual code (lines 27-41), the file DOES use the correct relative path `$SCRIPT_DIR/../plan/topic-utils.sh`:

```bash
if [ -f "$SCRIPT_DIR/../plan/topic-utils.sh" ]; then
  source "$SCRIPT_DIR/../plan/topic-utils.sh"
else
  echo "ERROR: topic-utils.sh not found" >&2
  echo "Expected location: $SCRIPT_DIR/../plan/topic-utils.sh" >&2  # BUG: prints wrong path
  exit 1
fi
```

The error message misleadingly prints `$SCRIPT_DIR/../plan/topic-utils.sh` but the actual SCRIPT_DIR value at runtime points to `workflow/`, and the error message should read the resolved path. However, the actual path IS correct (`../plan/topic-utils.sh` from workflow/ = plan/topic-utils.sh).

The ACTUAL cause is that workflow-state-machine.sh (sourced BEFORE workflow-initialization.sh) fails first due to its detect-project-dir.sh reference, causing the error cascade.

### Current Directory Structure

The .claude/lib/ directory has been reorganized into subdirectories:

```
.claude/lib/
├── core/                    # Core utilities
│   ├── base-utils.sh
│   ├── detect-project-dir.sh    # <-- Key file causing failures
│   ├── error-handling.sh
│   ├── library-sourcing.sh
│   ├── library-version-check.sh
│   ├── state-persistence.sh
│   ├── timestamp-utils.sh
│   ├── unified-location-detection.sh
│   └── unified-logger.sh
├── workflow/                # Workflow orchestration
│   ├── argument-capture.sh
│   ├── checkpoint-utils.sh
│   ├── metadata-extraction.sh
│   ├── workflow-detection.sh
│   ├── workflow-init.sh
│   ├── workflow-initialization.sh
│   ├── workflow-llm-classifier.sh   # <-- Has broken reference
│   ├── workflow-scope-detection.sh  # <-- Has broken reference
│   └── workflow-state-machine.sh
├── plan/                    # Planning utilities
│   ├── auto-analysis-utils.sh
│   ├── checkbox-utils.sh
│   ├── complexity-utils.sh
│   ├── parse-template.sh
│   ├── plan-core-bundle.sh
│   ├── topic-decomposition.sh
│   └── topic-utils.sh       # <-- Mentioned in error but path is correct
├── artifact/                # Artifact management
├── convert/                 # Document conversion
└── util/                    # General utilities
```

### Files That Have Correct Paths

Several files in the workflow directory DO use correct relative paths:

- `workflow-state-machine.sh:34`: `source "$SCRIPT_DIR/../core/detect-project-dir.sh"` - CORRECT
- `workflow-initialization.sh:28`: `source "$SCRIPT_DIR/../plan/topic-utils.sh"` - CORRECT
- `workflow-initialization.sh:36`: `source "$SCRIPT_DIR/../core/detect-project-dir.sh"` - CORRECT
- `workflow-detection.sh:15`: `source "$SCRIPT_DIR/../core/detect-project-dir.sh"` - CORRECT
- `checkpoint-utils.sh:17`: `source "$SCRIPT_DIR/../core/detect-project-dir.sh"` - CORRECT

### Files With Incorrect Paths

Files that still use incorrect paths:

1. **workflow-llm-classifier.sh:19**
   ```bash
   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/detect-project-dir.sh"
   ```
   Should be:
   ```bash
   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../core/detect-project-dir.sh"
   ```

2. **workflow-scope-detection.sh:22**
   ```bash
   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/detect-project-dir.sh"
   ```
   Should be:
   ```bash
   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../core/detect-project-dir.sh"
   ```

3. **workflow-init.sh:58** (and calls on lines 167-174, 300-301)
   ```bash
   local lib_path="${CLAUDE_PROJECT_DIR}/.claude/lib/${library_name}"
   ```
   Either modify function to accept subdirectory paths, or update calls to include full paths.

## Root Cause Analysis

### Primary Issue: Incomplete Refactoring

The .claude/lib/ directory was recently reorganized from a flat structure to a hierarchical subdirectory structure. This refactoring:

1. **Moved files to subdirectories** - detect-project-dir.sh moved from lib/ to lib/core/
2. **Updated most references** - Many files were updated with correct relative paths
3. **Missed some files** - workflow-llm-classifier.sh and workflow-scope-detection.sh were not updated

### Secondary Issue: Inconsistent Path Resolution Patterns

The codebase uses two different patterns for resolving library paths:

**Pattern A: SCRIPT_DIR + relative path** (Recommended)
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/detect-project-dir.sh"
```

**Pattern B: Inline path resolution** (Problematic)
```bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/detect-project-dir.sh"
```

Pattern B makes it harder to see and update relative paths during refactoring.

### Error Cascade

The error cascade in plan-output.md is:

1. plan.md sources `workflow-state-machine.sh` (line 116)
2. workflow-state-machine.sh sources `$SCRIPT_DIR/../core/detect-project-dir.sh` (line 34) - THIS WORKS
3. Then workflow-initialization.sh is sourced (line 123-126)
4. workflow-initialization.sh internally sources topic-utils.sh and detect-project-dir.sh - BOTH WORK
5. But somewhere in the chain, workflow-scope-detection.sh or workflow-llm-classifier.sh get sourced
6. These fail because they look for detect-project-dir.sh in workflow/ instead of core/

The error message `ERROR: topic-utils.sh not found` is actually a RED HERRING - the real first failure is the detect-project-dir.sh reference in one of the -llm-classifier or -scope-detection files.

## Recommendations

### Recommendation 1: Fix Broken Source References (Critical)

Update the two files with incorrect paths:

**File 1**: `/home/benjamin/.config/.claude/lib/workflow/workflow-llm-classifier.sh`
- Line 19: Change `source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/detect-project-dir.sh"`
- To: `source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../core/detect-project-dir.sh"`

**File 2**: `/home/benjamin/.config/.claude/lib/workflow/workflow-scope-detection.sh`
- Line 22: Change `source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/detect-project-dir.sh"`
- To: `source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../core/detect-project-dir.sh"`

### Recommendation 2: Fix workflow-init.sh _source_lib Function

Update the `_source_lib()` function to handle subdirectory paths:

**Option A**: Modify calls to include subdirectory
```bash
_source_lib "core/state-persistence.sh" "required" || return 1
_source_lib "workflow/workflow-state-machine.sh" "required" || return 1
```

**Option B**: Add subdirectory mapping to function
```bash
_source_lib() {
  local library_name="$1"
  local required="${2:-required}"

  # Map library names to their subdirectories
  local subdir=""
  case "$library_name" in
    state-persistence.sh|error-handling.sh|library-version-check.sh|unified-location-detection.sh)
      subdir="core/"
      ;;
    workflow-*.sh)
      subdir="workflow/"
      ;;
  esac

  local lib_path="${CLAUDE_PROJECT_DIR}/.claude/lib/${subdir}${library_name}"
  ...
}
```

**Option A is recommended** - explicit paths are clearer and less prone to mapping errors.

### Recommendation 3: Standardize Path Resolution Pattern

Adopt consistent SCRIPT_DIR pattern across all library files:

```bash
# At top of file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# When sourcing
source "$SCRIPT_DIR/../core/detect-project-dir.sh"
```

This makes paths explicit and easier to update during refactoring.

### Recommendation 4: Create Migration Test Script

Create a test script to validate all library source references:

```bash
#!/usr/bin/env bash
# validate-library-sources.sh
# Validates all source statements in .claude/lib/ resolve to existing files

find .claude/lib -name "*.sh" -exec grep -l "source" {} \; | while read file; do
  grep -n "source" "$file" | while read line; do
    # Extract and validate source path
    # Report any missing files
  done
done
```

### Recommendation 5: Update Existing Path Update Script

There's an existing script at `/home/benjamin/.config/.claude/lib/tmp/update_paths.sh` that was likely used during refactoring. Update it to include the missed files:

- Add: `sed -i 's|/detect-project-dir\.sh|/../core/detect-project-dir.sh|g'` for inline patterns

## References

- `/home/benjamin/.config/.claude/plan-output.md:23-28` - Error output showing failures
- `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh:34` - Correct reference example
- `/home/benjamin/.config/.claude/lib/workflow/workflow-llm-classifier.sh:19` - Broken reference
- `/home/benjamin/.config/.claude/lib/workflow/workflow-scope-detection.sh:22` - Broken reference
- `/home/benjamin/.config/.claude/lib/workflow/workflow-init.sh:55-76` - _source_lib function
- `/home/benjamin/.config/.claude/lib/workflow/workflow-init.sh:167-174` - Calls with missing subdirectory
- `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh:27-41` - Correct but misleading error message
- `/home/benjamin/.config/.claude/lib/core/detect-project-dir.sh` - Target file that should be found
- `/home/benjamin/.config/.claude/lib/plan/topic-utils.sh` - Another key dependency
- `/home/benjamin/.config/.claude/lib/tmp/update_paths.sh:11,30` - Existing migration script
- `/home/benjamin/.config/.claude/commands/plan.md:115-126` - Correct sourcing example in command

## Impact Assessment

### Severity: High

All commands that use the affected libraries will fail:
- /plan - Uses workflow-state-machine.sh and workflow-initialization.sh
- /research - Uses same libraries
- /build - Uses same libraries
- /debug - Uses same libraries
- /revise - Uses same libraries

### Effort to Fix: Low

- 2 files need path corrections (1 line each)
- 1 function needs update (either function body or 6 call sites)
- Estimated time: 15-30 minutes
