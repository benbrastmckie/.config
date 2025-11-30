# Research Report: Refactor /todo --clean Command

## Metadata
- **Date**: 2025-11-29
- **Research Topic**: Refactor /todo --clean command to remove the 30-day age criteria. When running /todo --clean: 1) Read TODO.md to identify all projects in Completed, Superseded, and Abandoned sections, 2) Commit any uncommitted changes to git first, 3) Remove those project directories from .claude/specs/ directory
- **Complexity**: 3
- **Status**: Planning In Progress
- **Plan**: [../plans/001-todo-clean-refactor-plan.md](../plans/001-todo-clean-refactor-plan.md)

## Executive Summary

This research examines refactoring the `/todo --clean` command to change from a plan-generation approach to direct directory removal based on TODO.md section classification. The current implementation generates a cleanup plan that must be executed via `/build`, applies a 30-day age threshold, and only targets "completed" status projects. The proposed refactoring will:

1. **Directly execute cleanup** (not generate a plan)
2. **Remove age-based filtering** (clean ALL eligible projects regardless of age)
3. **Target three TODO.md sections**: Completed, Abandoned, AND Superseded
4. **Add git verification** (ensure no uncommitted changes before removal)
5. **Preserve TODO.md** (do NOT modify TODO.md during cleanup)

**Key Findings**:
- Current implementation exists in plan 971 but is NOT STARTED
- The existing plan keeps the plan-generation approach (different from current requirement)
- Library functions exist but need modification to support direct execution
- TODO.md has 6 sections with ~200 eligible projects across Completed, Abandoned, and Superseded
- Git verification is critical to prevent data loss
- Archive approach safer than permanent deletion

## Research Findings

### 1. Current /todo Command Implementation

**File**: `/home/benjamin/.config/.claude/commands/todo.md`

**Command Structure**:

The `/todo` command has two operational modes:

**Default Mode** (no --clean flag):
- Block 1 (lines 58-217): Setup and Discovery
  - Parses flags (`--clean`, `--dry-run`)
  - Detects project directory (git-based or directory traversal)
  - Sources three-tier library pattern
  - Scans specs/ for topic directories (`[0-9][0-9][0-9]_*` pattern)
  - Collects plan files into JSON array

- Block 2a-2c (lines 220-439): Status Classification
  - Hard barrier pattern with todo-analyzer subagent
  - Batch classification of all discovered plans
  - Verification checkpoint ensures results exist

- Block 3-4 (lines 441-616): Generate and Write TODO.md
  - Generates TODO.md content from classified plans
  - Preserves Backlog section (manually curated)
  - Applies checkbox conventions and date grouping

**Clean Mode** (--clean flag, lines 618-652):
- **Current behavior**: Invokes plan-architect agent to generate cleanup plan
- **Plan structure**: 4 phases (archive creation, directory moves, TODO.md update, verification)
- **Age threshold**: 30 days (hardcoded in `filter_completed_projects()`)
- **Target status**: Completed only (not abandoned or superseded)
- **Execution**: Requires subsequent `/build <plan>` command

**Critical Code Section** (lines 618-652):
```markdown
## Clean Mode (--clean flag)

If CLEAN_MODE is true, instead of updating TODO.md, generate a cleanup plan
for completed projects older than 30 days.

**EXECUTE IF CLEAN_MODE=true**: Generate cleanup plan via plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Generate cleanup plan for completed projects"
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    Generate a cleanup plan for completed projects.

    Input:
    - completed_projects: List of projects with status=completed
    - age_threshold: 30 days
    - archive_path: ${CLAUDE_PROJECT_DIR}/.claude/archive/completed_$(date +%Y%m%d)/

    Create a plan with phases:
    1. Create archive manifest
    2. Move completed project directories to archive
    3. Update TODO.md (move entries to Completed section)
    4. Verify cleanup success
```

**Issues with Current Approach**:
1. **Two-step process**: Requires plan generation + `/build` execution
2. **Age-based filtering**: Only removes projects older than 30 days
3. **Limited scope**: Only targets "completed" status (misses abandoned/superseded)
4. **TODO.md modification**: Phase 3 updates TODO.md (removes entries)
5. **No git verification**: Doesn't check for uncommitted changes before cleanup

### 2. Existing Plan 971 Analysis

**Plan File**: `/home/benjamin/.config/.claude/specs/971_refactor_todo_clean_command/plans/001-refactor-todo-clean-command-plan.md`

**Status**: [NOT STARTED]

**Key Characteristics**:
- **Approach**: KEEPS plan-generation workflow (not direct execution)
- **Filtering**: Removes 30-day age threshold, adds superseded status
- **Git verification**: Adds Phase 0 for git commit verification
- **Phases**: 5 phases (Phase 0: Git check, Phase 1: Archive, Phase 2: Moves, Phase 3: TODO.md update, Phase 4: Verify)
- **TODO.md handling**: Plan DOES modify TODO.md (removes archived entries)

**Differences from Current Requirement**:

| Aspect | Plan 971 | Current Requirement |
|--------|----------|---------------------|
| Execution | Generate plan → `/build` | Direct execution |
| TODO.md | Modified by plan | NOT modified |
| Git verification | In generated plan (Phase 0) | Pre-cleanup check |
| Age threshold | Removed ✓ | Removed ✓ |
| Target sections | Completed + Abandoned + Superseded ✓ | Completed + Superseded + Abandoned ✓ |

