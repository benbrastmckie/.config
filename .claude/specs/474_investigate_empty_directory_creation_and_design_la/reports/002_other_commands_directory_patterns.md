# Other Commands Directory Creation Patterns

## Overview

This report analyzes directory creation patterns across all workflow commands (`/plan`, `/report`, `/implement`, `/debug`, `/orchestrate`, `/supervise`) to identify how they handle subdirectory creation. The research reveals a **transition from eager to lazy directory creation** that occurred on 2025-10-24 with the implementation of the unified location detection library.

**Key Finding**: Most commands now use **lazy directory creation** via `ensure_artifact_directory()`, creating subdirectories only when files are actually written. However, `/orchestrate` and `/supervise` still use **eager directory creation** as a fallback mechanism, creating all subdirectories upfront.

## Research Findings

### 1. Lazy Directory Creation Pattern (Preferred)

**Implementation**: `unified-location-detection.sh` (lines 239-250)

The modern approach uses `ensure_artifact_directory()` to create parent directories on-demand:

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

**Commands using lazy creation**:
- `/plan` - Uses `ensure_artifact_directory()` before writing plan files (line 254)
- `/implement` - Uses `ensure_artifact_directory()` for fallback artifacts (line 1038)
- `/debug` - Uses `ensure_artifact_directory()` for debug reports (line 422)
- `/report` - Creates research subdirectories on-demand with `create_research_subdirectory()` (line 140)
- `create_topic_structure()` - Creates ONLY topic root, not subdirectories (lines 271-278)

**Benefits** (from directory-protocols.md:67-75):
- Eliminates 400-500 empty directories across codebase
- 80% reduction in mkdir calls during location detection
- Directories exist only when they contain actual artifacts

### 2. Eager Directory Creation Pattern (Legacy/Fallback)

**Commands still using eager creation**:

**`/orchestrate`** (orchestrate.md:485):
```bash
mkdir -p "$TOPIC_PATH"/{reports,plans,summaries,debug,scripts,outputs}
```

**`/supervise`** (supervise.md:602):
```bash
mkdir -p "$TOPIC_PATH"/{reports,plans,summaries,debug,scripts,outputs}
```

**Context**: Both commands use eager creation as a **fallback mechanism** when location detection fails:

From orchestrate.md:480-493:
```bash
if [ ! -d "$TOPIC_PATH" ]; then
  echo "❌ ERROR: Location detection failed - topic directory not created at $TOPIC_PATH"
  echo "FALLBACK: Creating directory structure manually"

  # Fallback: Create directory structure manually
  mkdir -p "$TOPIC_PATH"/{reports,plans,summaries,debug,scripts,outputs}
```

### 3. Hybrid Pattern: `/plan` Command

The `/plan` command uses **eager creation as a fallback** when location specialist fails:

From plan.md:1002-1020:
```bash
if [ "$VERIFICATION_STATUS" != "true" ] || [ "$GITIGNORE_STATUS" != "true" ]; then
  echo "⚠️  TOPIC STRUCTURE INCOMPLETE - Triggering fallback mechanism"

  # Fallback: Create subdirectories manually
  for subdir in reports plans summaries debug scripts outputs artifacts backups; do
    mkdir -p "${TOPIC_DIR}/${subdir}"
  done
```

However, when location detection succeeds, `/plan` relies on lazy creation via `ensure_artifact_directory()`.

### 4. Special Case: `/report` Command

The `/report` command uses a **hybrid approach** with hierarchical research subdirectories:

From report.md:138-140:
```bash
# Create subdirectory for this research task (groups related subtopic reports)
RESEARCH_SUBDIR="${REPORTS_DIR}/${FORMATTED_NUM}_${TOPIC_NAME}"
mkdir -p "$RESEARCH_SUBDIR"
```

This is still lazy creation (only creates when writing reports), but creates a **nested structure** (`reports/NNN_topic/NNN_subtopic.md`).

The `create_research_subdirectory()` function (unified-location-detection.sh:473-479) also uses lazy creation:
```bash
# Create reports directory if it doesn't exist (lazy creation support)
if [ ! -d "$reports_dir" ]; then
  mkdir -p "$reports_dir" || {
    echo "ERROR: Failed to create reports directory: $reports_dir" >&2
    return 1
  }
fi
```

### 5. Library Design Philosophy

