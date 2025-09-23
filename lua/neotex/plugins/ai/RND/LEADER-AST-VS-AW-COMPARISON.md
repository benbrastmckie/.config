# Comparison Report: <leader>ast vs <leader>aw

## Executive Summary

Both `<leader>ast` and `<leader>aw` create git worktrees with WezTerm tabs, but they serve fundamentally different purposes within the Claude workflow ecosystem:

- **`<leader>aw`**: Creates **peer worktrees** for parallel development sessions
- **`<leader>ast`**: Creates **child worktrees** for hierarchical task delegation

## Quick Reference

| Feature | `<leader>aw` (ClaudeWorktree) | `<leader>ast` (TaskDelegate) |
|---------|-------------------------------|------------------------------|
| **Purpose** | Create new development session | Delegate subtask to child |
| **Relationship** | Peer/sibling worktrees | Parent-child hierarchy |
| **Input Required** | Feature name + Type selection | Task description only |
| **Branch Pattern** | `{type}/{feature}` | `task/{safe-name}-{timestamp}` |
| **Context Files** | CLAUDE.md | TASK_DELEGATION.md + CLAUDE.md |
| **Report Mechanism** | None | REPORT_BACK.md to parent |
| **Session Management** | Persistent sessions | Ephemeral tasks |
| **Cleanup** | Manual via git worktree | Integrated cleanup commands |
| **Use Case** | Long-running features | Short-term delegated tasks |

## Detailed Comparison

### 1. Conceptual Model

#### `<leader>aw` - Horizontal Organization
```
Main Branch
    ├── feature/auth-system      (<leader>aw created)
    ├── bugfix/memory-leak       (<leader>aw created)
    └── refactor/database        (<leader>aw created)
```
- Creates **independent** worktrees for parallel work
- Each session is a **peer** to others
- No hierarchical relationship between sessions
- Designed for **human context switching** between features

#### `<leader>ast` - Hierarchical Organization
```
feature/auth-system (Parent)
    ├── task/implement-login-123456     (<leader>ast created)
    ├── task/add-oauth-support-134512   (<leader>ast created)
    └── task/write-tests-145623         (<leader>ast created)
```
- Creates **subordinate** worktrees for task delegation
- Clear **parent-child** relationship
- Children report back to parent
- Designed for **Claude-to-Claude delegation**

### 2. User Interaction Flow

#### `<leader>aw` Flow
1. **Invoke**: Press `<leader>aw`
2. **Feature Input**: Enter feature name (e.g., "auth-system")
3. **Type Selection**: Choose from menu (feature/bugfix/refactor/etc.)
4. **Creation**: Worktree created at `../project-type-feature/`
5. **Context**: CLAUDE.md created with session metadata
6. **Tab**: New WezTerm tab opens with branch name as title

#### `<leader>ast` Flow
1. **Invoke**: Press `<leader>ast` (or with visual selection)
2. **Task Input**: Enter task description (e.g., "implement OAuth login")
3. **Creation**: Worktree created at `../project-task-{name}-{time}/`
4. **Context**: TASK_DELEGATION.md + CLAUDE.md created
5. **Tab**: New WezTerm tab opens, Claude auto-starts
6. **Delegation**: Parent continues working independently

### 3. Context File Generation

#### `<leader>aw` - CLAUDE.md
```markdown
# Task: auth-system

## Metadata
- **Type**: feature
- **Branch**: feature/auth-system
- **Created**: 2024-09-23 11:32
- **Worktree**: ../project-feature-auth-system
- **Session ID**: auth-system-1758652373

## Objective
[Describe the main goal]

## Current Status
- [ ] Planning
- [ ] Implementation
- [ ] Testing
- [ ] Documentation
- [ ] Review

## Claude Context
Tell Claude: "I'm working on auth-system in the feature/auth-system worktree..."
```

#### `<leader>ast` - TASK_DELEGATION.md
```markdown
# Task Delegation

## Parent Session Information
- **Session ID**: auth-system-1758652373
- **Working Directory**: /home/user/project-feature-auth-system
- **Branch**: feature/auth-system
- **Timestamp**: 2024-09-23 11:45:23

## Delegated Task
### Description
implement OAuth login with Google and GitHub providers

### Instructions
1. Review this task
2. Work in isolation
3. Commit frequently
4. Test your changes
5. Report completion via :TaskReportBack

## Report Mechanism
When complete, run :TaskReportBack
Report will be written to: /home/user/project-feature-auth-system/REPORT_BACK.md

## Git Workflow
You're on branch: task/implement-oauth-login-114523
Parent branch: feature/auth-system
```

### 4. Branch Naming Conventions

| System | Pattern | Example | Rationale |
|--------|---------|---------|-----------|
| `<leader>aw` | `{type}/{feature}` | `feature/auth-system` | Human-readable, semantic versioning |
| `<leader>ast` | `task/{safe-name}-{timestamp}` | `task/oauth-login-134512` | Unique, temporal, disposable |

### 5. Session/Task Management

#### `<leader>aw` Session Management
- **Persistence**: Sessions stored in `M.sessions` table
- **Commands**:
  - `:ClaudeSessions` - View all sessions
  - `:ClaudeSessionCleanup` - Remove stale sessions
  - `:ClaudeRestoreSession` - Reopen session
- **Monitoring**: `<leader>av` shows session picker
- **Lifecycle**: Long-lived until manually removed

#### `<leader>ast` Task Management
- **Tracking**: Tasks stored in `M.active_tasks` table
- **Commands**:
  - `:TaskMonitor` - View active tasks (Telescope)
  - `:TaskReportBack` - Complete and report
  - `:TaskCancel` - Cancel and cleanup
  - `:TaskStatus` - View current task