**Conclusion**: Plan 971 is NOT aligned with current requirements. Current requirement calls for:
1. Direct execution (not plan generation)
2. TODO.md preservation (not modification)
3. Git verification before cleanup (not during plan execution)

### 3. TODO.md Structure and Section Classification

**File**: `/home/benjamin/.config/.claude/TODO.md`

**Section Hierarchy** (from todo-organization-standards.md):

| Section | Purpose | Auto-Updated | Checkbox | Target for Cleanup |
|---------|---------|--------------|----------|-------------------|
| In Progress | Plans currently being implemented | Yes | `[x]` | No |
| Not Started | Plans created but not started | Yes | `[ ]` | No |
| Backlog | Manually curated future ideas | No (preserved) | `[ ]` | No |
| **Superseded** | Replaced by newer plans | Yes | `[~]` | **Yes** |
| **Abandoned** | Intentionally stopped | Yes | `[x]` | **Yes** |
| **Completed** | Successfully finished | Yes | `[x]` | **Yes** |

**Current TODO.md Statistics**:
- In Progress: 0 entries (empty section)
- Not Started: 5 entries
- Backlog: ~8-10 manually curated items
- **Superseded**: ~3 entries → **CLEANUP TARGET**
- **Abandoned**: ~20 entries → **CLEANUP TARGET**
- **Completed**: ~170 entries → **CLEANUP TARGET**

**Total Cleanup Candidates**: ~193 entries across three sections

**Entry Format Example**:
```markdown
- [x] **Fix /repair command spec numbering** - Implement timestamp-based topic naming
  [.claude/specs/961_repair_spec_numbering_allocation/plans/001-repair-spec-numbering-allocation-plan.md]
  - 4 phases complete: Direct timestamp naming replaces LLM-based naming
```

**Directory Mapping**:
- Entry path: `.claude/specs/{NNN_topic}/plans/*.md`
- Directory to remove: `$CLAUDE_PROJECT_DIR/.claude/specs/{NNN_topic}/`
- Example: `961_repair_spec_numbering_allocation/` → full path to remove

### 4. TODO.md Entry to Directory Mapping

**Directory Naming Convention**:
```
specs/
├── {NNN_topic_name}/
│   ├── plans/
│   │   └── 001-plan-name.md
│   ├── reports/
│   │   └── 001-report.md
│   ├── summaries/
│   │   └── 001-summary.md
│   ├── outputs/
│   └── debug/
```

**Pattern**: `{3-digit-number}_{topic_name}`

**Extraction Algorithm**:

From TODO.md entry:
```markdown
- [x] **Title** - Description [.claude/specs/961_repair/plans/001-plan.md]
```

Extract topic directory:
1. Parse path between brackets: `.claude/specs/961_repair/plans/001-plan.md`
2. Extract parent directory of `plans/`: `961_repair`
3. Construct full path: `$CLAUDE_PROJECT_DIR/.claude/specs/961_repair/`

**Validation Requirements**:
- Directory MUST exist (error if missing)
- Directory MUST be within `$CLAUDE_SPECS_ROOT` (security check)
- Directory MUST match pattern `[0-9][0-9][0-9]_*` (safety check)

**Current Specs Directory Count**:
```bash
ls -la /home/benjamin/.config/.claude/specs/ | grep "^d" | wc -l
# Result: 195 topic directories
```

**Gap Analysis**: 195 directories vs ~193 TODO.md entries
- Indicates ~2 directories without TODO.md entries (orphaned or in-progress)
- Cleanup should only target directories with entries in target sections

### 5. Library Functions for Cleanup

**File**: `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh`

**Existing Functions**:

#### `scan_project_directories()` (Lines 70-84)
- Discovers all topic directories in specs/
- Pattern: `[0-9][0-9][0-9]_*`
- Returns: Newline-separated topic names
- Status: ✓ Working, no changes needed

#### `find_plans_in_topic()` (Lines 94-107)
- Finds plan files within a topic's plans/ directory
- Returns: Absolute plan file paths
- Status: ✓ Working, no changes needed

#### `categorize_plan()` (Lines 234-261)
- Maps status to TODO.md section
- Returns: Section name (In Progress, Completed, etc.)
- Status: ✓ Working, no changes needed

#### `filter_completed_projects()` (Lines 717-768)
- **Purpose**: Filter completed projects older than age threshold
- **Current implementation**:
  - Filters ONLY `status == "completed"`
  - Applies age threshold (default 30 days)
  - Uses file modification time (`stat`)
- **Limitations**:
  - Missing "abandoned" and "superseded" statuses
  - Age-based filtering not needed for new requirement
- **Replacement needed**: New function to filter by TODO.md section

#### `generate_cleanup_plan()` (Lines 770-893)
- **Purpose**: Generate 4-phase cleanup plan
- **Current implementation**:
  - Creates plan content as markdown
  - Includes phases: archive, moves, TODO.md update, verification
  - Returns plan content string
- **Limitation**: Generates plan (not direct execution)
- **Not needed**: New requirement calls for direct execution

**Functions to Add**:

