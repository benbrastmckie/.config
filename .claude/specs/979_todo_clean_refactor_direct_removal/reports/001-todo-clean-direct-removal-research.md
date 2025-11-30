# /todo --clean Direct Removal Research Report

## Executive Summary

The current `/todo --clean` implementation generates a cleanup plan that requires manual execution via `/build`. The user requests refactoring to **directly remove completed/abandoned/superseded projects** after committing them to git history, eliminating the intermediate plan generation step. This research analyzes the current architecture, identifies refactoring requirements, and recommends an implementation approach.

**Key Findings**:
- Current implementation uses plan-architect agent to generate cleanup plans (2-step: generate → execute)
- User wants 1-step direct removal: commit → remove directories
- Git commit provides sufficient recovery mechanism (no separate archival needed)
- Requires architectural change from plan-generation to direct-execution model
- Safety preserved through mandatory pre-cleanup git commit

## Current Architecture Analysis

### Current Workflow (2-Step)

```
/todo --clean
    ↓
Block 1-3: Project Discovery & Classification (via todo-analyzer)
    ↓
Block 4a: Dry-Run Preview (if --dry-run flag)
    ├─→ Filter eligible projects
    ├─→ Display preview list
    └─→ Exit (no plan generation)
    ↓
Block 4b: Plan Generation (if no --dry-run)
    ├─→ Invoke plan-architect agent
    ├─→ Generate cleanup plan with phases:
    │   1. Git commit (pre-cleanup snapshot)
    │   2. Git verification
    │   3. Archive creation
    │   4. Directory removal
    │   5. Verification
    └─→ Return CLEANUP_PLAN_CREATED signal
    ↓
Block 5: Standardized Output
    ├─→ Parse plan path
    ├─→ Display 4-section console summary
    └─→ User must execute: /build <plan-path>
```

**Rationale for Current Design** (from spec 974):
- Separation of concerns: planning vs. execution
- Review-before-execute pattern for safety
- Consistent with other commands (/plan, /research, /debug)
- Reusable plan-architect agent

### Proposed Workflow (1-Step Direct Removal)

```
/todo --clean
    ↓
Block 1-3: Project Discovery & Classification (UNCHANGED)
    ↓
Block 4a: Dry-Run Preview (UNCHANGED)
    ├─→ Filter eligible projects
    ├─→ Display preview list
    └─→ Exit (no execution)
    ↓
Block 4b: Direct Removal Execution (NEW - REPLACES plan generation)
    ├─→ Filter eligible projects
    ├─→ Create git commit (pre-cleanup snapshot)
    │   - Stage all changes: git add .
    │   - Commit: "chore: pre-cleanup snapshot before /todo --clean"
    │   - Log commit hash for recovery reference
    ├─→ Git verification
    │   - Check for uncommitted changes
    │   - Exit if critical uncommitted changes detected
    ├─→ Direct directory removal
    │   - For each eligible project:
    │     * Check for uncommitted git-tracked changes in directory
    │     * Remove directory: rm -rf <topic_path>
    │     * Log removal operation
    │     * Track failures
    ├─→ Verification
    │   - Count removed directories
    │   - Report failures
    │   - Generate summary
    └─→ TODO.md remains unchanged (rescan with /todo after cleanup)
    ↓
Block 5: Standardized Completion Output (MODIFIED)
    ├─→ Display 4-section console summary
    │   - Summary: "Removed N projects after git commit"
    │   - Artifacts: Git commit hash for recovery
    │   - Next Steps: Rescan with /todo, restore if needed
    └─→ Emit CLEANUP_COMPLETED signal
```

## Architectural Changes Required

### 1. Remove plan-architect Agent Invocation