- **Monitoring**: `<leader>asm` shows task monitor
- **Lifecycle**: Short-lived, cleaned up after completion

### 6. Report-Back Mechanisms

#### `<leader>aw` - No Report Mechanism
- Independent sessions don't report to each other
- Changes merged through standard git workflow
- No automated communication between sessions

#### `<leader>ast` - Structured Reporting
```markdown
# Task Completion Report

**Task**: implement OAuth login
**Child Branch**: task/oauth-login-134512
**Completed**: 2024-09-23 12:30:15

## Summary
Implemented OAuth 2.0 login flow for Google and GitHub

## Changes Made
### Commits
- a1b2c3d Add OAuth provider configuration
- d4e5f6g Implement Google OAuth flow
- h7i8j9k Add GitHub OAuth support

### Files Modified
- src/auth/oauth.ts
- src/config/providers.ts
- tests/auth/oauth.test.ts

## Integration Instructions
To merge these changes:
```bash
git merge task/oauth-login-134512
```
```

### 7. WezTerm Tab Management

#### `<leader>aw` Tab Behavior
- **Title**: Branch name (e.g., "feature/auth-system")
- **Persistence**: Tab remains until manually closed
- **Switching**: Can switch between sessions with `<leader>av`
- **Cleanup**: Manual via window manager

#### `<leader>ast` Tab Behavior
- **Title**: Task branch without prefix (e.g., "oauth-login-134512")
- **Auto-start**: Claude Code starts automatically
- **Parent Switch**: Can return to parent with report
- **Cleanup**: Auto-closes on task completion/cancellation

### 8. Use Case Scenarios

#### When to Use `<leader>aw`
1. **Starting new feature development**
   - "I need to implement user authentication"
   - "Starting work on the payment system"

2. **Switching between multiple features**
   - Working on auth in the morning, payments in afternoon
   - Maintaining multiple long-running branches

3. **Isolating experimental work**
   - "Let me try a different approach in a new worktree"
   - Testing architectural changes

4. **Human-driven parallel development**
   - Multiple developers on same repository
   - Personal context switching

#### When to Use `<leader>ast`
1. **Delegating specific subtasks**
   - "While I design the API, spawn a task to implement the database schema"
   - "Create a child task to write comprehensive tests"

2. **Parallel implementation of components**
   - Parent works on backend while child implements frontend
   - Parent designs while child prototypes

3. **Isolated experimentation with report-back**
   - "Try three different implementations and report which works best"
   - "Research and implement optimal caching strategy"

4. **Claude-to-Claude workflow**
   - Parent Claude coordinates multiple child Claudes
   - Hierarchical task breakdown and delegation

### 9. Implementation Differences

#### Code Organization
| Aspect | `<leader>aw` | `<leader>ast` |
|--------|--------------|---------------|
| **Module Location** | `lua/neotex/core/claude-worktree.lua` | `lua/neotex/core/claude-agents/init.lua` |
| **Plugin Spec** | Part of core config | `lua/neotex/plugins/ai/claude-task-delegation.lua` |
| **Dependencies** | None (core module) | telescope.nvim, plenary.nvim |
| **Lines of Code** | ~1000 lines | ~1200 lines |

#### Key Functions
```lua
-- <leader>aw
M.create_worktree_with_claude()  -- Main entry point
M._generate_worktree_path()      -- Path generation
M._create_context_file()          -- CLAUDE.md creation
M._spawn_wezterm_tab()            -- Tab management

-- <leader>ast
M.spawn_child_task()              -- Main entry point
M._create_delegation_files()      -- TASK_DELEGATION.md + CLAUDE.md
M.task_report_back()              -- Report generation
M.telescope_task_monitor()        -- Task monitoring UI
```

### 10. Integration Points

Both systems share common infrastructure:
- **Git worktree** management
- **WezTerm CLI** integration
- **Session/task tracking** in memory
- **Context file** generation
- **Branch naming** conventions

Key differences in integration:
- `<leader>aw` integrates with **session management** (`:ClaudeSessions`)
- `<leader>ast` integrates with **Telescope** for monitoring
- `<leader>aw` works with **:ClaudeCode** commands
- `<leader>ast` provides dedicated **:Task*** commands

## Recommendations

### Workflow Guidelines

1. **Use `<leader>aw` when**:
   - Starting fresh work on a new feature
   - You need a long-running development environment
   - Working independently without need to report back
   - Managing multiple parallel features yourself

2. **Use `<leader>ast` when**:
   - You want to delegate a specific task
   - The task has clear completion criteria
   - You need the results reported back
   - Working with hierarchical task breakdown

### Potential Improvements

1. **Unification Opportunities**:
   - Share common worktree creation logic
   - Unified session/task tracking system
   - Consistent context file format
   - Shared WezTerm tab management

2. **Feature Additions**:
   - Add optional reporting to `<leader>aw` sessions
   - Allow `<leader>ast` to create peer tasks (not just child)
   - Unified monitoring interface showing both sessions and tasks
   - Cross-delegation between `<leader>aw` sessions

3. **Configuration Harmonization**:
   - Consistent naming for similar config options
   - Shared notification patterns
   - Unified debug mode behavior
   - Common cleanup strategies

## Conclusion

While `<leader>aw` and `<leader>ast` share technical implementation details (git worktrees, WezTerm tabs), they serve distinct conceptual purposes:

- **`<leader>aw`** is for **human workflow** - creating independent, long-running development sessions
- **`<leader>ast`** is for **Claude workflow** - hierarchical task delegation with structured reporting

Both tools are complementary rather than competing, and together they provide a comprehensive worktree-based development environment for both human developers and AI assistants.

The key insight is that `<leader>aw` creates **peers** while `<leader>ast` creates **children**, reflecting fundamentally different relationship models in the development workflow.