#### `parse_topic_from_path()` (NEW)
```bash
# Purpose: Extract topic directory name from plan file path in TODO.md entry
# Arguments:
#   $1 - TODO.md entry line
# Returns: Topic directory name (e.g., "961_repair_spec_numbering")
# Example:
#   entry="- [x] **Title** [.claude/specs/961_test/plans/001.md]"
#   topic=$(parse_topic_from_path "$entry")
#   # Returns: "961_test"
```

#### `verify_git_status()` (NEW)
```bash
# Purpose: Check if directory has uncommitted changes
# Arguments:
#   $1 - Directory path
#   $2 - Project root path
# Returns: Exit code 0 (clean) or 1 (uncommitted changes)
# Implementation:
#   cd "$project_root"
#   git status --porcelain "$directory_path" 2>/dev/null
#   [ -z "$output" ] # Empty = clean
```

#### `remove_project_directory()` (NEW)
```bash
# Purpose: Safely remove/archive project directory
# Arguments:
#   $1 - Topic directory path
#   $2 - Archive directory path
#   $3 - Dry run flag (true/false)
# Returns: Exit code 0 (success) or 1 (failure)
# Safety checks:
#   - Validate directory exists
#   - Ensure within specs/ root
#   - Move to archive (not delete)
#   - Log operation
```

#### `extract_todo_section()` (NEW)
```bash
# Purpose: Extract entries from specific TODO.md section
# Arguments:
#   $1 - TODO.md file path
#   $2 - Section name (e.g., "Completed", "Abandoned")
# Returns: Newline-separated entry lines
# Implementation:
#   sed -n '/^## Section$/,/^## /p' | grep "^- \["
```

### 6. Git Verification Requirements

**Requirement**: "Commit any uncommitted changes to git first"

**Interpretation**:
1. Before removing a directory, check if it contains uncommitted changes
2. If uncommitted changes exist:
   - Option A: Automatically commit changes (risky - user may not want this)
   - Option B: Skip directory and warn user (safer)
   - Option C: Abort entire cleanup and prompt user (safest)

**Recommended Approach**: Option B (Skip and Warn)
- Check each candidate directory for uncommitted changes
- Skip directories with uncommitted changes
- Log warnings with directory names
- Continue cleanup for other directories
- Report skipped directories in summary

**Git Status Check Pattern**:
```bash
verify_git_status() {
  local dir_path="$1"
  local project_root="$2"

  # Change to project root
  cd "$project_root" || return 1

  # Get relative path from project root
  local rel_path="${dir_path#$project_root/}"

  # Check for uncommitted changes
  local git_status
  git_status=$(git status --porcelain "$rel_path" 2>/dev/null)

  if [ -n "$git_status" ]; then
    # Uncommitted changes detected
    echo "WARNING: Uncommitted changes in $rel_path" >&2
    return 1
  fi

  # Clean directory
  return 0
}
```

**Edge Cases**:
1. **Not in git repo**: Skip git check, proceed with cleanup (log warning)
2. **Git not installed**: Skip git check, proceed with cleanup (log warning)
3. **Directory not tracked by git**: Treat as clean (no changes to commit)
4. **Uncommitted changes in parent specs/**: Don't affect individual directory checks

### 7. Proposed Direct Execution Workflow

**New --clean Behavior**:

```bash
/todo --clean [--dry-run]
```

**Execution Flow**:

1. **Read TODO.md** (parse file, extract sections)
2. **Identify cleanup candidates** (entries in Completed, Abandoned, Superseded sections)
3. **Extract directory paths** (parse entry lines, get topic directories)
4. **Git verification** (check each directory for uncommitted changes)
5. **Filter to safe directories** (exclude directories with uncommitted changes)
6. **Archive creation** (create timestamped archive directory)
7. **Remove directories** (move to archive, not delete)
8. **Log operations** (error log integration)
9. **Generate summary** (removed count, skipped count, archive path)

**Key Differences from Current Implementation**:

| Aspect | Current (Plan Generation) | Proposed (Direct Execution) |
|--------|--------------------------|----------------------------|
| Action | Generate cleanup plan | Execute directory removal |
| Execution | Requires `/build` command | Immediate execution |
| TODO.md | Modified (Phase 3) | **NOT modified** |
| Archive | Creates manifest | Simple move to archive/ |
| Target Sections | Completed only | Completed + Abandoned + Superseded |
| Age Threshold | 30 days (hardcoded) | **None** (all eligible projects) |
| Git Check | In plan (Phase 0) | Pre-cleanup verification |

**Expected Output**:
```
=== /todo --clean Command ===

Mode: Clean
Dry Run: false

Reading TODO.md...
Found 3 target sections: Completed, Abandoned, Superseded

Extracting cleanup candidates...
  Completed: 170 entries
  Abandoned: 20 entries
  Superseded: 3 entries
Total candidates: 193 directories

Verifying git status...
  Clean: 185 directories
  Uncommitted changes: 8 directories (skipped)
    - 961_repair_spec_numbering_allocation
    - 965_test_project
    ... (6 more)

Creating archive directory...
  Archive: /home/user/.claude/archive/cleaned_20251129_172530/

Removing directories...
  ✓ Archived: 102_plan_command_error_analysis
  ✓ Archived: 787_state_machine_persistence_bug
  ✓ Archived: 788_commands_readme_update
  ... (182 more)

=== Cleanup Summary ===
Removed: 185 directories
Skipped: 8 directories (uncommitted changes)
Preserved: 10 directories (in progress, not started, backlog)
Archive: /home/user/.claude/archive/cleaned_20251129_172530/

Next Steps:
  • Run /todo to update TODO.md (entries for removed directories will disappear)
  • Review archive: ls .claude/archive/cleaned_20251129_172530/
  • Restore if needed: mv archive/cleaned_*/NNN_topic/ specs/
