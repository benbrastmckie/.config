# Worktree Merge Workflow Analysis

## Metadata
- **Date**: 2025-10-08
- **Scope**: Analysis of worktree merge challenges encountered during github_agent integration workflow
- **Primary Directory**: /home/benjamin/.config/.claude/specs/reports/
- **Files Analyzed**:
  - worktree.lua (nvim/lua/neotex/plugins/ai/claude/core/worktree.lua)
  - Git operation logs from /orchestrate workflow
  - CLAUDE.md worktree documentation

## Executive Summary

During the github_agent integration workflow, merging the feature worktree back to master presented challenges due to environmental context switching and Claude Code's automatic working directory reset behavior. The key insight is that **worktree operations should be abstracted into helper commands or utilities** rather than executed directly via git commands, and the merge workflow should account for Claude Code's stateless bash environment.

### Key Findings

1. **Working Directory Instability**: Claude Code resets the working directory after each bash command, making sequential git operations in different directories difficult
2. **Worktree Lock Conflicts**: Attempting to checkout master from within a worktree directory fails due to git's worktree locking mechanism
3. **File Staging Conflicts**: Untracked or staged files in the main worktree created merge conflicts when attempting to merge from the feature branch
4. **Manual Cleanup Required**: Worktree removal required navigation outside the worktree directory, complicated by automatic directory resets

## Background

### Worktree System Overview

The project uses git worktrees to manage parallel feature development with isolated CLAUDE.md context files. Key components:

- **Worktree Creation**: `M.create_worktree_with_claude()` creates isolated directories for feature branches
- **Session Management**: Tracks worktrees in `~/.local/share/nvim/claude-worktree-sessions.json`
- **CLAUDE.md Preservation**: Copies main CLAUDE.md to worktree with task-specific metadata
- **Terminal Integration**: Spawns new terminal tabs (Kitty/WezTerm) for each worktree

### Workflow Context

The `/orchestrate` command executed:
1. Research phase (4 parallel agents)
2. Planning phase (single agent created 035_github_agent_integration.md)
3. Implementation phase (6 phases, 4 commits created in feature/github_agent)
4. Documentation phase (workflow summary created)
5. **Merge phase** (encountered issues merging back to master)

## Problem Analysis

### Issue 1: Working Directory Reset

**Observed Behavior**:
```bash
# Command 1
cd /home/benjamin/.config && git status
Shell cwd was reset to /home/benjamin/.config-feature-github_agent

# Command 2
cd /home/benjamin/.config && git merge...
Shell cwd was reset to /home/benjamin/.config-feature-github_agent
```

**Root Cause**: Claude Code's bash tool resets the working directory to the original CWD after each command execution. This is intentional to maintain context consistency but conflicts with git operations that require sustained directory context.

**Impact**: Cannot execute multi-step git operations (status → merge → commit) in a different directory without repeating `cd` for each command.

### Issue 2: Worktree Lock Conflict

**Error Message**:
```
fatal: 'master' is already used by worktree at '/home/benjamin/.config'
```

**Root Cause**: Git prevents checking out the same branch in multiple worktrees simultaneously. The main worktree has master checked out, so the feature worktree cannot checkout master.

**Impact**: Merge must be performed FROM the main worktree, not from the feature worktree.

### Issue 3: Staged File Conflicts

**Error Message**:
```
error: Your local changes to the following files would be overwritten by merge:
  .claude/agents/github-specialist.md
Merge with strategy ort failed.
```

**Root Cause**: The github-specialist.md file existed as:
- Staged file in main worktree (from previous operation)
- New file in feature branch (from implementation)

**Impact**: Git could not reconcile the two states, blocking the merge.

### Issue 4: Worktree Path Reset

**Error Message**:
```
Path "/home/benjamin/.config-feature-github_agent" does not exist
```

**Root Cause**: After certain operations, Claude Code reset the working directory reference, causing bash commands to fail when referencing the worktree path.

**Impact**: Worktree cleanup commands (`git worktree remove`) failed, requiring manual recovery.

## Current State Analysis

### Worktree Merge Process (As Attempted)

```markdown
Sequence of Operations:
1. git status (verify clean state in feature worktree)
2. git checkout master (FAILED - worktree lock)
3. cd /home/benjamin/.config && git merge (worked after cleanup)
4. git worktree remove (FAILED - path reset issues)
```

### Successful Workaround

The eventual successful merge required:

1. **Manual File Cleanup**: Remove conflicting staged file in main worktree
   ```bash
   cd /home/benjamin/.config && git reset HEAD .claude/agents/github-specialist.md
   cd /home/benjamin/.config && rm .claude/agents/github-specialist.md
   ```

2. **Main Worktree Merge**: Execute merge from main worktree
   ```bash
   cd /home/benjamin/.config && git merge --no-ff feature/github_agent
   ```

3. **Manual Worktree Cleanup**: Worktree removal handled by automatic cleanup (path no longer accessible)

## Technical Details

### Working Directory Management in Claude Code

From worktree.lua line 632:
```lua
function M.open_terminal()
  vim.cmd("ToggleTerm direction=vertical")
end
```

The integration relies on terminal tabs for worktree isolation, but git operations in Claude Code bash tool don't have sustained context.

### Git Worktree Architecture

```
/home/benjamin/.config/                    # Main worktree (master)
├── .git/                                  # Git metadata
│   └── worktrees/
│       └── .config-feature-github_agent/  # Feature worktree metadata
├── CLAUDE.md                              # Main context
└── .claude/
    └── agents/github-specialist.md        # Created in feature branch

/home/benjamin/.config-feature-github_agent/  # Feature worktree
├── .git                                   # Symlink to worktree metadata
├── CLAUDE.md                              # Task-specific context
└── .claude/
    └── agents/github-specialist.md        # New agent (this branch)
```

### Merge Conflict Scenarios

**Scenario 1: Staged Files in Main Worktree**
```
Main worktree:
  .claude/agents/github-specialist.md (staged, from previous copy)

Feature worktree:
  .claude/agents/github-specialist.md (new file, committed)

Result: Git cannot determine which version is authoritative
```

**Scenario 2: Directory Reset After Commands**
```bash
pwd                    # /home/benjamin/.config-feature-github_agent
cd /home/benjamin/.config && git status
pwd                    # /home/benjamin/.config-feature-github_agent (reset)
```

## Recommendations

### Short-Term: Workflow Improvements

#### 1. Encapsulate Merge Operations

Create a helper script `.claude/lib/worktree-merge.sh`:

```bash
#!/usr/bin/env bash
# Merge a feature worktree back to main branch

set -e

FEATURE_BRANCH="${1:?Usage: worktree-merge.sh <feature-branch>}"
MAIN_WORKTREE="$(git rev-parse --show-toplevel)"

# Function: Get to main worktree and execute command
in_main() {
  (cd "$MAIN_WORKTREE" && "$@")
}

# Verify current branch is feature branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "$FEATURE_BRANCH" ]; then
  echo "ERROR: Not on feature branch $FEATURE_BRANCH"
  echo "Current: $CURRENT_BRANCH"
  exit 1
fi

# Verify no uncommitted changes in feature worktree
if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: Uncommitted changes in feature worktree"
  git status
  exit 1
fi

# Clean up any staged files in main worktree
echo "Cleaning staged files in main worktree..."
in_main git reset HEAD .

# Remove any untracked files that match feature branch changes
echo "Removing potential conflict files from main worktree..."
FEATURE_FILES=$(git diff --name-only origin/main..HEAD)
for file in $FEATURE_FILES; do
  MAIN_FILE="$MAIN_WORKTREE/$file"
  if [ -f "$MAIN_FILE" ] && ! in_main git ls-files --error-unmatch "$file" &>/dev/null; then
    echo "  Removing untracked: $file"
    rm "$MAIN_FILE"
  fi
done

# Merge in main worktree
echo "Merging $FEATURE_BRANCH into main..."
in_main git merge --no-ff "$FEATURE_BRANCH" -m "Merge $FEATURE_BRANCH"

# Report success
MERGE_COMMIT=$(in_main git rev-parse HEAD)
echo "✓ Merge successful: $MERGE_COMMIT"
echo ""
echo "Next steps:"
echo "  1. Review merge commit: git log -1"
echo "  2. Run tests: /test-all"
echo "  3. Remove worktree: git worktree remove <path>"
echo "  4. Delete branch (if done): git branch -d $FEATURE_BRANCH"
```

**Usage in /orchestrate**:
```bash
# Instead of manual git commands
.claude/lib/worktree-merge.sh feature/github_agent
```

#### 2. Pre-Merge Validation

Add validation step before merge attempt:

```bash
# .claude/lib/validate-merge-ready.sh
#!/usr/bin/env bash

FEATURE_BRANCH="$1"
MAIN_WORKTREE="$(git rev-parse --show-toplevel)"

echo "Validating merge readiness for $FEATURE_BRANCH..."

# Check 1: Feature worktree is clean
if [ -n "$(git status --porcelain)" ]; then
  echo "✗ FAIL: Uncommitted changes in feature worktree"
  exit 1
fi
echo "✓ Feature worktree is clean"

# Check 2: Main worktree has no staged changes
STAGED=$(cd "$MAIN_WORKTREE" && git diff --cached --name-only)
if [ -n "$STAGED" ]; then
  echo "✗ FAIL: Staged files in main worktree:"
  echo "$STAGED"
  exit 1
fi
echo "✓ Main worktree has no staged changes"

# Check 3: No conflicting untracked files in main worktree
FEATURE_FILES=$(git diff --name-only origin/main..HEAD)
for file in $FEATURE_FILES; do
  MAIN_FILE="$MAIN_WORKTREE/$file"
  if [ -f "$MAIN_FILE" ]; then
    if ! (cd "$MAIN_WORKTREE" && git ls-files --error-unmatch "$file" &>/dev/null); then
      echo "✗ FAIL: Conflicting untracked file in main worktree: $file"
      exit 1
    fi
  fi
done
echo "✓ No conflicting untracked files"

# Check 4: All tests passing
if ! /test-all &>/dev/null; then
  echo "✗ FAIL: Tests not passing"
  exit 1
fi
echo "✓ All tests passing"

echo ""
echo "✓ Ready to merge $FEATURE_BRANCH"
```

#### 3. Integrate into /orchestrate Command

Update `.claude/commands/orchestrate.md` to include merge step:

```markdown
## Phase 5: Merge Worktree (Optional)

If workflow was executed in a feature worktree and --merge flag provided:

**Step 1: Validate Merge Readiness**
```bash
.claude/lib/validate-merge-ready.sh feature/github_agent
```

**Step 2: Execute Merge**
```bash
.claude/lib/worktree-merge.sh feature/github_agent
```

**Step 3: Cleanup Worktree**
```bash
# Navigate to parent of worktree
cd "$(git rev-parse --show-toplevel)/.."

# Remove worktree
git -C .config worktree remove .config-feature-github_agent

# Delete branch if --delete-branch flag provided
git -C .config branch -d feature/github_agent
```

**Step 4: Verify Merge**
```bash
cd "$(git rev-parse --show-toplevel)"
git log --oneline -5
```
```

### Medium-Term: Architectural Improvements

#### 1. Worktree Lifecycle Management

Extend worktree.lua with merge capabilities:

```lua
-- worktree.lua additions

-- Merge current worktree back to main
function M.merge_current_worktree()
  local current_branch = vim.fn.system("git branch --show-current"):gsub("\n", "")

  -- Validate it's a feature worktree
  local session = nil
  for name, sess in pairs(M.sessions) do
    if sess.branch == current_branch then
      session = sess
      break
    end
  end

  if not session then
    vim.notify("Current branch is not a tracked worktree session", vim.log.levels.ERROR)
    return
  end

  -- Confirm merge
  local confirm = vim.fn.confirm(
    string.format("Merge '%s' into main and cleanup worktree?", current_branch),
    "&Yes\n&No\n&Validate Only",
    2
  )

  if confirm == 3 then
    -- Validate only
    local result = vim.fn.system(".claude/lib/validate-merge-ready.sh " .. current_branch)
    if vim.v.shell_error == 0 then
      vim.notify("Merge validation passed", vim.log.levels.INFO)
    else
      vim.notify("Merge validation failed:\n" .. result, vim.log.levels.ERROR)
    end
    return
  elseif confirm ~= 1 then
    return
  end

  -- Execute merge script
  local result = vim.fn.system(".claude/lib/worktree-merge.sh " .. current_branch)

  if vim.v.shell_error == 0 then
    vim.notify("Merge successful", vim.log.levels.INFO)

    -- Cleanup session
    M.sessions[name] = nil
    M.save_sessions()

    -- Switch to main worktree
    local main_path = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
    vim.cmd("cd " .. vim.fn.fnameescape(main_path))
  else
    vim.notify("Merge failed:\n" .. result, vim.log.levels.ERROR)
  end
end

-- Command registration
vim.api.nvim_create_user_command("ClaudeMergeWorktree", M.merge_current_worktree, {
  desc = "Merge current worktree to main and cleanup"
})
```

