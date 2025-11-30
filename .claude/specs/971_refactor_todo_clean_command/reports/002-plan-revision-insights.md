# Plan Revision Research Report: Refactor /todo --clean Command

## Metadata
- **Date**: 2025-11-29
- **Research Topic**: Plan revision insights for refactoring /todo --clean command based on new requirements
- **Complexity**: 2
- **Status**: Complete
- **Related Plan**: /home/benjamin/.config/.claude/specs/971_refactor_todo_clean_command/plans/001-refactor-todo-clean-command-plan.md

## Executive Summary

This research report provides insights for revising the /todo --clean command implementation plan based on new requirements. The key changes are:

1. **KEEP plan generation approach** - Do NOT switch to direct execution
2. **Remove 30-day age threshold** - Clean ALL eligible projects regardless of age
3. **Include "superseded" status** - Clean completed, abandoned, AND superseded projects
4. **Add git commit verification** - Check that directories have no uncommitted changes before cleanup

## Revision Requirements Analysis

### Requirement 1: Keep Plan Generation Approach

**Current Plan Status**: The existing plan (001-refactor-todo-clean-command-plan.md) proposes switching from plan generation to direct execution.

**Required Change**: REVERT to plan generation approach, keeping the current architecture.

**Current Implementation** (lines 618-652 in todo.md):
```bash
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

**What to Keep**:
- Plan-architect agent invocation
- 4-phase plan structure (archive manifest, directory moves, TODO.md update, verification)
- Archive directory approach (safer than direct deletion)
- Plan generation workflow (generate plan → user executes with /build)

**What to Change**:
- Filtering logic (include more statuses)
- Age threshold (remove it)
- Eligible statuses (add superseded)
- Add git commit verification phase

### Requirement 2: Remove 30-Day Age Threshold

**Current Implementation** (lines 717-768 in todo-functions.sh):

```bash
filter_completed_projects() {
  local plans_json="$1"
  local age_threshold="${2:-30}"  # Default 30 days

  # ... filtering logic ...

  local current_epoch
  current_epoch=$(date +%s)
  local threshold_epoch=$((current_epoch - age_threshold * 86400))

  # Filter by age (based on plan file modification time)
  while IFS= read -r plan_path; do
    # ...
    local file_epoch
    file_epoch=$(stat -c %Y "$plan_path" 2>/dev/null || stat -f %m "$plan_path" 2>/dev/null || echo "$current_epoch")

    if [ "$file_epoch" -lt "$threshold_epoch" ]; then
      # Include in cleanup
    fi
  done
}
```

**Required Change**: Remove age-based filtering entirely.

**New Approach**:
```bash
filter_cleanup_candidates() {
  local plans_json="$1"

  # Filter for eligible statuses ONLY (no age check)
  echo "$plans_json" | jq -r '[.[] | select(
    .status == "completed" or
    .status == "abandoned" or
    .status == "superseded"
  )]'
}
```

**Impact**:
- ALL eligible projects will be cleaned up, not just old ones
- Simpler logic (no stat calls, no epoch calculations)
- Faster execution (no file modification time checks)
- More predictable behavior (status-based only)

### Requirement 3: Include "Superseded" Status

**Current Status Classification** (from todo-organization-standards.md):

| Section | Checkbox | Cleanup Eligible? (Current) | Cleanup Eligible? (New) |
|---------|----------|----------------------------|-------------------------|
| In Progress | `[x]` | No | No |
| Not Started | `[ ]` | No | No |
| Backlog | `[ ]` | No | No |
| **Superseded** | `[~]` | **No** | **YES** |
| **Abandoned** | `[x]` | Yes (planned) | Yes |
| **Completed** | `[x]` | Yes (current) | Yes |

**Superseded Projects Definition** (from categorize_plan() in todo-functions.sh, lines 234-261):

```bash
categorize_plan() {
  local status="$1"

  case "$status" in
    # ...
    superseded|deferred)
      echo "Superseded"
      ;;