```

### 8. Archive vs Delete Strategy

**Options**:

**Option A: Move to Archive** (RECOMMENDED)
- Create timestamped directory: `archive/cleaned_YYYYMMDD_HHMMSS/`
- Move directories: `mv specs/{topic}/ archive/cleaned_*/`
- Advantages:
  - Full recovery possible
  - No data loss risk
  - Audit trail preserved
- Disadvantages:
  - Disk space usage
  - Manual cleanup needed eventually

**Option B: Permanent Delete**
- Direct removal: `rm -rf specs/{topic}/`
- Advantages:
  - Immediate disk space recovery
  - No archive management needed
- Disadvantages:
  - Irreversible data loss
  - No recovery option
  - High risk if error occurs

**Option C: Git-based Archive**
- Commit directories to git before removal
- Delete after commit
- Advantages:
  - Recoverable via git history
  - No separate archive directory
- Disadvantages:
  - Git history bloat
  - Harder to recover
  - Doesn't work for untracked files

**Recommendation**: Option A (Move to Archive)
- Safest approach
- Aligns with existing archive pattern in project
- Easy recovery procedure
- Can add archive rotation policy later

**Archive Structure**:
```
.claude/
├── archive/
│   ├── cleaned_20251129_172530/
│   │   ├── 102_plan_command_error_analysis/
│   │   ├── 787_state_machine_persistence_bug/
│   │   ├── 788_commands_readme_update/
│   │   └── ... (185 more)
│   └── cleaned_20251130_093045/
│       └── ... (future cleanups)
└── specs/
    ├── 969_repair_plan_20251129_155633/  (preserved - in progress)
    ├── 970_build_command_streamline/      (preserved - in progress)
    └── ... (remaining projects)
```

### 9. TODO.md Handling Strategy

**Requirement**: "Remove directories from .claude/specs/ directory" (does NOT mention modifying TODO.md)

**Interpretation**: TODO.md should NOT be modified by `--clean`

**Workflow**:
1. `/todo --clean` removes directories from specs/
2. `/todo` (without flags) scans specs/ and regenerates TODO.md
3. Entries for removed directories disappear naturally (no plan files found)

**Advantages**:
- **Separation of concerns**: Cleanup vs status tracking
- **Idempotent**: Running `/todo` after cleanup syncs TODO.md automatically
- **Safer**: No risk of TODO.md corruption during cleanup
- **Clearer workflow**: Two distinct operations

**Alternative Approach** (NOT RECOMMENDED):
- Modify TODO.md during cleanup (remove entries from target sections)
- Issues:
  - More complex implementation
  - Risk of TODO.md corruption if cleanup fails mid-operation
  - Inconsistent with "only remove directories" requirement

**Recommended Workflow**:
```bash
# Step 1: Clean up specs/ directory
/todo --clean

# Step 2: Update TODO.md to reflect current state
/todo

# Result: TODO.md no longer shows entries for removed directories
```

### 10. Implementation Approach

**Command Changes** (todo.md):

**Replace Clean Mode Section** (lines 618-652):

**Current**:
```markdown
## Clean Mode (--clean flag)

If CLEAN_MODE is true, instead of updating TODO.md, generate a cleanup plan
for completed projects older than 30 days.

**EXECUTE IF CLEAN_MODE=true**: Generate cleanup plan via plan-architect agent.
```

**Proposed**:
```markdown
## Clean Mode (--clean flag)

If CLEAN_MODE is true, directly remove project directories from specs/ based on
TODO.md section classification (Completed, Abandoned, Superseded).

**EXECUTE IF CLEAN_MODE=true**: Execute cleanup via Block 5.

## Block 5: Directory Cleanup (Clean Mode Only)

