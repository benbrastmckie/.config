# Directory Creation Code Patterns

## Research Topic
Analysis of directory creation patterns in .claude/ codebase

## Status
✅ Research complete

## Related Reports
- [Overview Report](./OVERVIEW.md) - Main synthesis of all findings

## Objectives
1. Identify all directory creation patterns in .claude/
2. Locate spec directory creation logic in commands
3. Find directory creation utilities in libraries
4. Document numbered spec directory creation mechanisms

## Findings

### Pattern 1: Unified Location Detection Library - Primary Directory Creation

**File**: `/home/benjamin/.config/.claude/lib/unified-location-detection.sh`

This is the **primary** directory creation mechanism used by all workflow commands.

**Key Functions**:

1. **`create_topic_structure(topic_path)`** - Lines 263-279
   - Creates topic root directory only (lazy subdirectory creation)
   - **Does NOT** create subdirectories (reports/, plans/, etc.)
   - Verification checkpoint ensures topic root exists
   - Used by: `perform_location_detection()` at line 346

2. **`ensure_artifact_directory(file_path)`** - Lines 231-242
   - Lazy creation pattern: creates parent directory only when needed
   - Called before file writes (not during location detection)
   - Idempotent: safe to call multiple times
   - 80% reduction in mkdir calls vs eager creation

3. **`perform_location_detection(workflow_description)`** - Lines 313-387
   - Orchestrates complete location detection workflow
   - Step 6 (line 346): Calls `create_topic_structure()` to create topic root only
   - Returns JSON with artifact paths (not directories)
   - Used by: `/report` (line 87), `/plan` (line 485), `/research` (line 87), `/orchestrate` (line 431)

**Design Philosophy** (from file header, lines 10-22):
```bash
# Features:
#   - Lazy directory creation: Creates artifact directories only when files are written
#   - Eliminates empty subdirectories (reduced from 400-500 to 0 empty dirs)
#   - Performance: 80% reduction in mkdir calls during location detection
#
# Usage:
#   # Lazy directory creation pattern:
#   ensure_artifact_directory "$REPORT_PATH" || exit 1
#   echo "content" > "$REPORT_PATH"
```

**Behavior Change** (Evidence):
- Lines 10-12: Explicitly states "Eliminates empty subdirectories (reduced from 400-500 to 0 empty dirs)"
- Line 263: Function comment says "Create topic root directory (lazy subdirectory creation pattern)"
- Line 266: Only creates topic root: `mkdir -p "$topic_path"`
- Line 252: Previous note says "Does NOT create: reports/, plans/, summaries/, etc. (created lazily)"

### Pattern 2: Legacy Topic-Utils Library - Eager Directory Creation

**File**: `/home/benjamin/.config/.claude/lib/topic-utils.sh`

This library represents the **OLD** pattern that created empty directories.

**Key Function**:

**`create_topic_structure(topic_path)`** - Lines 63-90
```bash
create_topic_structure() {
  local topic_path="$1"

  # Create parent directory
  mkdir -p "$topic_path"

  # Create all 6 standard subdirectories
  mkdir -p "$topic_path"/{reports,plans,summaries,debug,scripts,outputs}

  # Verification checkpoint (required by Verification and Fallback pattern)
  local missing_dirs=()
  for subdir in reports plans summaries debug scripts outputs; do
    if [ ! -d "$topic_path/$subdir" ]; then
      missing_dirs+=("$subdir")
    fi
  done

  # If any directories are missing, report error and fail
  if [ ${#missing_dirs[@]} -gt 0 ]; then
    echo "ERROR: Failed to create subdirectories in $topic_path:" >&2
    for missing in "${missing_dirs[@]}"; do
      echo "  - $missing" >&2
    done
    return 1
  fi

  return 0
}
```

**Behavior**:
- Line 70: **Creates ALL 6 subdirectories eagerly** using brace expansion
- Lines 73-87: Verification loop ensures all 6 exist
- Used by: Legacy code, may still be referenced in old commands

**Status**: This library is **deprecated** in favor of unified-location-detection.sh