```

**Examples of Superseded Projects**:
Projects marked as "superseded" or "deferred" in plan metadata, indicating they've been replaced by newer plans or postponed indefinitely.

**Required Change**: Add "superseded" to eligible cleanup statuses.

**Implementation**:
```bash
# In filter_cleanup_candidates()
.status == "completed" or
.status == "abandoned" or
.status == "superseded"  # NEW
```

**Impact on Cleanup Count**:
Based on TODO.md statistics (Appendix A in previous research):
- Completed: ~170 entries
- Abandoned: ~20 entries
- Superseded: ~10 entries
- **New Total**: ~200 eligible projects (vs ~190 previously)

### Requirement 4: Add Git Commit Verification Phase

**Purpose**: Ensure no uncommitted changes exist in directories before cleanup to prevent data loss.

**Git Commands for Checking Uncommitted Changes**:

1. **Check if directory has uncommitted changes**:
```bash
# Method 1: Using git status --porcelain (most reliable)
git status --porcelain "path/to/directory" 2>/dev/null

# Output:
# - Empty string: no uncommitted changes (SAFE to cleanup)
# - Non-empty: has uncommitted changes (UNSAFE, skip cleanup)
```

2. **Check specific directory status**:
```bash
# For a topic directory like specs/961_repair_spec_numbering_allocation/
cd /path/to/repo
git status --porcelain .claude/specs/961_repair_spec_numbering_allocation/

# Examples:
# Clean directory: (no output)
# Modified files:
#  M .claude/specs/961_repair_spec_numbering_allocation/plans/001.md
# Untracked files:
# ?? .claude/specs/961_repair_spec_numbering_allocation/outputs/test.txt
```

3. **Check both staged and unstaged changes**:
```bash
# git status --porcelain shows both:
# - Staged changes (index vs HEAD)
# - Unstaged changes (working tree vs index)
# - Untracked files (not in git)

# Empty output = directory is clean = safe to cleanup
```

**Implementation Pattern**:

```bash
check_directory_committed() {
  local topic_path="$1"
  local project_root="${CLAUDE_PROJECT_DIR}"

  # Get relative path from project root
  local rel_path="${topic_path#$project_root/}"

  # Check git status
  cd "$project_root"
  local git_status
  git_status=$(git status --porcelain "$rel_path" 2>/dev/null)

  if [ -n "$git_status" ]; then
    # Has uncommitted changes
    return 1
  else
    # Clean, safe to cleanup
    return 0
  fi
}
```

**New Phase for Cleanup Plan**:

```markdown
### Phase 0: Git Commit Verification [NOT STARTED]
dependencies: []

**Objective**: Verify all target directories have been committed before cleanup

**Complexity**: Low

Tasks:
- [ ] Check git repository status (ensure in git repo)
- [ ] For each cleanup candidate directory:
  - [ ] Run git status --porcelain on directory path
  - [ ] If uncommitted changes found: SKIP directory, log warning
  - [ ] If clean: Mark as safe for cleanup
- [ ] Generate list of safe vs unsafe directories
- [ ] If any unsafe directories: warn user to commit first
- [ ] Report: X directories safe, Y directories have uncommitted changes

**Expected Duration**: 0.5 hours

---
```

**Integration Points**:

1. **In todo.md Clean Mode section** (line 620+):
```bash
# Before invoking plan-architect, add git verification

# Filter eligible candidates
CLEANUP_CANDIDATES=$(filter_cleanup_candidates "$CLASSIFIED_RESULTS")

# Verify git status for each candidate
SAFE_CANDIDATES="[]"
UNSAFE_CANDIDATES="[]"

while IFS= read -r topic_path; do
  if check_directory_committed "$topic_path"; then
    # Safe - add to safe list
    SAFE_CANDIDATES=$(echo "$SAFE_CANDIDATES" | jq ". += [\"$topic_path\"]")
  else
    # Has uncommitted changes - skip
    UNSAFE_CANDIDATES=$(echo "$UNSAFE_CANDIDATES" | jq ". += [\"$topic_path\"]")
  fi
