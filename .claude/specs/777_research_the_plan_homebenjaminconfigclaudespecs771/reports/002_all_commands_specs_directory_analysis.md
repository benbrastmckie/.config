# All Commands Creating Specs Directories - Research Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Commands creating directories in .claude/specs/
- **Report Type**: codebase analysis

## Executive Summary

This report identifies ALL commands that create directories in the `.claude/specs/` directory and evaluates which ones are covered by the existing semantic slug integration plan. Five commands create specs directories, but the current plan only covers `/plan`. The remaining four commands (`/research`, `/debug`, `/coordinate`, `/revise`) also need to be updated, with `/coordinate` already correctly using the new pattern. Additionally, `/optimize-claude` uses a different approach via `perform_location_detection()` that should also be evaluated.

## Findings

### Commands Creating Specs Directories

#### 1. /plan Command (COVERED IN PLAN - NEEDS FIX)
- **File**: `/home/benjamin/.config/.claude/commands/plan.md`
- **Lines**: 223-256
- **Current Pattern**: Uses `sanitize_topic_name()` + `allocate_and_create_topic()`
- **Status**: Covered in existing plan - this is the primary target of Plan 001

```bash
# Line 223-225: Topic slug generation
TOPIC_SLUG=$(sanitize_topic_name "$FEATURE_DESCRIPTION")

# Line 227-229: Directory allocation
SPECS_ROOT="${CLAUDE_PROJECT_DIR}/.claude/specs"
RESULT=$(allocate_and_create_topic "$SPECS_ROOT" "$TOPIC_SLUG")
```

#### 2. /research Command (NOT COVERED - NEEDS UPDATE)
- **File**: `/home/benjamin/.config/.claude/commands/research.md`
- **Lines**: 222-248
- **Current Pattern**: Uses `sanitize_topic_name()` + `allocate_and_create_topic()`
- **Status**: NOT covered in existing plan - uses identical problematic pattern

```bash
# Line 222-224: Topic slug generation
TOPIC_SLUG=$(sanitize_topic_name "$WORKFLOW_DESCRIPTION")

# Line 226-228: Directory allocation
SPECS_ROOT="${CLAUDE_PROJECT_DIR}/.claude/specs"
RESULT=$(allocate_and_create_topic "$SPECS_ROOT" "$TOPIC_SLUG")
```

#### 3. /debug Command (NOT COVERED - NEEDS UPDATE)
- **File**: `/home/benjamin/.config/.claude/commands/debug.md`
- **Lines**: 167-189
- **Current Pattern**: Uses inline sed sanitization + `allocate_and_create_topic()`
- **Status**: NOT covered in existing plan - uses even simpler sanitization

```bash
# Line 167-168: Manual inline sanitization (worse than sanitize_topic_name)
TOPIC_SLUG=$(echo "$ISSUE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-50)

# Line 170-172: Directory allocation
SPECS_ROOT="${CLAUDE_PROJECT_DIR}/.claude/specs"
RESULT=$(allocate_and_create_topic "$SPECS_ROOT" "$TOPIC_SLUG")
```

#### 4. /coordinate Command (ALREADY USING CORRECT PATTERN)
- **File**: `/home/benjamin/.config/.claude/commands/coordinate.md`
- **Lines**: 475-513
- **Current Pattern**: Uses `initialize_workflow_paths()` with `CLASSIFICATION_JSON`
- **Status**: ALREADY CORRECT - reference implementation

```bash
# Line 475-477: Sources workflow-initialization.sh
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh"

# Line 483: Uses initialize_workflow_paths with classification result
if initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE" "$RESEARCH_COMPLEXITY" "$CLASSIFICATION_JSON"; then
```

#### 5. /revise Command (NOT COVERED - PARTIAL UPDATE NEEDED)
- **File**: `/home/benjamin/.config/.claude/commands/revise.md`
- **Lines**: 235-245
- **Current Pattern**: Derives from existing plan path, uses sed sanitization for revision topic
- **Status**: NOT covered in plan - unique case, derives SPECS_DIR from EXISTING_PLAN_PATH

```bash
# Line 235-237: Derives specs directory from existing plan
SPECS_DIR=$(dirname "$(dirname "$EXISTING_PLAN_PATH")")
RESEARCH_DIR="${SPECS_DIR}/reports"

# Line 243: Uses inline sed for revision topic slug
REVISION_TOPIC_SLUG=$(echo "$REVISION_DETAILS" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-30)
```

#### 6. /optimize-claude Command (DIFFERENT APPROACH)
- **File**: `/home/benjamin/.config/.claude/commands/optimize-claude.md`
- **Lines**: 37-51
- **Current Pattern**: Uses `perform_location_detection()` function
- **Status**: NOT covered - uses separate detection system

```bash
# Line 37-38: Uses perform_location_detection
LOCATION_JSON=$(perform_location_detection "optimize CLAUDE.md structure")

# Line 40-43: Extracts paths from JSON
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
```

### Directory Naming Patterns Summary