#### 2. Slash Command Integration

Create `/merge-worktree` command:

```markdown
# /merge-worktree Command

## Purpose
Merge the current feature worktree back to main branch with comprehensive validation and cleanup.

## Usage
```
/merge-worktree [--no-cleanup] [--keep-branch]
```

## Flags
- `--no-cleanup`: Skip worktree removal after merge
- `--keep-branch`: Don't delete feature branch after merge

## Process

### 1. Validation
- Verify current directory is in a feature worktree
- Check for uncommitted changes
- Validate main worktree cleanliness
- Run test suite
- Check for merge conflicts

### 2. Pre-Merge Cleanup
- Unstage any files in main worktree
- Remove untracked files that conflict with feature changes
- Verify git status is clean

### 3. Merge Execution
- Switch context to main worktree
- Execute `git merge --no-ff <feature-branch>`
- Capture merge commit hash
- Update workflow summary with merge commit

### 4. Post-Merge Cleanup (unless --no-cleanup)
- Remove worktree directory
- Delete feature branch (unless --keep-branch)
- Update session tracking
- Return to main worktree

### 5. Verification
- Display merge commit
- Show final git status
- List remaining worktrees
- Update CLAUDE.md if needed
```

#### 3. Atomic Merge Operations

Create git alias for atomic worktree merge:

```bash
# Add to ~/.gitconfig
[alias]
  worktree-merge = "!f() { \
    MAIN=$(git rev-parse --show-toplevel); \
    BRANCH=\"$1\"; \
    cd \"$MAIN\" && \
    git reset HEAD . && \
    git clean -f && \
    git merge --no-ff \"$BRANCH\" && \
    echo \"Merged $BRANCH at $(git rev-parse --short HEAD)\"; \
  }; f"
```

**Usage**:
```bash
git worktree-merge feature/github_agent
```

### Long-Term: System-Level Improvements

#### 1. Bash Context Persistence

Enhance Claude Code's bash tool to support session-based working directories:

```yaml
Proposal: Bash Session Mode

Syntax:
  Bash(command, session_id="merge-ops", persist_cwd=True)

Behavior:
  - Commands with same session_id share working directory context
  - CWD persists across commands in session
  - Session clears when different session_id used

Example:
  Bash("cd /main/worktree", session_id="merge", persist_cwd=True)
  Bash("git status", session_id="merge", persist_cwd=True)  # Uses /main/worktree
  Bash("git merge feature", session_id="merge", persist_cwd=True)  # Still in /main/worktree
```

#### 2. Worktree-Aware Git Operations

Create abstraction layer for git operations that understand worktree context:

```python
# Conceptual API
class WorktreeGit:
    def __init__(self, worktree_path):
        self.worktree_path = worktree_path
        self.main_worktree = self._find_main_worktree()

    def merge_to_main(self, message=None):
        """Merge current worktree to main, handling all context switches"""
        with self.in_main_worktree():
            self.reset_staged()
            self.clean_conflicts()
            self.merge(self.current_branch, no_ff=True, message=message)
        return self.get_merge_commit()

    @contextmanager
    def in_main_worktree(self):
        """Context manager for executing commands in main worktree"""
        original_cwd = os.getcwd()
        try:
            os.chdir(self.main_worktree)
            yield
        finally:
            os.chdir(original_cwd)
```

#### 3. Orchestrate Workflow Enhancement

Add merge as explicit final phase in /orchestrate:

```markdown
## Orchestrate Workflow Phases (Enhanced)

1. Research Phase (parallel)
2. Planning Phase (sequential)
3. Implementation Phase (adaptive)
4. Debugging Loop (conditional)
5. Documentation Phase (sequential)
6. **Merge Phase** (conditional - if in worktree)
   - Validate merge readiness
   - Execute merge
   - Cleanup worktree
   - Verify final state

Merge Phase Triggers:
- Workflow executed in feature worktree
- All previous phases completed successfully
- User provided --merge flag or confirmed merge prompt
```

## Best Practices for Future Workflows

### 1. Worktree Merge Checklist

Before attempting merge:

- [ ] All changes committed in feature worktree
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Workflow summary created
- [ ] Main worktree has no staged changes
- [ ] Main worktree has no untracked files matching feature changes
- [ ] Feature branch is ahead of main (not diverged)

### 2. Recommended Merge Sequence