done < <(echo "$CLEANUP_CANDIDATES" | jq -r '.[].topic_path')

# Warn if any unsafe
if [ "$(echo "$UNSAFE_CANDIDATES" | jq 'length')" -gt 0 ]; then
  echo "WARNING: Some directories have uncommitted changes and will be skipped:"
  echo "$UNSAFE_CANDIDATES" | jq -r '.[]'
  echo "Please commit or stash changes before running cleanup."
fi

# Pass only safe candidates to plan-architect
```

2. **In generate_cleanup_plan()** (todo-functions.sh, lines 770-893):
Add Phase 0 to the generated plan structure.

**Error Handling**:

```bash
# If git command fails (not in repo, git not installed)
log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
  "validation_error" "Git status check failed for directory: $topic_path" \
  "Block:GitVerification" \
  '{"topic":"'"$topic_name"'","git_output":"'"$git_status"'"}'
```

**Example Output**:

```
=== Git Commit Verification ===

Checking git status for 200 cleanup candidates...

✓ Safe (no uncommitted changes): 187 directories
⚠ Unsafe (has uncommitted changes): 13 directories

Unsafe directories (will be SKIPPED):
  - 965_optimize_plan_command_performance (2 modified files)
  - 966_repair_build_20251129_150219 (1 untracked file)
  - 968_plan_standards_alignment (3 modified files)
  ...

Proceeding with cleanup of 187 safe directories.
Run 'git add -A && git commit' to include unsafe directories in future cleanup.
```

## Revised Plan Structure

**Updated Phase Order**:

0. **Git Commit Verification** (NEW)
   - Check all target directories for uncommitted changes
   - Filter to only safe directories
   - Warn about skipped directories

1. **Create Archive Manifest** (EXISTING)
   - Create timestamped archive directory
   - Generate manifest with project metadata

2. **Archive Project Directories** (UPDATED)
   - Move ONLY safe directories to archive
   - Skip directories with uncommitted changes
   - Log each operation

3. **Update TODO.md** (EXISTING)
   - Remove archived entries from respective sections
   - Add archive reference

4. **Verification** (EXISTING)
   - Verify all safe directories moved
   - Verify manifest completeness
   - Generate cleanup summary

## Impact on Existing Plan

**Sections Requiring Revision**:

1. **Overview** (lines 16-25):
   - Remove mention of "direct execution"
   - Clarify plan generation approach
   - Update eligible statuses (completed, abandoned, superseded)
   - Remove 30-day threshold

2. **Research Summary** (lines 27-53):
   - Update findings to reflect new requirements
   - Document git verification requirement

3. **Success Criteria** (lines 54-64):
   - Remove "TODO.md NOT modified" (plan DOES modify TODO.md)
   - Add git verification success criterion
   - Update eligible status list

4. **Technical Design** (lines 66-159):
   - Remove "Direct Execution" architecture
   - Keep "Plan Generation" architecture
   - Add git verification component
   - Update filtering logic

5. **Implementation Phases** (lines 160-310):
   - **Phase 1**: Modify to remove age threshold, add superseded status
   - **Phase 2**: Add git verification logic
   - **Phase 3**: Keep as-is (summary generation still needed)
   - **Phase 4**: Update to modify plan-architect invocation (not remove it)
   - **Phase 5**: Update documentation to reflect plan generation approach

## Git Verification Function Specification

**Function Name**: `verify_git_status()`

**Location**: /home/benjamin/.config/.claude/lib/todo/todo-functions.sh

**Purpose**: Check if a directory has uncommitted changes

**Arguments**:
- `$1` - Absolute path to directory
- `$2` - Project root directory (for relative path calculation)

**Returns**:
- Exit code 0: Directory is clean (safe for cleanup)
- Exit code 1: Directory has uncommitted changes (unsafe)

**Output**: Git status message (if uncommitted changes detected)

**Implementation**:

```bash
verify_git_status() {
  local topic_path="$1"
  local project_root="${2:-${CLAUDE_PROJECT_DIR}}"

  # Validate directory exists
  if [ ! -d "$topic_path" ]; then
    echo "ERROR: Directory not found: $topic_path" >&2
    return 1
  fi

  # Get relative path from project root
  local rel_path="${topic_path#$project_root/}"

  # Check if in git repository
  if ! git -C "$project_root" rev-parse --git-dir >/dev/null 2>&1; then
    echo "WARNING: Not a git repository: $project_root" >&2
    return 1
  fi

  # Check git status for this directory
  local git_status
  git_status=$(git -C "$project_root" status --porcelain "$rel_path" 2>/dev/null)

  if [ -n "$git_status" ]; then
    # Has uncommitted changes
    local change_count
    change_count=$(echo "$git_status" | wc -l)
    echo "Uncommitted changes ($change_count files): $rel_path" >&2
    return 1
  else
    # Clean
    return 0
  fi
}