**Current** (Block 4b, lines 700-741 in todo.md):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Generate cleanup plan for cleanup-eligible projects"
  prompt: "..."
}
```

**Proposed**:
```bash
# Direct execution bash block (no agent invocation)
# Perform git commit, verification, removal, and reporting
```

**Impact**:
- Eliminates plan generation step
- Reduces execution time (no agent invocation overhead)
- Changes workflow from plan → build to single-step execution

### 2. Add Direct Removal Logic

**New Functions Required** (in todo-functions.sh):

```bash
# execute_cleanup_removal()
# Purpose: Directly remove eligible project directories after git commit
# Arguments:
#   $1 - JSON array of eligible projects
#   $2 - Specs root path
# Returns: 0 on success, 1 on failure
# Side Effects: Removes directories from filesystem
#
execute_cleanup_removal() {
  local projects_json="$1"
  local specs_root="$2"
  local removed_count=0
  local failed_count=0
  local skipped_count=0

  # Create git commit for recovery
  create_cleanup_git_commit || return 1

  # Process each project
  while IFS= read -r topic_name; do
    [ -z "$topic_name" ] && continue

    local topic_path="${specs_root}/${topic_name}"

    # Check for uncommitted changes in directory
    if has_uncommitted_changes "$topic_path"; then
      log_skip "$topic_name" "uncommitted changes"
      skipped_count=$((skipped_count + 1))
      continue
    fi

    # Remove directory
    if rm -rf "$topic_path" 2>/dev/null; then
      log_removal "$topic_name" "success"
      removed_count=$((removed_count + 1))
    else
      log_removal "$topic_name" "failed"
      failed_count=$((failed_count + 1))
    fi
  done < <(echo "$projects_json" | jq -r '.[].topic_name')

  # Report summary
  echo "Removed: $removed_count, Failed: $failed_count, Skipped: $skipped_count"

  return 0
}

# create_cleanup_git_commit()
# Purpose: Create pre-cleanup git commit for recovery
# Returns: 0 on success, 1 on failure
# Side Effects: Creates git commit
#
create_cleanup_git_commit() {
  local commit_message="chore: pre-cleanup snapshot before /todo --clean"

  # Stage all changes
  git add . 2>/dev/null || {
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "git_error" "Failed to stage changes with git add" \
      "cleanup:git_commit" "{}"
    return 1
  }

  # Create commit
  git commit -m "$commit_message" 2>/dev/null || {
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "git_error" "Failed to create git commit" \
      "cleanup:git_commit" "{}"
    return 1
  }

  # Get commit hash for recovery reference
  local commit_hash
  commit_hash=$(git rev-parse HEAD 2>/dev/null)

  echo "Git commit created: $commit_hash"
  echo "Recovery command: git revert HEAD~1"

  return 0
}

# has_uncommitted_changes()
# Purpose: Check if directory has uncommitted git-tracked changes
# Arguments:
#   $1 - Directory path to check
# Returns: 0 if changes exist, 1 if clean
#
has_uncommitted_changes() {
  local dir_path="$1"

  if [ ! -d "$dir_path" ]; then
    return 1
  fi

  # Check git status for directory
  local status_output
  status_output=$(git status --porcelain "$dir_path" 2>/dev/null)

  if [ -n "$status_output" ]; then
    return 0  # Has uncommitted changes
  else
    return 1  # Clean
  fi
}
```

### 3. Update Block 4b in todo.md

**Current Block 4b** (lines 700-741):
- Invokes plan-architect agent via Task tool
- Generates plan file in specs/ directory
- Returns CLEANUP_PLAN_CREATED signal

**Proposed Block 4b** (direct execution):

```bash
set +H  # CRITICAL: Disable history expansion
set -e  # Fail-fast per code-standards.md

# === DETECT PROJECT DIRECTORY ===
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi
export CLAUDE_PROJECT_DIR

# === SOURCE LIBRARIES (Three-Tier Pattern) ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
  echo "ERROR: Failed to source todo-functions.sh" >&2
  exit 1
}

# === RESTORE STATE ===
STATE_FILE=$(ls -t ~/.claude/data/state/todo_*.state 2>/dev/null | head -1)
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE" 2>/dev/null || true
else
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "state_error" "State file not found - cannot restore variables" \
    "Block4b:StateRestore" \
    '{"expected_pattern":"~/.claude/data/state/todo_*.state"}'
  echo "ERROR: State file not found" >&2
  exit 1
fi

echo ""
echo "=== Cleanup Execution ==="
echo ""

