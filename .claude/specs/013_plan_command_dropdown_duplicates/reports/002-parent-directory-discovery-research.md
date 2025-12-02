# Claude Code Parent Directory Discovery Research

## Research Date
2025-12-02

## Executive Summary

Web research reveals that the triple `/plan` command dropdown entries are caused by Claude Code's INTENTIONAL parent directory scanning behavior, not a bug. The root cause and solution differ significantly from the original plan's assumptions.

## Key Findings

### 1. Parent Directory Scanning is Intentional

**Discovery Mechanism**:
- Claude Code recursively scans UP the directory tree from current working directory (CWD) to root (/)
- It discovers and loads CLAUDE.md files and .claude/ directories from ALL parent directories
- This is explicitly documented as a feature for monorepo support

**Source**: [CLAUDE.md discovery documentation](https://github.com/anthropics/claude-code/issues/722)

> "Claude Code discovers CLAUDE.md files in parent directories above where you run claude, which is most useful for monorepos."

### 2. Command Discovery Hierarchy

**Documented Behavior**:
- Project-level: `.claude/commands/` from current working directory
- User-level: `~/.claude/commands/` from home directory
- Parent directories: `.claude/commands/` from ANY parent directory up to root

**Actual Discovery When Running from `/home/benjamin/.config`**:
1. `/home/benjamin/.config/.claude/commands/plan.md` (CWD project-level)
2. `/home/benjamin/.dotfiles/.claude/commands/plan.md` (parent directory, discovered via upward scan)
3. Possibly `~/.claude/commands/plan.md` (user-level, but user has this intentionally empty)

**Source**: [Working Directory in Claude Code](https://claudelog.com/faqs/what-is-working-directory-in-claude-code/)

### 3. No Conflict Resolution

**Critical Finding**:
> "Conflicts between user and project level commands are not supported."

When multiple `.claude/commands/plan.md` files exist in the discovery hierarchy, ALL appear in the dropdown. There is NO priority system or conflict resolution - all discovered commands are presented to the user.

**Source**: [Slash commands - Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code/slash-commands)

### 4. Subdirectory Recursion Issue

**GitHub Issue #231**:
A known issue exists where Claude Code recursively scans subdirectories within `.claude/commands/` and registers commands multiple times, causing duplicates when subdirectories are present.

**Relevance**: This may explain a potential third duplicate if `.dotfiles/.claude/commands/` contains subdirectories.

**Source**: [Duplicate commands from subdirectories - GitHub Issue #231](https://github.com/SuperClaude-Org/SuperClaude_Framework/issues/231)

### 5. Label Behavior

**Mystery Partially Solved**:
All three entries showing "(project)" label (instead of "(user)" vs "(project)" differentiation) suggests:
- Parent directory .claude/ may be treated as "project-level" rather than "user-level"
- The "(project)" vs "(user)" distinction only applies to `~/.claude/` (true user-level)
- Commands from parent `.claude/` directories inherit "project" scope

## Implications for Original Plan

### Incorrect Assumptions

**Original Plan Assumed**:
- .dotfiles discovery was unexpected/undocumented behavior
- Removal of .dotfiles commands would fix the issue
- Discovery mechanism was a bug to be reported

**Reality**:
- .dotfiles discovery is INTENTIONAL parent directory scanning
- Removal fixes the symptom but doesn't address root cause (user workflow)
- No bug to report - this is documented feature behavior

### Root Cause Analysis Revision

**True Root Cause**:
User's directory structure has `.dotfiles/.claude/` as a parent of `.config/.claude/`, causing parent directory discovery to find commands in `.dotfiles/` when Claude Code is launched from `.config/`.

**User's Actual Need**:
- Keep project-specific commands in each project's `.claude/` directory only
- Use `~/.claude/` for truly cross-project commands (intentionally kept empty)
- Prevent parent directory `.claude/` from polluting child project command discovery

## Revised Solution Strategy

### Option 1: Remove `.dotfiles/.claude/commands/` (Original Plan)
**Pros**: Eliminates immediate duplicate issue
**Cons**: Doesn't prevent future issues if user creates other parent `.claude/` directories

### Option 2: Move `.dotfiles/.claude/` Out of Parent Chain
**Pros**: Eliminates parent discovery without deleting .dotfiles content
**Cons**: Requires restructuring .dotfiles location or symlinking

### Option 3: Don't Store Project Commands in `.dotfiles/`
**Pros**: Aligns with user's stated goal (project-scoped commands only)
**Cons**: Requires auditing all `.dotfiles/.claude/commands/` to determine which are truly cross-project

### Recommended Approach (Hybrid)

1. **Immediate**: Remove or move `.dotfiles/.claude/commands/plan.md` after backup
2. **Strategic**: Audit ALL `.dotfiles/.claude/commands/` files:
   - Move project-specific commands to their respective project `.claude/` directories
   - Move truly cross-project commands to `~/.claude/commands/`
   - Empty `.dotfiles/.claude/commands/` entirely to prevent future parent discovery issues
3. **Documentation**: Update CLAUDE.md and troubleshooting guide with parent discovery behavior

## Implementation Changes Required

### Phase 1 Changes
- Add web research citation to investigation tasks
- Document parent directory scanning as expected behavior
- Clarify that this is NOT a bug to report

### Phase 2 Changes  
- Expand scope: Not just remove `.dotfiles/plan.md`, but audit ALL commands in `.dotfiles/.claude/commands/`
- Decision point: Keep .dotfiles/.claude/ empty or move it out of parent chain

### Phase 3 Changes
- Update objective: Not "investigate third source" but "verify no other parent .claude/ directories exist"
- Check for additional parent directories: `/home/.claude/`, `/home/benjamin/.claude/`, etc.

### Phase 4 Changes
- Document parent directory scanning as INTENTIONAL feature
- Update troubleshooting guide with correct root cause explanation
- Add guidance for structuring .claude/ directories to avoid parent discovery conflicts

## Testing Validation Changes

### Additional Tests
```bash
# Test 1: Verify parent directory discovery
cd /home/benjamin/.config
# Should find both .config and .dotfiles .claude/ directories
find /home/benjamin -maxdepth 2 -name ".claude" -type d

# Test 2: Launch Claude Code from different depths to verify discovery
cd /home/benjamin/.config/nvim
# Should discover: .config/nvim/.claude (if exists), .config/.claude, .dotfiles/.claude

# Test 3: Verify ~/.claude/ remains empty (user-level)
ls -la ~/.claude/commands/
# Should be empty or non-existent
```

## Conclusion

The triple `/plan` dropdown issue is caused by Claude Code's intentional parent directory scanning feature, not a bug. The correct solution is to align the user's `.claude/` directory structure with their stated goal: project-scoped commands in project directories, cross-project commands in `~/.claude/`, and NO project-specific commands in parent directories like `.dotfiles/.claude/`.

**Action Required**: Revise implementation plan to reflect these findings and adjust solution strategy accordingly.

## References

1. [Slash commands - Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code/slash-commands)
2. [What is Working Directory in Claude Code](https://claudelog.com/faqs/what-is-working-directory-in-claude-code/)
3. [CLAUDE.md discovery - GitHub Issue #722](https://github.com/anthropics/claude-code/issues/722)
4. [Duplicate commands from subdirectories - GitHub Issue #231](https://github.com/SuperClaude-Org/SuperClaude_Framework/issues/231)
5. [Using CLAUDE.MD files](https://www.claude.com/blog/using-claude-md-files)
6. [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