```bash
# Execute only if CLEAN_MODE=true

# Restore state from Block 2c
STATE_FILE=$(ls -t ~/.claude/data/state/todo_*.state 2>/dev/null | head -1)
source "$STATE_FILE" 2>/dev/null || exit 1

TODO_PATH="${CLAUDE_PROJECT_DIR}/.claude/TODO.md"
ARCHIVE_DIR="${CLAUDE_PROJECT_DIR}/.claude/archive/cleaned_$(date +%Y%m%d_%H%M%S)"

# Read TODO.md and extract cleanup candidates
cleanup_candidates=()

# Extract entries from Completed section
while IFS= read -r entry; do
  # Parse topic directory from entry path
  topic=$(echo "$entry" | grep -oP '\.claude/specs/\K[0-9]{3}_[^/]+')
  [ -n "$topic" ] && cleanup_candidates+=("$topic")
done < <(sed -n '/^## Completed$/,/^## /p' "$TODO_PATH" | grep "^- \[")

# Extract entries from Abandoned section
while IFS= read -r entry; do
  topic=$(echo "$entry" | grep -oP '\.claude/specs/\K[0-9]{3}_[^/]+')
  [ -n "$topic" ] && cleanup_candidates+=("$topic")
done < <(sed -n '/^## Abandoned$/,/^## /p' "$TODO_PATH" | grep "^- \[")

# Extract entries from Superseded section
while IFS= read -r entry; do
  topic=$(echo "$entry" | grep -oP '\.claude/specs/\K[0-9]{3}_[^/]+')
  [ -n "$topic" ] && cleanup_candidates+=("$topic")
done < <(sed -n '/^## Superseded$/,/^## /p' "$TODO_PATH" | grep "^- \[")

# Git verification and filtering
safe_dirs=()
skipped_dirs=()

for topic in "${cleanup_candidates[@]}"; do
  dir_path="${SPECS_ROOT}/${topic}"

  # Verify git status
  if verify_git_status "$dir_path" "$CLAUDE_PROJECT_DIR"; then
    safe_dirs+=("$topic")
  else
    skipped_dirs+=("$topic")
  fi
done

# Create archive directory
if [ "$DRY_RUN" = "false" ]; then
  mkdir -p "$ARCHIVE_DIR"
fi

# Remove safe directories
removed_count=0
for topic in "${safe_dirs[@]}"; do
  dir_path="${SPECS_ROOT}/${topic}"

  if [ "$DRY_RUN" = "true" ]; then
    echo "[DRY RUN] Would archive: $topic"
  else
    mv "$dir_path" "$ARCHIVE_DIR/"
    echo "Archived: $topic"
    removed_count=$((removed_count + 1))
  fi
done

# Generate summary
echo ""
echo "=== Cleanup Summary ==="
echo "Removed: ${removed_count} directories"
echo "Skipped: ${#skipped_dirs[@]} directories (uncommitted changes)"
if [ ${#skipped_dirs[@]} -gt 0 ]; then
  echo ""
  echo "Skipped directories:"
  for topic in "${skipped_dirs[@]}"; do
    echo "  - $topic"
  done
fi
echo "Archive: $ARCHIVE_DIR"
echo ""
echo "Next Steps:"
echo "  • Run /todo to update TODO.md"
echo "  • Review archive: ls $ARCHIVE_DIR"
```
```

**Library Changes** (todo-functions.sh):

Add four new functions in SECTION 7:

```bash
# parse_topic_from_entry()
# Purpose: Extract topic directory name from TODO.md entry
# Arguments:
#   $1 - TODO.md entry line
# Returns: Topic directory name or empty string
parse_topic_from_entry() {
  local entry="$1"
  # Extract path pattern: .claude/specs/{NNN_topic}/
  echo "$entry" | grep -oP '\.claude/specs/\K[0-9]{3}_[^/]+' | head -1
}

# verify_git_status()
# Purpose: Check if directory has uncommitted changes
# Arguments:
#   $1 - Directory path
#   $2 - Project root path
# Returns: Exit code 0 (clean) or 1 (uncommitted changes)
verify_git_status() {
  local dir_path="$1"
  local project_root="$2"

  # Skip if git not available
  if ! command -v git &>/dev/null; then
    return 0  # Treat as clean
  fi

  # Skip if not in git repo
  if ! git -C "$project_root" rev-parse --git-dir >/dev/null 2>&1; then
    return 0  # Treat as clean
  fi

  # Get relative path
  local rel_path="${dir_path#$project_root/}"

  # Check for uncommitted changes
  local git_status
  git_status=$(cd "$project_root" && git status --porcelain "$rel_path" 2>/dev/null)

  if [ -n "$git_status" ]; then
    return 1  # Uncommitted changes
  fi

  return 0  # Clean
}

# extract_todo_section()
# Purpose: Extract entries from specific TODO.md section
# Arguments:
#   $1 - TODO.md file path
#   $2 - Section name (e.g., "Completed")
# Returns: Newline-separated entry lines
extract_todo_section() {
  local todo_path="$1"
  local section_name="$2"

  if [ ! -f "$todo_path" ]; then
    return 1
  fi

  # Extract section content between headers
  sed -n "/^## ${section_name}$/,/^## /p" "$todo_path" | grep "^- \["
}

# remove_project_directory()
# Purpose: Safely remove/archive project directory
# Arguments:
#   $1 - Topic directory path
#   $2 - Archive directory path
#   $3 - Dry run flag (true/false)
# Returns: Exit code 0 (success) or 1 (failure)
remove_project_directory() {
  local topic_path="$1"
  local archive_dir="$2"
  local dry_run="${3:-false}"

  # Validation
  if [ ! -d "$topic_path" ]; then
    echo "WARNING: Directory not found: $topic_path" >&2
    return 1
  fi

  # Ensure within specs/ root
  local specs_root="${CLAUDE_SPECS_ROOT:-${CLAUDE_PROJECT_DIR}/.claude/specs}"
  if [[ ! "$topic_path" =~ ^${specs_root}/ ]]; then
    echo "ERROR: Directory outside specs root: $topic_path" >&2
    return 1
  fi

  local topic_name=$(basename "$topic_path")

  if [ "$dry_run" = "true" ]; then
    echo "[DRY RUN] Would archive: $topic_name"
    return 0
  fi

  # Create archive directory if needed
  mkdir -p "$archive_dir"

  # Move to archive
  mv "$topic_path" "$archive_dir/"
  echo "Archived: $topic_name → $archive_dir/"

  return 0
}