# === FILTER ELIGIBLE PROJECTS ===
if [ ! -f "$CLASSIFIED_RESULTS" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "file_error" "Classified results file not found: $CLASSIFIED_RESULTS" \
    "Block4b:FilterProjects" \
    '{"expected_file":"'"$CLASSIFIED_RESULTS"'"}'
  echo "ERROR: Classified results file missing" >&2
  exit 1
fi

CLASSIFIED_JSON=$(cat "$CLASSIFIED_RESULTS")
ELIGIBLE_PROJECTS=$(filter_completed_projects "$CLASSIFIED_JSON")
ELIGIBLE_COUNT=$(echo "$ELIGIBLE_PROJECTS" | jq 'length')

echo "Found $ELIGIBLE_COUNT eligible projects (Completed, Abandoned, Superseded)"
echo ""

if [ "$ELIGIBLE_COUNT" -eq 0 ]; then
  echo "No projects to clean up - all projects are In Progress, Not Started, or Backlog"
  exit 0
fi

# === CREATE GIT COMMIT ===
echo "Creating pre-cleanup git commit..."
COMMIT_MESSAGE="chore: pre-cleanup snapshot before /todo --clean (${ELIGIBLE_COUNT} projects)"

git add . 2>/dev/null || {
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "git_error" "Failed to stage changes with git add" \
    "Block4b:GitCommit" "{}"
  echo "ERROR: Failed to stage changes" >&2
  exit 1
}

git commit -m "$COMMIT_MESSAGE" 2>/dev/null || {
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "git_error" "Failed to create git commit" \
    "Block4b:GitCommit" "{}"
  echo "ERROR: Failed to create git commit" >&2
  exit 1
}

COMMIT_HASH=$(git rev-parse HEAD 2>/dev/null)
echo "Git commit created: $COMMIT_HASH"
echo "Recovery: git revert $COMMIT_HASH"
echo ""

# === GIT VERIFICATION ===
echo "Verifying git status..."
GIT_STATUS=$(git status --porcelain 2>/dev/null)
if [ -n "$GIT_STATUS" ]; then
  echo "WARNING: Uncommitted changes detected after commit"
  echo "$GIT_STATUS"
  echo ""
fi

# === REMOVE DIRECTORIES ===
echo "Removing project directories..."
echo ""

REMOVED_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0
FAILED_PROJECTS=()

while IFS= read -r line; do
  [ -z "$line" ] && continue

  TOPIC_NAME=$(echo "$line" | jq -r '.topic_name')
  TOPIC_TITLE=$(echo "$line" | jq -r '.title // "Untitled"')
  TOPIC_PATH="${SPECS_ROOT}/${TOPIC_NAME}"

  # Check for uncommitted changes in directory
  DIR_STATUS=$(git status --porcelain "$TOPIC_PATH" 2>/dev/null)
  if [ -n "$DIR_STATUS" ]; then
    echo "  ⚠ Skipped: $TOPIC_NAME (uncommitted changes)"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    continue
  fi

  # Remove directory
  if rm -rf "$TOPIC_PATH" 2>/dev/null; then
    echo "  ✓ Removed: $TOPIC_NAME - $TOPIC_TITLE"
    REMOVED_COUNT=$((REMOVED_COUNT + 1))
  else
    echo "  ✗ Failed: $TOPIC_NAME - $TOPIC_TITLE"
    FAILED_COUNT=$((FAILED_COUNT + 1))
    FAILED_PROJECTS+=("$TOPIC_NAME")
  fi
done < <(echo "$ELIGIBLE_PROJECTS" | jq -c '.[]')

echo ""
echo "=== Cleanup Summary ==="
echo "Removed: $REMOVED_COUNT projects"
echo "Skipped: $SKIPPED_COUNT projects (uncommitted changes)"
echo "Failed: $FAILED_COUNT projects"

if [ "$FAILED_COUNT" -gt 0 ]; then
  echo ""
  echo "Failed projects:"
  for project in "${FAILED_PROJECTS[@]}"; do
    echo "  - $project"
  done
fi

# === PERSIST STATE FOR BLOCK 5 ===
append_workflow_state "COMMIT_HASH" "$COMMIT_HASH"
append_workflow_state "REMOVED_COUNT" "$REMOVED_COUNT"
append_workflow_state "SKIPPED_COUNT" "$SKIPPED_COUNT"
append_workflow_state "FAILED_COUNT" "$FAILED_COUNT"
append_workflow_state "ELIGIBLE_COUNT" "$ELIGIBLE_COUNT"

echo ""
echo "[CHECKPOINT] Cleanup execution complete"
```

### 4. Update Block 5 Completion Output

**Current Block 5** (lines 743-819):
- Parses `CLEANUP_PLAN_CREATED` signal from plan-architect
- Displays plan path and next steps: review → /build → /todo

**Proposed Block 5** (direct execution completion):

```bash
set +H  # CRITICAL: Disable history expansion
set -e  # Fail-fast per code-standards.md

# === DETECT PROJECT DIRECTORY ===
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi
export CLAUDE_PROJECT_DIR

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1

# === RESTORE STATE ===
STATE_FILE=$(ls -t ~/.claude/data/state/todo_*.state 2>/dev/null | head -1)
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE" 2>/dev/null || true
fi

# === GENERATE 4-SECTION CONSOLE SUMMARY ===
SUMMARY_TEXT="Removed ${REMOVED_COUNT} eligible projects (${ELIGIBLE_COUNT} total) from Completed, Abandoned, and Superseded sections after creating git commit ${COMMIT_HASH}. Recovery available via git revert if needed."

ARTIFACTS="  🔗 Git Commit: ${COMMIT_HASH}
  📊 Removed: ${REMOVED_COUNT} projects
  ⚠ Skipped: ${SKIPPED_COUNT} projects (uncommitted changes)
  ✗ Failed: ${FAILED_COUNT} projects"

NEXT_STEPS="  • Rescan TODO.md: /todo
  • Restore if needed: git revert ${COMMIT_HASH}
  • Review git log: git log -1 ${COMMIT_HASH}"

# Print standardized summary
cat << EOF

=== /todo --clean Complete ===

Summary: ${SUMMARY_TEXT}

Artifacts:
${ARTIFACTS}

Next Steps:
${NEXT_STEPS}

EOF

# === EMIT COMPLETION SIGNAL ===
echo "CLEANUP_COMPLETED: removed=${REMOVED_COUNT} skipped=${SKIPPED_COUNT} failed=${FAILED_COUNT} commit=${COMMIT_HASH}"
echo ""

exit 0
```

## Safety Mechanisms

### Git Commit Recovery

**Pre-Cleanup Commit**:
- Mandatory git commit before any directory removal
- Commit message format: `chore: pre-cleanup snapshot before /todo --clean (N projects)`
- Commit hash logged for recovery reference
- Enables full recovery: `git revert <commit-hash>`

**Why No Separate Archive Directory**:
- Git history provides permanent record
- Reduces filesystem clutter
- Simplifies recovery (single git command vs. manual archive restore)
- Follows clean-break development standard (no deprecated/legacy artifacts)

### Uncommitted Changes Protection

**Directory-Level Checks**:
- Before removing each directory, check: `git status --porcelain <dir>`
- If uncommitted changes detected, skip directory with warning
- Log all skipped directories in summary
- User can commit changes and re-run cleanup

**Pre-Execution Verification**:
- After creating commit, verify working tree is clean
- Warn if uncommitted changes remain
- Allows user to abort if unexpected changes detected

### Dry-Run Preview

**Unchanged Behavior**:
- `/todo --clean --dry-run` displays eligible projects without execution
- Shows count and list of projects that would be removed
- No git commit, no directory removal
- Exit before execution

## Comparison with Current Implementation

| Aspect | Current (Plan-Generation) | Proposed (Direct-Removal) |
|--------|---------------------------|---------------------------|
| **Workflow** | 2-step: generate plan → /build | 1-step: execute directly |
| **Agent Invocation** | plan-architect agent | None |
| **Archival** | Creates archive/ directory | No archive (git history only) |
| **Recovery** | Archive directory OR git revert | Git revert only |
| **Execution Time** | ~5-10s (agent invocation) | ~1-2s (direct bash) |
| **User Interaction** | Review plan → execute | Preview → execute |
| **TODO.md Update** | Manual (/todo after /build) | Manual (/todo after cleanup) |
| **Safety** | Git commit + archive | Git commit + directory skip |
| **Complexity** | Higher (agent coordination) | Lower (single bash execution) |

## Recommended Approach

### Refactoring Strategy

**1. Update todo-functions.sh** (Phase 1):
- Add `execute_cleanup_removal()` function
- Add `create_cleanup_git_commit()` function
- Add `has_uncommitted_changes()` function
- Export new functions

**2. Replace Block 4b in todo.md** (Phase 2):
- Remove plan-architect Task invocation (lines 704-741)
- Add direct execution bash block
- Implement git commit, verification, removal logic
- Persist state for Block 5

**3. Update Block 5 in todo.md** (Phase 3):
- Change from plan-based output to execution-based output
- Update 4-section console summary
- Change completion signal: `CLEANUP_PLAN_CREATED` → `CLEANUP_COMPLETED`
- Update artifacts section (git commit instead of plan path)

**4. Update Documentation** (Phase 4):
- Update todo-command-guide.md
- Remove plan-generation workflow
- Document direct-removal workflow
- Add git recovery instructions
- Update examples and troubleshooting

**5. Testing** (Phase 5):
- Unit tests for new functions
- Integration tests for full cleanup workflow
- Dry-run preview tests
- Git commit verification tests
- Uncommitted changes detection tests

### Backward Compatibility

**Breaking Changes**:
- No cleanup plan generated (plan-architect not invoked)
- No archive/ directory created
- Different completion signal

**Migration Path**:
- Users relying on plan review should use `--dry-run` preview
- Users needing archival should manually copy directories before cleanup
- Orchestrators parsing completion signals must update to `CLEANUP_COMPLETED`

### Standards Compliance

**Three-Tier Library Sourcing**:
- Block 4b and Block 5 already follow pattern
- New functions in todo-functions.sh maintain compliance

**Error Handling**:
- All git operations wrapped in error handling
- Error logging for failures
- Fail-fast on critical errors (git commit failure)

**Output Formatting**:
- Maintains 4-section console summary pattern
- Uses approved emoji vocabulary
- Standardized completion signal format

## Testing Requirements

### Unit Tests (New Functions)

**test_execute_cleanup_removal()**:
- Create mock project directories
- Verify removal of eligible projects
- Verify skip on uncommitted changes
- Verify failure handling

**test_create_cleanup_git_commit()**:
- Verify git commit created with correct message
- Verify commit hash returned
- Verify error handling on git failure

**test_has_uncommitted_changes()**:
- Verify detection of modified files
- Verify clean directory returns false
- Verify non-existent directory handling

### Integration Tests

**test_todo_clean_workflow()**:
- Create test project directories with different statuses
- Run `/todo --clean`
- Verify git commit created
- Verify eligible projects removed
- Verify TODO.md unchanged
- Verify completion output format

**test_todo_clean_dry_run()**:
- Create test project directories
- Run `/todo --clean --dry-run`
- Verify preview displayed
- Verify no git commit
- Verify no directory removal

**test_todo_clean_uncommitted_changes()**:
- Create test project with uncommitted changes
- Run `/todo --clean`
- Verify project skipped
- Verify warning logged
- Verify other projects removed

### Recovery Testing

**test_git_recovery()**:
- Run `/todo --clean`
- Verify projects removed
- Run `git revert HEAD~1`
- Verify projects restored
- Verify TODO.md unchanged

## Documentation Updates Required

### Files to Update

1. **/.claude/commands/todo.md**:
   - Line 21: Update Clean Mode description
   - Line 35: Remove plan-generation reference
   - Line 618-620: Update Clean Mode overview
   - Lines 700-741: Replace Block 4b (plan generation → direct execution)
   - Lines 743-819: Replace Block 5 (completion output)

2. **/.claude/docs/guides/commands/todo-command-guide.md**:
   - Line 98-99: Update Clean Mode workflow
   - Lines 276-294: Update Cleanup Plan Generation section → Direct Removal section
   - Lines 297-337: Update Clean Mode Output Format
   - Add Git Recovery section
   - Update troubleshooting

3. **/.claude/lib/todo/todo-functions.sh**:
   - Lines 713-863: Update SECTION 7 comment block
   - Remove `generate_cleanup_plan()` function (lines 740-863)
   - Add new functions: `execute_cleanup_removal()`, `create_cleanup_git_commit()`, `has_uncommitted_changes()`
   - Update exports (lines 884-885)

### New Documentation Sections

**Git Recovery Instructions**:
```markdown
## Git Recovery

If cleanup removed projects unintentionally, recover via git revert:

1. Find commit hash from cleanup output
2. Revert commit: `git revert <commit-hash>`
3. Rescan TODO.md: `/todo`
4. Review restored projects

**Example**:
```bash
# Cleanup output shows:
# Git commit created: abc123def456

# Recover:
git revert abc123def456
/todo
```
```

**Direct Removal Workflow**:
```markdown
## Direct Removal Workflow

1. **Preview** (optional): `/todo --clean --dry-run`
   - Shows count and list of eligible projects
   - No execution

2. **Execute**: `/todo --clean`
   - Creates git commit (pre-cleanup snapshot)
   - Removes eligible project directories
   - Logs commit hash for recovery

3. **Rescan**: `/todo`
   - Updates TODO.md to reflect cleanup
   - Removes entries from Completed/Abandoned/Superseded sections

4. **Recover** (if needed): `git revert <commit-hash>`
   - Restores all removed projects
   - Git history preserves all work
```

## Risk Analysis

### Technical Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Git commit fails | High | Low | Fail-fast, don't proceed with removal |
| Directory removal fails | Medium | Low | Log failures, continue with others |
| Uncommitted changes lost | High | Low | Directory-level checks, skip if changes |
| Recovery fails | Medium | Very Low | Test git revert extensively |

### Operational Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| User expects archive/ | Low | Medium | Document git-only recovery |
| User expects plan review | Medium | Medium | Promote --dry-run preview |
| Breaking change for automation | Medium | Low | Update completion signal docs |

## Implementation Estimate

**Complexity Score**: 22 (Medium-High)
- Library function changes: 3 new functions (6 points)
- Command block replacement: 2 blocks (6 points)
- Documentation updates: 3 files (6 points)
- Testing: Integration + unit tests (4 points)

**Estimated Hours**: 5-6 hours
- Phase 1 (Library functions): 1.5 hours
- Phase 2 (Block 4b replacement): 1.5 hours
- Phase 3 (Block 5 update): 1 hour
- Phase 4 (Documentation): 1 hour
- Phase 5 (Testing): 1 hour

**Estimated Phases**: 5

## Recommendations

### Approach

**RECOMMENDED**: Direct removal with git commit recovery

**Rationale**:
1. **Simplicity**: Eliminates plan-generation step, reduces workflow complexity
2. **Speed**: 5-10s faster than agent invocation
3. **Recovery**: Git history provides permanent, reliable recovery mechanism
4. **Standards Alignment**: Follows clean-break development (no legacy artifacts)
5. **User Experience**: Single-step execution, fewer clicks

### Alternative Considered

**REJECTED**: Keep plan-generation, add `--execute` flag

**Why Rejected**:
- Adds complexity (dual execution paths)
- Still requires intermediate plan artifact
- Doesn't address user's core request (eliminate plan step)
- Violates clean-break standard (preserves deprecated workflow)

### Next Steps

1. Create implementation plan from this research
2. Implement in phases (functions → blocks → docs → tests)
3. Test recovery extensively
4. Update standards documentation
5. Deploy and monitor

## Conclusion

Refactoring `/todo --clean` to direct removal is **architecturally sound** and **improves user experience** while maintaining safety through git commit recovery. The current plan-generation approach was designed for review-before-execute safety, but the mandatory pre-cleanup git commit provides equivalent safety with less workflow friction.

**Key Benefits**:
- Simpler workflow (1-step vs. 2-step)
- Faster execution (no agent invocation)
- Reliable recovery (git revert)
- Standards compliance (clean-break development)

**Key Trade-offs**:
- No archive/ directory (git history only)
- No plan artifact to review (use --dry-run preview instead)
- Breaking change for automation (completion signal format change)

The refactoring aligns with the project's clean-break development philosophy and eliminates unnecessary intermediate artifacts while preserving safety through git-based recovery.
