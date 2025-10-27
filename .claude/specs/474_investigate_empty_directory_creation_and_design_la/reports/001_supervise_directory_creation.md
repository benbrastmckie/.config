# /supervise Command Directory Creation Research

## Overview

The `/supervise` command creates topic directory structure during **Phase 0** (lines 587-622 in `/home/benjamin/.config/.claude/commands/supervise.md`). It calls the `create_topic_structure()` function from the `topic-utils.sh` library, which creates all 6 standard subdirectories (reports, plans, summaries, debug, scripts, outputs) upfront before any agents are invoked. This ensures a consistent directory structure for all workflows, regardless of which artifacts will actually be created.

## Research Findings

### Where Directory Creation Occurs

**File**: `/home/benjamin/.config/.claude/commands/supervise.md`
**Section**: Phase 0 - Project Location and Path Pre-Calculation
**Lines**: 587-622 (STEP 5: Create topic directory structure)

The relevant code is:
```bash
TOPIC_PATH="${SPECS_ROOT}/${TOPIC_NUM}_${TOPIC_NAME}"

echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - Topic Directory Creation"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Creating topic directory structure at: $TOPIC_PATH"
echo ""

# Create topic structure using utility function (includes verification)
if ! create_topic_structure "$TOPIC_PATH"; then
  echo "❌ CRITICAL ERROR: Topic directory not created at $TOPIC_PATH"
  echo ""
  echo "FALLBACK MECHANISM: Attempting manual directory creation..."
  mkdir -p "$TOPIC_PATH"/{reports,plans,summaries,debug,scripts,outputs}

  # Re-verification
  if [ ! -d "$TOPIC_PATH" ]; then
    echo "❌ FATAL: Fallback failed - directory creation impossible"
    echo ""
    echo "Workflow TERMINATED."
    exit 1
  fi

  echo "✅ FALLBACK SUCCESSFUL: Topic directory created manually"
fi

echo "✅ VERIFIED: Topic directory exists at $TOPIC_PATH"
echo "   All 6 subdirectories verified: reports, plans, summaries, debug, scripts, outputs"
echo ""
```

### The `create_topic_structure()` Function

**File**: `/home/benjamin/.config/.claude/lib/topic-utils.sh`
**Lines**: 63-90

The function implementation:
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

### What Directories Are Created

All 6 standard subdirectories are created upfront:
1. **reports/** - Research reports (gitignored)
2. **plans/** - Implementation plans (gitignored)
3. **summaries/** - Implementation summaries (gitignored)
4. **debug/** - Debug reports (COMMITTED to git)
5. **scripts/** - Investigation scripts (gitignored, temporary)
6. **outputs/** - Test outputs (gitignored, temporary)

### Why All 6 Are Created Upfront

**Design Philosophy**: The eager directory creation pattern ensures:
- **Consistent structure** across all topics
- **Simplified path pre-calculation** (Phase 0 can calculate all artifact paths knowing directories exist)
- **Verification and fallback** (the function verifies all 6 directories were created successfully)
- **Clear separation of concerns** (orchestrator calculates paths, agents write files)

**Trade-offs**:
- Creates some empty directories when workflows don't use all artifact types
- However, all directories are gitignored except debug/, so they don't clutter the repository
- The consistency benefit outweighs the minor disk space usage

### Recent Evolution: Lazy Directory Creation

**Important Note**: According to `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` (lines 67-89), as of 2025-10-24, the system has evolved to support **lazy directory creation** as an alternative pattern:

> **As of 2025-10-24**: Subdirectories are created **on-demand** when files are written, not eagerly when topics are created.

The new pattern uses `ensure_artifact_directory()` function:
```bash
# Before writing any file, ensure parent directory exists
source .claude/lib/unified-location-detection.sh
ensure_artifact_directory "$FILE_PATH" || exit 1
echo "content" > "$FILE_PATH"
```

**However**: The `/supervise` command still uses the eager pattern (`create_topic_structure()`) rather than the lazy pattern, meaning it creates all 6 directories upfront during Phase 0.

## Recommendations

### Should Directory Creation Be Lazy or Eager?

**For `/supervise` command specifically**: **EAGER (current approach) is correct**

**Reasoning**:
1. **Path pre-calculation requirement**: Phase 0 must calculate all artifact paths before invoking agents in Phase 1-6. This requires knowing the directory structure upfront.
2. **Agent behavioral injection**: Agents receive absolute file paths from the orchestrator. The orchestrator needs directories to exist to pass valid paths.
3. **Verification and fallback pattern**: The mandatory verification checkpoint (lines 607-622) requires all directories to exist immediately after creation.
4. **Workflow scope flexibility**: The command supports 4 workflow types (research-only, research-and-plan, full-implementation, debug-only). Different workflows use different subdirectories, but the orchestrator doesn't know which until after agents complete. Creating all 6 upfront simplifies the logic.

### Alternative Consideration

**For other commands** (like `/report`, `/plan`): The lazy creation pattern may be more appropriate since they:
- Create artifacts in only one subdirectory (reports/ or plans/)
- Don't need to pre-calculate paths for multiple agent invocations
- Can use `ensure_artifact_directory()` right before writing files

### Consistency vs Optimization Trade-off

**Current state**: Mixed approach
- `/supervise` uses eager creation (all 6 directories)
- Other commands may use lazy creation (one directory on-demand)

**Recommendation**: This is acceptable because:
- `/supervise` is a complex orchestrator with different requirements
- Simpler commands benefit from lazy creation
- The directory protocols documentation explicitly describes both patterns as valid
- No functional issues or significant waste (empty gitignored directories are negligible)

## References

### Source Files

- **`/supervise` command**: `/home/benjamin/.config/.claude/commands/supervise.md`
  - Phase 0 (lines 434-674): Location detection and directory creation
  - STEP 5 (lines 587-622): `create_topic_structure()` invocation with verification

- **`create_topic_structure()` function**: `/home/benjamin/.config/.claude/lib/topic-utils.sh`
  - Function definition (lines 63-90)
  - Creates all 6 standard subdirectories with verification

### Documentation

- **Directory Protocols**: `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md`
  - Lazy vs eager creation patterns (lines 67-89)
  - Topic directory structure (lines 36-65)
  - Gitignore compliance rules (lines 40-50)

### Related Libraries

- **Topic utilities**: `/home/benjamin/.config/.claude/lib/topic-utils.sh`
  - `create_topic_structure()` - Eager creation of all 6 subdirectories
  - `get_next_topic_number()` - Sequential topic numbering
  - `sanitize_topic_name()` - Topic name formatting

- **Unified location detection**: `/home/benjamin/.config/.claude/lib/unified-location-detection.sh`
  - `ensure_artifact_directory()` - Lazy creation of single subdirectory
  - `perform_location_detection()` - Complete location workflow