### Pattern 3: Command-Specific Directory Creation

**File**: `/home/benjamin/.config/.claude/commands/report.md`

Commands now use the lazy creation pattern via library sourcing.

**Agent Invocation Pattern** (Lines 217-224):
```bash
**STEP 1.5 (EXECUTE NOW)**: Ensure parent directory exists (lazy creation):
```bash
source .claude/lib/unified-location-detection.sh
ensure_artifact_directory "[ABSOLUTE_PATH_FROM_SUBTOPIC_REPORT_PATHS]" || {
  echo "ERROR: Failed to create parent directory" >&2
  exit 1
}
```
```

**Integration Flow**:
1. Command sources unified-location-detection.sh (line 84)
2. Command calls `perform_location_detection()` (line 87)
3. Library creates topic root only
4. Agent receives absolute file path
5. Agent calls `ensure_artifact_directory()` before write
6. Parent directory created on-demand

**Commands Using This Pattern**:
- `/report` - Line 84-87
- `/plan` - Line 485
- `/research` - Line 84-87
- `/orchestrate` - Line 428-431

### Pattern 4: Artifact Creation Library

**File**: `/home/benjamin/.config/.claude/lib/artifact-creation.sh`

Provides artifact-specific directory creation.

**Functions**:

1. **`create_artifact_directory(plan_path)`** - Lines 86-103
   - Creates `specs/artifacts/{plan_name}/` directory
   - Used for temporary artifacts during implementation
   - Calls `mkdir -p` directly (line 100)

2. **`create_artifact_directory_with_workflow(workflow_description)`** - Lines 105-129
   - Converts workflow description to snake_case
   - Creates artifact directory with next available number
   - Returns artifact directory path

**Usage Context**: Implementation-phase artifacts, not topic structure

### Pattern 5: Migration Utilities

**File**: `/home/benjamin/.config/.claude/lib/migrate-specs-utils.sh`

**Function**: `create_topic_directories(topic_dir)` - Lines 326-398

**Behavior** (Lines 331-334):
```bash
mkdir -p "$topic_dir"

# Create all subdirectories (including backups and artifacts)
mkdir -p "$topic_dir"/{reports,plans,summaries,debug,scripts,outputs,artifacts,backups}
```

**Purpose**: Migration from old spec structure to topic-based structure
- Creates **8 subdirectories** (includes artifacts/ and backups/)
- Used by migration scripts only, not regular workflow commands

### Pattern 6: Template Integration Library

**File**: `/home/benjamin/.config/.claude/lib/template-integration.sh`

**Function**: `get_or_create_topic_dir(base_name)` - Line 260-288

**Behavior** (Line 288):
```bash
mkdir -p "$topic_dir"/{plans,reports,summaries,debug,scripts,outputs,artifacts,backups}
```

**Purpose**: Template-based plan generation
- Creates 8 subdirectories (same as migration utils)
- Used by `/plan-from-template` command

### Pattern 7: Supervise Command Fallback

**File**: `/home/benjamin/.config/.claude/commands/supervise.md`

**Fallback Pattern** (Lines 543-577):
```bash
# Create topic structure using utility function (includes verification)
if ! create_topic_structure "$TOPIC_PATH"; then
  echo "❌ CRITICAL ERROR: Topic directory not created at $TOPIC_PATH"
  echo ""
  echo "FALLBACK MECHANISM: Attempting manual directory creation..."
  echo ""

  # Manual fallback: Create topic root and essential subdirectories
  mkdir -p "$TOPIC_PATH"/{reports,outputs} || {
    echo "❌ FATAL: Cannot create topic directory. Aborting."
    exit 1
  }

  # Verify minimal structure created
  if [ ! -d "$TOPIC_PATH/reports" ] || [ ! -d "$TOPIC_PATH/outputs" ]; then
    echo "❌ FATAL: Fallback directory creation failed. Aborting."
    exit 1
  fi

  echo "✓ RECOVERED: Created minimal topic structure (reports/, outputs/)"
  echo "  Note: Other subdirectories will be created on-demand if needed"
fi
```