From unified-location-detection.sh:10-14:
```bash
# Features:
#   - Lazy directory creation: Creates artifact directories only when files are written
#   - Eliminates empty subdirectories (reduced from 400-500 to 0 empty dirs)
#   - Performance: 80% reduction in mkdir calls during location detection
```

From create_topic_structure() documentation (lines 257-264):
```bash
# Creates:
#   - Topic root directory ONLY
#   - Subdirectories created on-demand via ensure_artifact_directory()
#
# Usage:
#   create_topic_structure "$TOPIC_PATH" || exit 1
#   # Creates: /path/to/project/.claude/specs/042_feature/
#   # Does NOT create: reports/, plans/, summaries/, etc. (created lazily)
```

## Recommendations

### 1. Adopt Lazy Creation System-Wide

**Recommendation**: Eliminate eager directory creation from `/orchestrate` and `/supervise` fallback mechanisms.

**Rationale**:
- Lazy creation is the documented standard (directory-protocols.md:67-89)
- Proven 80% reduction in mkdir calls
- Eliminates 400-500 empty directories
- Directories only exist when they contain artifacts

**Implementation**: Replace eager fallback with lazy pattern:
```bash
# BEFORE (Eager - Bad)
mkdir -p "$TOPIC_PATH"/{reports,plans,summaries,debug,scripts,outputs}

# AFTER (Lazy - Good)
# No subdirectory creation
# Rely on ensure_artifact_directory() when writing files
```

### 2. Update `/plan` Fallback Logic

**Recommendation**: Remove eager subdirectory creation from `/plan` fallback (lines 1002-1020).

**Rationale**: The fallback should only ensure the topic root exists, not create all subdirectories. Subdirectories will be created lazily when plans are written.

### 3. Standardize on `ensure_artifact_directory()`

**Recommendation**: All commands should use `ensure_artifact_directory()` before writing any file.

**Best Practice Pattern**:
```bash
# Standard pattern for all commands
ARTIFACT_PATH="$TOPIC_PATH/plans/001_implementation.md"
ensure_artifact_directory "$ARTIFACT_PATH" || {
  echo "ERROR: Failed to create parent directory"
  exit 1
}
echo "content" > "$ARTIFACT_PATH"
```

### 4. Document Lazy Creation Pattern

**Recommendation**: Add clear documentation to command files explaining lazy creation.

**Template**:
```bash
# DIRECTORY CREATION: Lazy Pattern
# - Topic root created by create_topic_structure()
# - Subdirectories created on-demand by ensure_artifact_directory()
# - No eager subdirectory creation (reduces empty dirs by 400-500)
```

### 5. Remove Legacy Eager Creation

**Recommendation**: Audit and remove all instances of eager subdirectory creation except:
- Fallback for topic root creation (not subdirectories)
- Explicit user-requested directory structures

**Files to Update**:
- `/home/benjamin/.config/.claude/commands/orchestrate.md` (line 485)
- `/home/benjamin/.config/.claude/commands/supervise.md` (line 602)
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 1002-1020)

## References

### Library Implementation
- **Lazy creation utility**: `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:239-250` (`ensure_artifact_directory()`)
- **Topic structure creation**: `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:271-284` (`create_topic_structure()`)
- **Research subdirectory creation**: `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:473-479` (within `create_research_subdirectory()`)

### Command Implementations

**Lazy Creation (Good)**:
- `/plan`: `/home/benjamin/.config/.claude/commands/plan.md:254` (uses `ensure_artifact_directory()`)
- `/implement`: `/home/benjamin/.config/.claude/commands/implement.md:1038` (uses `ensure_artifact_directory()`)
- `/debug`: `/home/benjamin/.config/.claude/commands/debug.md:422` (uses `ensure_artifact_directory()`)
- `/report`: `/home/benjamin/.config/.claude/commands/report.md:140` (creates subdirectory on-demand)

**Eager Creation (Needs Fixing)**:
- `/orchestrate`: `/home/benjamin/.config/.claude/commands/orchestrate.md:485` (creates all subdirs in fallback)
- `/supervise`: `/home/benjamin/.config/.claude/commands/supervise.md:602` (creates all subdirs in fallback)
- `/plan` fallback: `/home/benjamin/.config/.claude/commands/plan.md:1003-1004` (creates all subdirs when location fails)

### Documentation
- **Directory protocols**: `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md:67-89` (lazy creation section)
- **Library API reference**: `/home/benjamin/.config/.claude/docs/reference/library-api.md:157-196` (`ensure_artifact_directory()` documentation)
- **Design philosophy**: `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:10-14` (library header comments)