# Export functions
export -f parse_topic_from_entry
export -f verify_git_status
export -f extract_todo_section
export -f remove_project_directory
```

### 11. Error Handling and Edge Cases

**Error Types**:
- `file_error`: TODO.md not found, directory not found, permission denied
- `validation_error`: Directory outside specs/, invalid path pattern
- `execution_error`: Archive creation failed, move operation failed
- `parse_error`: Cannot extract topic from TODO.md entry

**Error Handling Strategy**:
```bash
# Example: Directory removal with error handling
if ! remove_project_directory "$dir_path" "$archive_dir" "$DRY_RUN"; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "execution_error" "Failed to remove directory: $topic" \
    "Block5:DirectoryRemoval" \
    '{"topic":"'"$topic"'","archive":"'"$archive_dir"'","reason":"move failed"}'
  # Continue with next directory (don't abort)
fi
```

**Edge Cases**:

1. **TODO.md Entry Without Plan File**
   - Scenario: Entry exists but plan file deleted manually
   - Resolution: Skip directory (topic extraction returns empty)
   - Impact: No error, entry ignored

2. **Directory Already Removed**
   - Scenario: Directory doesn't exist but entry in TODO.md
   - Resolution: Log warning, continue
   - Impact: Non-fatal error, cleanup continues

3. **Uncommitted Changes in Multiple Directories**
   - Scenario: 50 out of 193 directories have uncommitted changes
   - Resolution: Skip all 50, remove remaining 143
   - Impact: Partial cleanup, user must commit changes and re-run

4. **Archive Directory Creation Fails**
   - Scenario: Disk full, permission denied
   - Resolution: Abort cleanup, log error
   - Impact: Fatal error, no directories removed

5. **TODO.md Parse Error**
   - Scenario: Malformed TODO.md (missing section headers)
   - Resolution: Extract what's possible, log warnings
   - Impact: Partial cleanup, some entries missed

6. **Concurrent /todo Execution**
   - Scenario: User runs `/todo` and `/todo --clean` simultaneously
   - Resolution: Separate workflow IDs, different state files
   - Impact: Race condition possible, but each operation independent

7. **Empty Target Sections**
   - Scenario: No entries in Completed, Abandoned, or Superseded sections
   - Resolution: Report zero candidates, no cleanup needed
   - Impact: No-op, informational message

**Recovery Procedures**:
1. **Restore from archive**: `mv archive/cleaned_*/NNN_topic/ specs/`
2. **Restore all**: `mv archive/cleaned_*/* specs/`
3. **Verify restoration**: `/todo` to regenerate TODO.md
4. **Commit changes**: Address uncommitted changes, re-run cleanup

### 12. Testing Strategy

**Unit Tests** (Library Functions):

Test `parse_topic_from_entry()`:
```bash
# Test valid entry
entry="- [x] **Title** [.claude/specs/961_test/plans/001.md]"
result=$(parse_topic_from_entry "$entry")
[ "$result" = "961_test" ] || echo "FAIL"

# Test malformed entry
entry="- [x] **Title** - No path"
result=$(parse_topic_from_entry "$entry")
[ -z "$result" ] || echo "FAIL"
```

Test `verify_git_status()`:
```bash
# Test clean directory
mkdir -p test_specs/961_test/plans
git add test_specs/961_test/plans
git commit -m "test"
verify_git_status "$PWD/test_specs/961_test" "$PWD"
[ $? -eq 0 ] || echo "FAIL: Should be clean"

# Test uncommitted changes
echo "new" > test_specs/961_test/plans/new.md
verify_git_status "$PWD/test_specs/961_test" "$PWD"
[ $? -eq 1 ] || echo "FAIL: Should detect uncommitted"
```

Test `extract_todo_section()`:
```bash
# Create test TODO.md
cat > test_todo.md <<'EOF'
## Completed
- [x] **Test 1** [path1]
- [x] **Test 2** [path2]
## Abandoned
- [x] **Test 3** [path3]
EOF

result=$(extract_todo_section "test_todo.md" "Completed")
count=$(echo "$result" | wc -l)
[ "$count" -eq 2 ] || echo "FAIL: Expected 2 entries"
```

**Integration Tests** (Command):

Test `/todo --clean --dry-run`:
```bash
# Setup: Create test TODO.md with known entries
# Execute: /todo --clean --dry-run
# Verify: Output shows "Would archive" for each candidate
# Verify: No actual file operations performed
```

Test `/todo --clean` (actual execution):
```bash
# Setup: Create test specs/ with known directories
# Execute: /todo --clean
# Verify: Archive directory created
# Verify: Directories moved to archive
# Verify: Summary shows correct counts
```

Test git verification:
```bash
# Setup: Create directory with uncommitted changes
# Execute: /todo --clean
# Verify: Directory skipped
# Verify: Warning logged
# Verify: Summary shows skipped count
```

**Error Handling Tests**:

Test directory outside specs/:
```bash
# Setup: Craft TODO.md entry with path outside specs/
# Execute: /todo --clean
# Verify: Error logged, directory not removed
```

Test permission denied:
```bash
# Setup: Create read-only directory
# Execute: /todo --clean
# Verify: Error logged, continue with other directories
```

Test archive creation failure:
```bash
# Setup: Make archive/ read-only
# Execute: /todo --clean
# Verify: Fatal error, cleanup aborted
```

### 13. Documentation Requirements

**Files to Update**:

1. **Command File** (todo.md):
   - Update Clean Mode description (lines 618-652)
   - Add Block 5 for direct execution
   - Document git verification
   - Add --dry-run examples
   - Update eligible sections list

2. **Command Guide** (todo-command-guide.md):
   - Update "Clean Mode" section
   - Document direct execution workflow
   - Add troubleshooting for uncommitted changes
   - Document archive management
   - Add recovery procedures

3. **Library Documentation** (todo-functions.sh):
   - Add doc headers for 4 new functions
   - Follow existing doc pattern (Purpose, Arguments, Returns)
   - Add usage examples

4. **Standards Documentation** (todo-organization-standards.md):
   - Update "Usage by Commands" section
   - Document /todo --clean behavior
   - Clarify TODO.md preservation

**Documentation Standards**:
- Follow CommonMark specification
- Use clear, concise language
- Include code examples with syntax highlighting
- No emojis in file content (UTF-8 encoding issues)
- Document WHAT code does, not WHY

## Recommendations

### Immediate Actions

1. **Implement Direct Execution**
   - Replace plan-generation in Clean Mode section
   - Add Block 5 for directory removal
   - Filter by TODO.md sections (not age threshold)
   - Archive to timestamped directory

2. **Add Library Functions**
   - `parse_topic_from_entry()`: Extract directory from entry
   - `verify_git_status()`: Check for uncommitted changes
   - `extract_todo_section()`: Parse TODO.md sections
   - `remove_project_directory()`: Safe removal with archive

3. **Git Verification**
   - Check each directory before removal
   - Skip directories with uncommitted changes
   - Warn user about skipped directories
   - Continue cleanup for clean directories

4. **Preserve TODO.md**
   - Do NOT modify TODO.md during cleanup
   - Document workflow: `/todo --clean` → `/todo`
   - Entries disappear naturally when dirs removed

5. **Enhance Safety**
   - Archive to `archive/cleaned_{timestamp}/`
   - Validate all directory paths (must be within specs/)
   - Log all operations to error log
   - Support --dry-run for preview

### Implementation Phases

**Phase 1: Library Functions** (2 hours)
- Add 4 new functions to todo-functions.sh
- Implement git verification logic
- Add unit tests

**Phase 2: Command Update** (3 hours)
- Replace Clean Mode section in todo.md
- Add Block 5 for direct execution
- Integrate git verification
- Add error handling

**Phase 3: Documentation** (2 hours)
- Update todo-command-guide.md
- Update inline documentation
- Add troubleshooting guide
- Document recovery procedures

**Phase 4: Testing** (2 hours)
- Integration tests with real specs/ directory
- Test git verification scenarios
- Test error handling
- Validate with --dry-run

**Total Effort**: 9 hours (Complexity 3)

### Future Enhancements

1. **Configurable Age Threshold** (Optional)
   - Add `--age-threshold <days>` flag
   - Default: remove all (no threshold)
   - Example: `/todo --clean --age-threshold 30`

2. **Selective Cleanup** (Optional)
   - Add `--completed-only`, `--abandoned-only`, `--superseded-only` flags
   - Allow targeting specific sections
   - Example: `/todo --clean --completed-only`

3. **Archive Management** (Optional)
   - Add `--list-archives` to show archived cleanups
   - Add `--restore <archive>` to restore from specific archive
   - Add archive rotation policy (delete old archives)

4. **Interactive Mode** (Optional)
   - Show list of candidates with descriptions
   - Prompt for confirmation per directory
   - Example: `/todo --clean --interactive`

5. **Auto-commit** (Optional but Risky)
   - Add `--auto-commit` flag
   - Automatically commit uncommitted changes before cleanup
   - Requires careful implementation (commit message generation)

## Success Criteria

1. **Functional Requirements**:
   - `/todo` (no flags) updates TODO.md only ✓
   - `/todo --clean` removes directories from specs/ ✓
   - `/todo --clean --dry-run` previews without execution ✓
   - Target sections: Completed, Abandoned, Superseded ✓
   - No age-based filtering (all eligible projects) ✓

2. **Safety Requirements**:
   - Git verification before removal ✓
   - Skip directories with uncommitted changes ✓
   - Archive (not delete) removed directories ✓
   - Validate directory paths (within specs/) ✓
   - Error log captures all operations ✓

3. **Usability Requirements**:
   - Clear summary output (removed, skipped, archive path) ✓
   - Recovery instructions provided ✓
   - Dry-run preview matches actual execution ✓
   - Warning for skipped directories ✓

4. **Documentation Requirements**:
   - Updated command guide ✓
   - Updated function documentation ✓
   - Troubleshooting guide ✓
   - Recovery procedures documented ✓

## Conclusion

The refactoring of `/todo --clean` from plan-generation to direct execution is feasible and beneficial. The current Plan 971 exists but is NOT aligned with requirements (keeps plan-generation approach, modifies TODO.md).

**Key Benefits**:
1. **Simpler workflow**: One-step cleanup vs two-step (generate + execute)
2. **Clearer separation**: TODO.md sync (default) vs directory cleanup (--clean)
3. **More comprehensive**: Removes completed, abandoned, AND superseded projects
4. **No age filtering**: Cleans all eligible projects (not just old ones)
5. **Safer execution**: Git verification, archive approach, dry-run preview

**Implementation Approach**:
1. Add 4 library functions (parse, verify, extract, remove)
2. Replace Clean Mode section with Block 5 (direct execution)
3. Integrate git verification (skip uncommitted directories)
4. Archive to timestamped directory (not delete)
5. Preserve TODO.md (do NOT modify during cleanup)
6. Update documentation and tests

**Effort**: 9 hours (Complexity 3)

**Risk**: Low
- Archive approach allows full recovery
- Git verification prevents data loss
- Dry-run preview validates before execution
- Error logging provides audit trail

**Next Steps**:
1. Create implementation plan with 4 phases
2. Implement library functions
3. Update command Clean Mode section
4. Update documentation
5. Add integration tests
6. Validate with --dry-run on production specs/

## Appendix A: Comparison Matrix

| Feature | Current Impl | Plan 971 | Proposed Impl |
|---------|-------------|----------|---------------|
| **Execution Model** | Plan generation | Plan generation | Direct execution |
| **Workflow Steps** | 2 steps (/todo, /build) | 2 steps | 1 step (/todo --clean) |
| **TODO.md Handling** | Modified by plan | Modified by plan | NOT modified |
| **Age Filtering** | 30 days | None | None |
| **Target Sections** | Completed only | Completed + Abandoned + Superseded | Completed + Abandoned + Superseded |
| **Git Verification** | Not implemented | In plan (Phase 0) | Pre-cleanup check |
| **Archive Approach** | Yes (with manifest) | Yes (with manifest) | Yes (simple move) |
| **Dry-run Support** | Via plan preview | Via plan preview | Direct preview |
| **Error Logging** | Limited | Via plan execution | Integrated |
| **Recovery** | Via archive | Via archive | Via archive |

## Appendix B: File Inventory

**Commands**:
- `/home/benjamin/.config/.claude/commands/todo.md` (672 lines)

**Libraries**:
- `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh` (916 lines)
- `/home/benjamin/.config/.claude/lib/core/error-handling.sh`
- `/home/benjamin/.config/.claude/lib/core/unified-location-detection.sh`

**Agents**:
- `/home/benjamin/.config/.claude/agents/todo-analyzer.md` (451 lines)

**Documentation**:
- `/home/benjamin/.config/.claude/docs/guides/commands/todo-command-guide.md` (389 lines)
- `/home/benjamin/.config/.claude/docs/reference/standards/todo-organization-standards.md` (285 lines)

**Data Files**:
- `/home/benjamin/.config/.claude/TODO.md` (296 lines)
- `/home/benjamin/.config/.claude/specs/` (195 directories, ~193 eligible for cleanup)

**Existing Plans** (NOT aligned with current requirement):
- `/home/benjamin/.config/.claude/specs/971_refactor_todo_clean_command/plans/001-refactor-todo-clean-command-plan.md`
- `/home/benjamin/.config/.claude/specs/971_refactor_todo_clean_command/reports/001-refactor-todo-clean-command-research.md`
- `/home/benjamin/.config/.claude/specs/971_refactor_todo_clean_command/reports/002-plan-revision-insights.md`

## Appendix C: Implementation Checklist

**Library Changes**:
- [ ] Add `parse_topic_from_entry()` function
- [ ] Add `verify_git_status()` function
- [ ] Add `extract_todo_section()` function
- [ ] Add `remove_project_directory()` function
- [ ] Export all 4 new functions
- [ ] Add function documentation headers
- [ ] Add unit tests

**Command Changes**:
- [ ] Replace Clean Mode section description
- [ ] Add Block 5 for direct execution
- [ ] Implement TODO.md parsing (3 sections)
- [ ] Implement git verification loop
- [ ] Implement directory removal loop
- [ ] Add archive directory creation
- [ ] Add error handling and logging
- [ ] Add summary generation
- [ ] Preserve --dry-run flag handling

**Documentation Changes**:
- [ ] Update todo-command-guide.md Clean Mode section
- [ ] Add troubleshooting for uncommitted changes
- [ ] Add archive management documentation
- [ ] Add recovery procedures
- [ ] Update todo.md inline documentation
- [ ] Update function documentation headers

**Testing**:
- [ ] Unit tests for parse_topic_from_entry()
- [ ] Unit tests for verify_git_status()
- [ ] Unit tests for extract_todo_section()
- [ ] Unit tests for remove_project_directory()
- [ ] Integration test: /todo --clean --dry-run
- [ ] Integration test: /todo --clean (actual execution)
- [ ] Integration test: Git verification with uncommitted changes
- [ ] Integration test: Error handling scenarios
- [ ] Validation test: --dry-run matches actual execution
- [ ] Validation test: TODO.md preservation (/todo --clean does NOT modify TODO.md)

**Validation**:
- [ ] Run --dry-run on production specs/ directory
- [ ] Verify candidate count matches expectation (~193)
- [ ] Verify git verification detects uncommitted changes
- [ ] Verify archive directory structure
- [ ] Verify error logging integration
- [ ] Verify summary output format
- [ ] Test recovery procedure (restore from archive)