```bash
# 1. Validate readiness
.claude/lib/validate-merge-ready.sh <feature-branch>

# 2. Execute merge
.claude/lib/worktree-merge.sh <feature-branch>

# 3. Verify merge
cd "$(git rev-parse --show-toplevel)"
git log --oneline -5
git diff origin/main..HEAD --stat

# 4. Cleanup worktree
cd ..
git -C .config worktree remove .config-<feature>

# 5. Delete branch (optional)
git -C .config branch -d <feature-branch>
```

### 3. Error Recovery Procedures

**If merge blocked by staged files**:
```bash
cd /path/to/main/worktree
git reset HEAD .
git status  # Verify clean
# Retry merge
```

**If merge blocked by untracked files**:
```bash
cd /path/to/main/worktree
git clean -n  # Preview what will be removed
git clean -f  # Remove untracked files
# Retry merge
```

**If worktree removal fails**:
```bash
# Navigate outside all worktrees
cd ~

# Force remove
git -C /path/to/main/worktree worktree remove --force /path/to/feature/worktree

# Prune stale worktree metadata
git -C /path/to/main/worktree worktree prune
```

## Lessons Learned

### What Worked Well

1. **Feature Isolation**: Worktree kept feature work completely isolated from main development
2. **CLAUDE.md Context**: Task-specific CLAUDE.md provided clear context throughout workflow
3. **Terminal Integration**: Separate terminal tabs maintained clear workspace boundaries
4. **Eventual Success**: Despite challenges, merge completed successfully with correct final state

### Challenges Encountered

1. **Directory Context Loss**: Bash tool CWD resets required repeating `cd` for each command
2. **Worktree Locking**: Couldn't checkout main from feature worktree
3. **File Staging Confusion**: Unclear source of staged github-specialist.md in main worktree
4. **Path References**: Worktree path became inaccessible mid-operation

### Key Insights

1. **Abstraction is Critical**: Git operations should be encapsulated in scripts/utilities that handle context switching internally
2. **Validation Prevents Issues**: Pre-merge validation would have caught staged file conflicts
3. **Stateless Operations**: Design workflows assuming each bash command is independent (no persistent CWD)
4. **Cleanup is Part of Workflow**: Merge and cleanup should be atomic operations

## Future Enhancements

### Phase 1: Immediate (Next Workflow)

- [ ] Create `.claude/lib/worktree-merge.sh` script
- [ ] Create `.claude/lib/validate-merge-ready.sh` script
- [ ] Document usage in CLAUDE.md
- [ ] Test with next feature worktree

### Phase 2: Integration (1-2 Weeks)

- [ ] Add merge commands to worktree.lua
- [ ] Create `/merge-worktree` slash command
- [ ] Integrate into /orchestrate workflow
- [ ] Add to worktree documentation

### Phase 3: Enhancement (1-2 Months)

- [ ] Proposal for bash session persistence
- [ ] WorktreeGit abstraction layer
- [ ] Automated merge validation in pre-merge hooks
- [ ] Worktree health checks and diagnostics

## References

### Files Analyzed
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/worktree.lua` - Worktree management (2344 lines)
- `/home/benjamin/.config/CLAUDE.md` - Project standards and workflow documentation
- `.claude/specs/summaries/035_github_agent_workflow_summary.md` - Workflow execution details

### Related Documentation
- Git worktree documentation: https://git-scm.com/docs/git-worktree
- Claude Code bash tool behavior (internal implementation)
- Neovim integration patterns (worktree.lua implementation)

### Commands and Utilities
- `git worktree add <path> -b <branch>` - Create worktree
- `git worktree list` - List all worktrees
- `git worktree remove <path>` - Remove worktree
- `git merge --no-ff <branch>` - Merge with merge commit

## Conclusion

The worktree merge challenges revealed important insights about Claude Code's bash environment and git worktree architecture. The primary recommendation is to **encapsulate merge operations in dedicated scripts** that handle all context switching internally, and to **validate merge readiness before attempting merge** to catch common issues like staged files or untracked conflicts.

By implementing the short-term recommendations (merge and validation scripts), the next worktree workflow should complete merge seamlessly. The medium-term architectural improvements will further streamline the process and integrate merge capabilities directly into the /orchestrate command.

The long-term enhancements around bash session persistence and WorktreeGit abstraction would represent more fundamental improvements to Claude Code's git operation handling, benefiting not just worktree merges but all multi-step git workflows.

**Success Metric**: Next feature worktree merge completes in single `/merge-worktree` command with no manual intervention required.