| Command | Sanitization Method | Uses Classification | Current Quality |
|---------|-------------------|-------------------|-----------------|
| /plan | `sanitize_topic_name()` | No | Poor - truncated paths |
| /research | `sanitize_topic_name()` | No | Poor - truncated paths |
| /debug | inline sed | No | Worst - 50 char truncation |
| /coordinate | `validate_topic_directory_slug()` | Yes | Good - semantic slugs |
| /revise | derive + sed | No (N/A - uses existing) | Acceptable - reuses existing |
| /optimize-claude | `perform_location_detection()` | No | Unknown - separate system |

### Key Library Functions

1. **`sanitize_topic_name()`** in `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:356-368`
   - Simple sanitization: lowercase, replace spaces, remove special chars, truncate to 50 chars
   - Does NOT extract significant words

2. **`allocate_and_create_topic()`** in `/home/benjamin/.config/.claude/lib/unified-location-detection.sh`
   - Atomically allocates next available topic number
   - Creates directory with NNN prefix

3. **`initialize_workflow_paths()`** in `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:364-509+`
   - Accepts classification_result as 4th parameter
   - Uses `validate_topic_directory_slug()` for LLM-based semantic naming
   - Falls back to `sanitize_topic_name()` if no classification provided

4. **`validate_topic_directory_slug()`** in `/home/benjamin/.config/.claude/lib/topic-utils.sh`
   - Three-tier fallback: LLM slug -> extract_significant_words -> sanitize_topic_name

5. **`perform_location_detection()`** in `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:473+`
   - Different system used by /optimize-claude
   - Returns JSON with paths

### Coverage Gap Analysis

The existing plan (001_plan_command_semantic_slug_integration_plan.md) only covers:
- Phase 1: Update /plan command
- Phase 2: Improve fallback in unified-location-detection.sh
- Phase 3: Add integration tests
- Phase 4: Documentation and verification

**MISSING from the plan**:
1. /research command (identical pattern to /plan)
2. /debug command (worse inline sanitization)
3. /optimize-claude command (different system)

**Not requiring changes**:
1. /coordinate command (already correct)
2. /revise command (derives from existing plan, doesn't create new topic directories)

## Recommendations

### 1. Expand Plan Scope to Include All Commands (HIGH PRIORITY)

Add new phases to update:
- **/research** - Uses identical pattern to /plan, nearly copy-paste fix
- **/debug** - Uses inline sed, needs workflow-classifier integration

Both should follow the same pattern as /plan:
1. Invoke workflow-classifier agent via Task tool
2. Parse CLASSIFICATION_COMPLETE response
3. Call `initialize_workflow_paths()` with classification result

### 2. Create Common Refactoring Pattern (MEDIUM PRIORITY)

Since /plan, /research, and /debug all need nearly identical changes:
1. Consider extracting the workflow-classifier invocation into a reusable template
2. Document the pattern in command guidelines for future commands
3. Ensure consistent error handling across all three

### 3. Evaluate /optimize-claude Integration (LOW PRIORITY)

The /optimize-claude command uses `perform_location_detection()` which is a separate system:
- Investigate if this should also use semantic slugs
- Determine if `perform_location_detection()` should be updated to use `validate_topic_directory_slug()`
- This may be intentionally simpler and not require the same sophistication

### 4. Add Regression Tests for All Commands (MEDIUM PRIORITY)

The current plan only tests /plan. Add tests for:
- /research semantic slug generation
- /debug semantic slug generation
- Ensure /coordinate continues working correctly

### 5. Consider Unified Topic Allocation Function (FUTURE)

Long-term, consider creating a single function that:
- Invokes workflow-classifier
- Calls `initialize_workflow_paths()`
- Returns standardized path variables
- Could be used by all commands

This would prevent drift between commands and ensure consistency.

## References

- `/home/benjamin/.config/.claude/commands/plan.md:223-256` - /plan directory creation
- `/home/benjamin/.config/.claude/commands/research.md:222-248` - /research directory creation
- `/home/benjamin/.config/.claude/commands/debug.md:167-189` - /debug directory creation
- `/home/benjamin/.config/.claude/commands/coordinate.md:475-513` - /coordinate (correct pattern)
- `/home/benjamin/.config/.claude/commands/revise.md:235-245` - /revise directory derivation
- `/home/benjamin/.config/.claude/commands/optimize-claude.md:37-51` - /optimize-claude path detection
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:356-368` - sanitize_topic_name()
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:473` - perform_location_detection()
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:364-509` - initialize_workflow_paths()
- `/home/benjamin/.config/.claude/specs/777_research_the_plan_homebenjaminconfigclaudespecs771/plans/001_plan_command_semantic_slug_integration_plan.md` - Existing plan

## Implementation Status
- **Status**: Plan Revised
- **Plan**: [../plans/001_plan_command_semantic_slug_integration_plan.md](../plans/001_plan_command_semantic_slug_integration_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-17
- **Note**: Research findings incorporated into revised plan which now covers all three commands