export -f verify_git_status
```

**Usage Example**:

```bash
# Check if directory is safe for cleanup
if verify_git_status "/path/to/.claude/specs/961_repair/" "$CLAUDE_PROJECT_DIR"; then
  echo "Safe to cleanup"
else
  echo "Skip - has uncommitted changes"
fi
```

## Updated Library Functions

### 1. filter_cleanup_candidates() (Replaces filter_completed_projects)

**Changes**:
- Remove age threshold parameter
- Remove age-based filtering logic
- Add "superseded" status to filter
- Rename from `filter_completed_projects()` to `filter_cleanup_candidates()`

**New Signature**:
```bash
filter_cleanup_candidates() {
  local plans_json="$1"
  # No age threshold parameter

  # Filter for eligible statuses only
  echo "$plans_json" | jq -r '[.[] | select(
    .status == "completed" or
    .status == "abandoned" or
    .status == "superseded"
  )]'
}
```

### 2. generate_cleanup_plan() (Updated)

**Changes**:
- Add Phase 0 (Git Commit Verification)
- Update phase descriptions to mention git verification
- Update eligible statuses in documentation

**Updated Plan Template** (lines 789-893 in todo-functions.sh):

```bash
generate_cleanup_plan() {
  local projects_json="$1"
  local archive_path="$2"
  local specs_root="$3"

  local project_count
  project_count=$(echo "$projects_json" | jq -r 'length')

  local plan_content="# TODO Cleanup Plan

## Metadata
- **Date**: $(date +%Y-%m-%d)
- **Feature**: Archive completed/abandoned/superseded projects from TODO.md
- **Scope**: Move ${project_count} eligible projects to archive directory
- **Status**: [NOT STARTED]
- **Archive Path**: ${archive_path}

## Overview

This plan archives ${project_count} eligible projects (completed, abandoned, or superseded status). Projects will be verified for git commit status before being moved to the archive directory.

## Success Criteria

- [ ] All ${project_count} projects verified for git commit status
- [ ] Only projects with no uncommitted changes are archived
- [ ] Archive manifest created with project metadata
- [ ] TODO.md updated to reflect archived projects
- [ ] Verification confirms no data loss

## Implementation Phases

### Phase 0: Git Commit Verification [NOT STARTED]
dependencies: []

**Objective**: Verify all target directories have no uncommitted changes

**Complexity**: Low

Tasks:
- [ ] Check git repository status
- [ ] For each cleanup candidate, run git status --porcelain
- [ ] Filter to only directories with no uncommitted changes
- [ ] Warn about skipped directories (if any have uncommitted changes)
- [ ] Generate safe vs unsafe directory lists

**Expected Duration**: 0.5 hours

---

### Phase 1: Create Archive Directory and Manifest [NOT STARTED]
dependencies: [0]

**Objective**: Prepare archive directory and create manifest file

Tasks:
- [ ] Create archive directory: ${archive_path}
- [ ] Generate archive manifest with project metadata
- [ ] Verify directory permissions

**Expected Duration**: 0.5 hours

---

### Phase 2: Archive Project Directories [NOT STARTED]
dependencies: [1]

**Objective**: Move verified project directories to archive

Tasks:"

  # Add task for each project
  while IFS= read -r topic_name; do
    [ -z "$topic_name" ] || [ "$topic_name" = "null" ] && continue
    plan_content+="- [ ] Archive project: ${topic_name}\n"
  done < <(echo "$projects_json" | jq -r '.[].topic_name')

  plan_content+="

**Expected Duration**: 1.5 hours

---

### Phase 3: Update TODO.md [NOT STARTED]
dependencies: [2]

**Objective**: Update TODO.md to reflect archived projects

Tasks:
- [ ] Backup current TODO.md
- [ ] Remove archived entries from Completed/Abandoned/Superseded sections
- [ ] Add archive reference to section headers

**Expected Duration**: 1 hour

---

### Phase 4: Verification [NOT STARTED]
dependencies: [3]

**Objective**: Verify cleanup completed successfully

Tasks:
- [ ] Verify all safe project directories moved to archive
- [ ] Verify manifest contains all project metadata
- [ ] Verify TODO.md updated correctly
- [ ] Generate cleanup summary report

**Expected Duration**: 0.5 hours

## Projects to Archive

"

  # List projects with status
  while IFS= read -r line; do
    local topic_name title status
    topic_name=$(echo "$line" | cut -d'|' -f1)
    title=$(echo "$line" | cut -d'|' -f2)
    status=$(echo "$line" | cut -d'|' -f3)
    [ -z "$topic_name" ] || [ "$topic_name" = "null" ] && continue
    plan_content+="- **${title}** (${status}) - ${specs_root}/${topic_name}\n"
  done < <(echo "$projects_json" | jq -r '.[] | "\(.topic_name)|\(.title)|\(.status)"')

  plan_content+="

## Safety Measures

- Verify git commit status before cleanup (skip directories with uncommitted changes)
- Archive (not delete) all projects
- Create manifest with full metadata
- Backup TODO.md before modifications
- Log all operations for audit

## Notes

This plan was generated by /todo --clean command.
Execute with /build to perform cleanup.
"

  echo -e "$plan_content"
}
```

## Recommended Plan Revisions

### High-Priority Changes

1. **Revert to Plan Generation Architecture**
   - Remove all references to "direct execution"
   - Keep plan-architect agent invocation
   - Keep 4-phase plan structure
   - Document workflow: `/todo --clean` → `/build <plan>`

2. **Remove Age Threshold**
   - Delete age-based filtering logic in Phase 1
   - Remove `age_threshold` parameter from functions
   - Update documentation to clarify "all eligible projects"

3. **Add Superseded Status**
   - Update filtering logic to include `status == "superseded"`
   - Update documentation and success criteria
   - Update expected cleanup counts (~200 vs ~190)

4. **Add Git Verification Phase**
   - Create Phase 0: Git Commit Verification
   - Add `verify_git_status()` function to todo-functions.sh
   - Integrate verification into cleanup workflow
   - Update error handling for git failures

### Medium-Priority Changes

1. **Update Success Criteria**
   - Remove "TODO.md NOT modified" (plan DOES modify it)
   - Add git verification criterion
   - Update eligible status list

2. **Update Testing Strategy**
   - Add git verification tests
   - Test with uncommitted changes scenario
   - Test with clean directory scenario
   - Test with non-git repository scenario

3. **Update Documentation**
   - Clarify plan generation workflow
   - Document git verification requirement
   - Update eligible statuses list
   - Add troubleshooting for uncommitted changes

### Low-Priority Changes

1. **Enhance Error Messages**
   - Provide clear warnings for uncommitted changes
   - Show count of skipped directories
   - Suggest remediation steps (git add, git commit)

2. **Add Summary Statistics**
   - Show safe vs unsafe directory counts
   - Report skipped directories with reasons
   - Include git verification results in final summary

## Example Revised Workflow

**User Workflow**:

1. **Check cleanup candidates**:
```bash
/todo --clean --dry-run
```

Output:
```
=== /todo --clean (DRY RUN) ===