**Purpose**: Graceful degradation if library function fails
- Creates minimal subdirectories (reports/, outputs/)
- Follows verification and fallback pattern

## Summary

### Primary Pattern: Lazy Directory Creation

The .claude/ system has **migrated from eager to lazy directory creation**:

**Old Pattern** (topic-utils.sh):
- Created all 6 subdirectories upfront
- Result: 400-500 empty directories across codebase

**New Pattern** (unified-location-detection.sh):
- Creates topic root only during location detection
- Creates subdirectories on-demand via `ensure_artifact_directory()`
- Result: 0 empty directories (80% reduction in mkdir calls)

### Function Distribution

| Function | File | Purpose | Subdirs Created |
|----------|------|---------|-----------------|
| `perform_location_detection()` | unified-location-detection.sh | Primary workflow | Topic root only |
| `ensure_artifact_directory()` | unified-location-detection.sh | Lazy creation | Parent dir of file |
| `create_topic_structure()` | topic-utils.sh | Legacy (deprecated) | All 6 subdirs |
| `create_artifact_directory()` | artifact-creation.sh | Implementation artifacts | artifacts/{name} |
| `create_topic_directories()` | migrate-specs-utils.sh | Migration only | All 8 subdirs |
| `get_or_create_topic_dir()` | template-integration.sh | Template plans | All 8 subdirs |

### Command Integration Count

**4 primary workflow commands** use unified-location-detection.sh:
1. `/report` (line 87)
2. `/plan` (line 485)
3. `/research` (line 87)
4. `/orchestrate` (line 431)

All follow the lazy creation pattern.

## Recommendations

### 1. Complete Migration to Lazy Pattern (Priority: High)

**Finding**: Some libraries still use eager creation (migrate-specs-utils.sh, template-integration.sh)

**Action**: Update these libraries to use `ensure_artifact_directory()` pattern:
- Migration utilities should create directories only when copying files
- Template integration should create directories only when writing plans

### 2. Deprecate topic-utils.sh (Priority: Medium)

**Finding**: topic-utils.sh implements the old eager creation pattern

**Action**:
- Add deprecation notice to file header
- Identify remaining references (if any)
- Plan removal in future cleanup

### 3. Document Lazy Creation Pattern (Priority: High)

**Finding**: Pattern is documented in unified-location-detection.sh but not in general guides

**Action**: Add section to `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md`:
```markdown
## Lazy Directory Creation Pattern

The .claude/ system uses lazy directory creation to eliminate empty directories:

1. **Location Detection**: Creates topic root only (`specs/NNN_topic/`)
2. **File Write**: Agent calls `ensure_artifact_directory()` before write
3. **Subdirectory Creation**: Parent directory created on-demand

Benefits:
- Eliminates 400-500 empty directories
- 80% reduction in mkdir calls
- Cleaner codebase structure
```

### 4. Update Agent Templates (Priority: Medium)

**Finding**: Agents must call `ensure_artifact_directory()` before writes

**Action**: Ensure all agent templates include STEP 1.5 pattern:
```bash
source .claude/lib/unified-location-detection.sh
ensure_artifact_directory "$REPORT_PATH" || exit 1
```

**Files to check**:
- `/home/benjamin/.config/.claude/agents/*.md`
- Agent invocation templates in commands

### 5. Add Test Coverage (Priority: High)

**Finding**: Need explicit tests for lazy creation behavior

**Action**: Add test to `/home/benjamin/.config/.claude/tests/test_unified_location_detection.sh`:
```bash
test_lazy_creation_no_empty_directories() {
  local test_topic=$(perform_location_detection "test lazy creation" "true" | jq -r '.topic_path')

  # Verify topic root exists
  [ -d "$test_topic" ] || fail "Topic root not created"

  # Verify subdirectories do NOT exist yet
  for subdir in reports plans summaries debug scripts outputs; do
    if [ -d "$test_topic/$subdir" ]; then
      fail "Eager creation detected: $subdir exists without file write"
      return 1
    fi
  done

  pass "Lazy creation confirmed: no empty subdirectories"
}
```