Scanning projects...
Found 195 topic directories

=== Status Classification ===
Classified 195 plans

=== Cleanup Candidate Filtering ===
Eligible statuses: completed, abandoned, superseded
Total candidates: 200 directories

=== Git Commit Verification ===
Checking git status...
✓ Safe (no uncommitted changes): 187 directories
⚠ Unsafe (has uncommitted changes): 13 directories

Unsafe directories (will be SKIPPED in cleanup):
  - 965_optimize_plan_command_performance
  - 966_repair_build_20251129_150219
  - 968_plan_standards_alignment
  ...

=== Cleanup Plan Generation ===
Generating plan for 187 safe directories...

CLEANUP_PLAN_CREATED: /home/benjamin/.config/.claude/specs/972_todo_cleanup_20251129/plans/001-cleanup-plan.md
```

2. **Commit uncommitted changes** (if needed):
```bash
git add .claude/specs/965_optimize_plan_command_performance/
git commit -m "Save work in progress for 965"
```

3. **Generate cleanup plan**:
```bash
/todo --clean
```

4. **Review and execute plan**:
```bash
/build .claude/specs/972_todo_cleanup_20251129/plans/001-cleanup-plan.md
```

## Conclusion

The plan revision should focus on:

1. **Preserving plan generation approach** - NOT switching to direct execution
2. **Removing age-based filtering** - Clean all eligible projects regardless of age
3. **Expanding eligible statuses** - Include completed, abandoned, AND superseded
4. **Adding git verification** - Ensure no uncommitted changes before cleanup

These changes maintain the safety and auditability of the plan-based approach while making the cleanup more comprehensive and protecting against accidental data loss from uncommitted changes.

## Appendix A: Git Commands Reference

**Check directory for uncommitted changes**:
```bash
# Method 1: Porcelain output (parseable)
git status --porcelain "path/to/directory"

# Method 2: Short format
git status --short "path/to/directory"

# Method 3: Check exit code with diff
git diff --quiet "path/to/directory" && git diff --cached --quiet "path/to/directory"
# Exit code 0 = clean, non-zero = has changes
```

**Check if in git repository**:
```bash
git rev-parse --git-dir >/dev/null 2>&1
# Exit code 0 = in git repo, non-zero = not in git repo
```

**Get relative path from git root**:
```bash
git rev-parse --show-prefix
# Returns relative path from git root to current directory
```

## Appendix B: Filter Function Comparison

**Old (filter_completed_projects)**:
```bash
filter_completed_projects() {
  local plans_json="$1"
  local age_threshold="${2:-30}"  # Age parameter

  # Filter for completed only
  completed_projects=$(echo "$plans_json" | jq -r '[.[] | select(.status == "completed")]')

  # Filter by age
  while IFS= read -r plan_path; do
    file_epoch=$(stat -c %Y "$plan_path" 2>/dev/null)
    if [ "$file_epoch" -lt "$threshold_epoch" ]; then
      # Include
    fi
  done
}
```

**New (filter_cleanup_candidates)**:
```bash
filter_cleanup_candidates() {
  local plans_json="$1"
  # No age parameter

  # Filter for completed, abandoned, AND superseded
  echo "$plans_json" | jq -r '[.[] | select(
    .status == "completed" or
    .status == "abandoned" or
    .status == "superseded"
  )]'
  # No age filtering
}
```

**Key Differences**:
1. Removed age threshold parameter
2. Added "abandoned" and "superseded" statuses
3. Removed file modification time checks
4. Simpler, faster implementation
5. More predictable behavior (status-based only)
