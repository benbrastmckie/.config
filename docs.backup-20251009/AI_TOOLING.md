# Advanced AI Tooling: Git Worktrees with OpenCode for Parallel Development

This guide provides comprehensive documentation for using Git Worktrees with OpenCode to enable parallel AI agent development workflows in a single repository.

## Table of Contents

1. [Overview](#overview)
2. [Git Worktrees Fundamentals](#git-worktrees-fundamentals)
3. [OpenCode Multi-Agent Architecture](#opencode-multi-agent-architecture)
4. [Integration Patterns](#integration-patterns)
5. [Setup and Configuration](#setup-and-configuration)
6. [Workflow Examples](#workflow-examples)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)
9. [Advanced Automation](#advanced-automation)

## Overview

Git Worktrees combined with OpenCode's multi-session capabilities enable a revolutionary parallel development workflow where multiple AI agents can work simultaneously on different aspects of the same repository without interference.

### Key Benefits

- **Parallel Development**: Run multiple OpenCode sessions on different branches simultaneously
- **Context Isolation**: Each agent maintains its own workspace and context
- **No Context Switching**: Work on multiple features without stashing or committing incomplete work
- **Reduced Conflicts**: Minimize merge conflicts through isolated workspaces
- **Accelerated Velocity**: Complete multiple tasks in parallel rather than sequentially

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Main Repository                         │
│                    (.git directory)                         │
└────────────────────┬────────────────────────────────────────┘
                     │
     ┌───────────────┼───────────────┐
     │               │               │
┌────▼────┐    ┌─────▼─────┐    ┌────▼────┐
│Worktree1│    │Worktree2  │    │Worktree3│
│feature-a│    │feature-b  │    │bugfix-c │
│OpenCode1│    │OpenCode2  │    │OpenCode3│
└─────────┘    └───────────┘    └─────────┘
```

## Git Worktrees Fundamentals

### What are Git Worktrees?

Git Worktrees allow you to have multiple working directories associated with a single Git repository. Each worktree can have a different branch checked out, enabling simultaneous work on multiple branches.

### Core Commands

```bash
# List all worktrees
git worktree list

# Create a new worktree with new branch
git worktree add ../project-feature-auth feature/auth

# Create worktree from existing branch
git worktree add ../project-bugfix-login bugfix/login

# Remove a worktree
git worktree remove ../project-feature-auth

# Prune stale worktree references
git worktree prune
```

### Directory Structure Example

```
project/
├── .git/                    # Main repository data
├── main-workspace/         # Main worktree (original)
├── feature-auth/           # Worktree for authentication feature
├── feature-api/            # Worktree for API development
├── bugfix-validation/      # Worktree for validation fixes
└── experiment-ui/          # Worktree for UI experiments
```

## OpenCode Multi-Agent Architecture

### Agent Types

**Primary Agents:**
- Main assistants you interact with directly
- Switchable using Tab key during sessions
- Built-in: Build (full tools), Plan (restricted tools)

**Subagents:**
- Specialized assistants for specific tasks
- Invoked via @ mentions or automatic triggers
- Built-in: General (complex searches, multi-step tasks)

### Session Management

**Navigation Commands:**
- `Ctrl+Right`: Cycle forward through sessions
- `Ctrl+Left`: Cycle backward through sessions
- `Tab`: Switch between primary agents

**Multi-Session Capabilities:**
- Multiple concurrent sessions on same project
- Shareable session links for collaboration
- Independent context and conversation history per session

### Agent Configuration

Each agent can be customized via JSON or Markdown files:

```json
{
  "name": "feature-developer",
  "description": "Specialized agent for feature development",
  "temperature": 0.7,
  "model": "claude-3-5-sonnet-20241022",
  "mode": "primary",
  "permissions": {
    "file_operations": "allow",
    "git_operations": "ask",
    "terminal": "allow"
  },
  "tools": ["filesystem", "git", "search"]
}
```

## Integration Patterns

### Pattern 1: Feature-Based Parallelization

Use separate worktrees for each major feature, with dedicated OpenCode sessions:

```bash
# Create worktrees for different features
git worktree add ../myproject-auth feature/authentication
git worktree add ../myproject-api feature/api-endpoints
git worktree add ../myproject-ui feature/user-interface

# Start OpenCode in each worktree
cd ../myproject-auth && opencode
cd ../myproject-api && opencode  
cd ../myproject-ui && opencode
```

### Pattern 2: Role-Based Agent Specialization

Assign different agent roles to different worktrees:

- **Backend Agent** (API worktree): Database, API endpoints, business logic
- **Frontend Agent** (UI worktree): Components, styling, user interactions
- **DevOps Agent** (infrastructure worktree): CI/CD, deployment, monitoring
- **QA Agent** (testing worktree): Test creation, bug fixes, validation

### Pattern 3: Experimental Development

Use worktrees for parallel experimentation:

```bash
# Create experimental branches
git worktree add ../experiment-approach-a experiment/approach-a
git worktree add ../experiment-approach-b experiment/approach-b
git worktree add ../experiment-approach-c experiment/approach-c

# Run different OpenCode agents with different prompts/models
```

### Pattern 4: Refactoring and Optimization

Parallel refactoring of different modules:

```bash
# Create worktrees for different refactoring tasks
git worktree add ../refactor-auth refactor/authentication-module
git worktree add ../refactor-db refactor/database-layer
git worktree add ../refactor-api refactor/api-controllers
```

## Setup and Configuration

### Prerequisites

**NixOS Dependencies:**
```nix
environment.systemPackages = with pkgs; [
  git          # Git with worktree support
  nodejs_20    # For OpenCode and npx MCP servers
  uv           # For uvx MCP servers
  opencode-ai  # OpenCode CLI (add to your config)
];
```

**OpenCode Installation:**
```bash
# Via npm (if not using NixOS package)
npm install -g opencode-ai

# Verify installation
opencode --version
```

### Initial Repository Setup

```bash
# Navigate to your project
cd ~/projects/myproject

# Create a main workspace directory (optional, for organization)
mkdir -p ../myproject-workspaces
cd ../myproject-workspaces

# Create main worktree (if organizing outside original repo)
git worktree add main main

# Verify setup
git worktree list
```

### OpenCode Configuration

Create `~/.config/opencode/opencode.json`:

```json
{
  "llm": {
    "provider": "anthropic",
    "model": "claude-3-5-sonnet-20241022"
  },
  "mcp": {
    "filesystem": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem"],
      "args": ["${HOME}"],
      "enabled": true
    },
    "git": {
      "type": "local",
      "command": ["uvx", "mcp-server-git"],
      "enabled": true
    },
    "neovim": {
      "type": "local",
      "command": ["npx", "-y", "mcp-neovim-server"],
      "environment": {
        "NVIM_SOCKET_PATH": "/tmp/nvim"
      },
      "enabled": true
    }
  },
  "agents": {
    "backend-dev": {
      "description": "Backend development specialist",
      "temperature": 0.3,
      "tools": ["filesystem", "git", "terminal"],
      "permissions": {
        "file_operations": "allow",
        "git_operations": "allow"
      }
    },
    "frontend-dev": {
      "description": "Frontend development specialist", 
      "temperature": 0.4,
      "tools": ["filesystem", "git", "browser"],
      "permissions": {
        "file_operations": "allow",
        "git_operations": "ask"
      }
    }
  }
}
```

### Neovim Integration Setup

Configure opencode.nvim for worktree-aware development:

```lua
-- In your opencode.lua plugin config
opts = {
  terminal = {
    split_side = "right",
    split_width_percentage = 0.35,
  },
  
  -- Worktree-specific settings
  worktree = {
    auto_detect = true,
    sync_context = true,
  },
  
  context = {
    include_git_branch = true,
    include_worktree_path = true,
  },
}
```

## Workflow Examples

### Example 1: Full-Stack Feature Development

**Scenario**: Implementing a user authentication system

```bash
# 1. Create worktrees for different aspects
git worktree add ../auth-backend feature/auth-backend
git worktree add ../auth-frontend feature/auth-frontend
git worktree add ../auth-database feature/auth-database

# 2. Start specialized OpenCode sessions
cd ../auth-backend
opencode --agent backend-dev --context "Implement JWT authentication API"

cd ../auth-frontend  
opencode --agent frontend-dev --context "Create login/register components"

cd ../auth-database
opencode --agent database-dev --context "Design user authentication schema"

# 3. Work in parallel
# - Backend agent: API endpoints, middleware, JWT handling
# - Frontend agent: Login forms, state management, routing
# - Database agent: Schema design, migrations, seed data
```

### Example 2: Bug Investigation and Fixing

**Scenario**: Multiple bug reports across different modules

```bash
# Create worktrees for each bug
git worktree add ../bug-payment-validation hotfix/payment-validation
git worktree add ../bug-email-delivery hotfix/email-delivery  
git worktree add ../bug-user-permissions hotfix/user-permissions

# Start focused debugging sessions
cd ../bug-payment-validation
opencode --context "Debug payment validation failing for international cards"

cd ../bug-email-delivery
opencode --context "Investigate why confirmation emails are not being sent"

cd ../bug-user-permissions
opencode --context "Fix admin users losing permissions after login"
```

### Example 3: Experimental Development

**Scenario**: Trying different approaches to a complex problem

```bash
# Create experimental worktrees
git worktree add ../experiment-caching-redis experiment/caching-redis
git worktree add ../experiment-caching-memcached experiment/caching-memcached
git worktree add ../experiment-caching-in-memory experiment/caching-in-memory

# Run parallel experiments
cd ../experiment-caching-redis
opencode --context "Implement caching layer using Redis with clustering support"

cd ../experiment-caching-memcached  
opencode --context "Implement caching layer using Memcached with consistent hashing"

cd ../experiment-caching-in-memory
opencode --context "Implement in-memory caching with LRU eviction and persistence"

# Compare results and choose the best approach
```

### Example 4: Refactoring Legacy Code

**Scenario**: Modernizing a legacy codebase

```bash
# Create refactoring worktrees by module
git worktree add ../refactor-user-service refactor/user-service
git worktree add ../refactor-payment-service refactor/payment-service
git worktree add ../refactor-notification-service refactor/notification-service

# Start refactoring sessions
cd ../refactor-user-service
opencode --context "Refactor user service to use dependency injection and modern patterns"

cd ../refactor-payment-service  
opencode --context "Modernize payment service, add proper error handling and logging"

cd ../refactor-notification-service
opencode --context "Refactor notification service to support multiple channels and templates"
```

## Best Practices

### Worktree Management

**Naming Conventions:**
```bash
# Feature worktrees
../project-feature-[name]

# Bug fix worktrees  
../project-bugfix-[issue-id]

# Experimental worktrees
../project-experiment-[approach]

# Refactoring worktrees
../project-refactor-[module]
```

**Branch Naming:**
- `feature/[feature-name]` - New features
- `bugfix/[issue-description]` - Bug fixes
- `experiment/[approach-name]` - Experimental branches
- `refactor/[module-name]` - Refactoring work

### OpenCode Session Management

**Context Isolation:**
- Use specific, focused prompts for each session
- Include branch purpose in agent context
- Maintain separate conversation histories

**Agent Specialization:**
- Configure different agents for different types of work
- Use appropriate temperature settings (lower for backend, higher for creative work)
- Set specific tool permissions per agent type

**Session Coordination:**
```bash
# Use descriptive session names
opencode --session "auth-backend-$(date +%Y%m%d)"
opencode --session "ui-redesign-$(date +%Y%m%d)"

# Document progress in commit messages
git commit -m "feat(auth): implement JWT middleware via OpenCode session auth-backend-20250916"
```

### Synchronization Strategy

**Regular Syncing:**
```bash
# In each worktree, regularly sync with main
git fetch origin
git rebase origin/main

# Or use merge if rebase is too complex
git merge origin/main
```

**Conflict Prevention:**
- Assign different modules/files to different worktrees when possible
- Communicate changes that might affect multiple worktrees
- Use feature flags for experimental changes

**Integration Strategy:**
```bash
# Create integration branch for testing combined changes
git worktree add ../integration-test integration/multi-feature

# Merge all feature branches for testing
cd ../integration-test
git merge feature/auth-backend
git merge feature/auth-frontend  
git merge feature/auth-database

# Test integration, fix conflicts, then merge to main
```

### Performance Optimization

**Resource Management:**
- Limit the number of concurrent OpenCode sessions (typically 3-5)
- Use appropriate models for different tasks (smaller models for simple tasks)
- Monitor system resources (CPU, memory, disk I/O)

**Efficient Worktree Usage:**
```bash
# Remove completed worktrees promptly
git worktree remove ../completed-feature
git branch -d feature/completed-feature

# Use shared build directories when possible
export BUILD_DIR=/tmp/shared-build

# Avoid deep nesting of worktrees
```

## Troubleshooting

### Common Issues

**Issue 1: Worktree Creation Fails**
```bash
# Error: branch already checked out
git worktree list  # Check existing worktrees
git worktree remove [path]  # Remove if stale

# Error: branch doesn't exist
git checkout -b new-feature-branch
git worktree add ../path new-feature-branch
```

**Issue 2: OpenCode Context Confusion**
```bash
# Clear OpenCode cache
rm -rf ~/.cache/opencode/

# Restart with specific context
opencode --context "Working on [specific task] in [specific worktree]"
```

**Issue 3: Git Operations Conflicts**
```bash
# Check git status in all worktrees
for dir in ../project-*; do
  echo "=== $dir ==="
  cd "$dir" && git status --short
done

# Resolve conflicts systematically
git status
git add .
git commit -m "resolve: address conflicts in [module]"
```

**Issue 4: Performance Degradation**
```bash
# Check active OpenCode processes
ps aux | grep opencode

# Monitor resource usage
htop

# Reduce concurrent sessions if needed
```

### Debug Commands

**Worktree Diagnostics:**
```bash
# List all worktrees with details
git worktree list --verbose

# Check for prunable worktrees
git worktree prune --dry-run

# Validate worktree integrity
git fsck
```

**OpenCode Diagnostics:**
```bash
# Check OpenCode configuration
opencode config show

# Test MCP servers
opencode test mcp

# Check session list
opencode sessions list
```

### Recovery Procedures

**Corrupted Worktree:**
```bash
# Remove corrupted worktree
git worktree remove --force [path]

# Clean up references
git worktree prune

# Recreate from backup or main branch
git worktree add [path] [branch]
```

**Lost OpenCode Session:**
```bash
# List active sessions
opencode sessions list

# Reconnect to session
opencode sessions attach [session-id]

# Export session history
opencode sessions export [session-id] > session-backup.json
```

## Advanced Automation

### Custom Scripts

**Worktree Creation Script:**
```bash
#!/bin/bash
# create-feature-worktree.sh

FEATURE_NAME=$1
WORKTREE_PATH="../$(basename $(pwd))-$FEATURE_NAME"
BRANCH_NAME="feature/$FEATURE_NAME"

# Create branch and worktree
git checkout -b "$BRANCH_NAME"
git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"

# Start OpenCode in the new worktree
cd "$WORKTREE_PATH"
opencode --session "$FEATURE_NAME-$(date +%Y%m%d)" --context "Working on $FEATURE_NAME feature"

echo "Created worktree at $WORKTREE_PATH with branch $BRANCH_NAME"
```

**Batch Operations Script:**
```bash
#!/bin/bash
# sync-all-worktrees.sh

for worktree in ../$(basename $(pwd))-*; do
  if [ -d "$worktree" ]; then
    echo "Syncing $worktree..."
    cd "$worktree"
    git fetch origin
    git status --short
    echo "---"
  fi
done
```

**Integration Testing Script:**
```bash
#!/bin/bash
# test-integration.sh

INTEGRATION_BRANCH="integration/$(date +%Y%m%d)"
INTEGRATION_PATH="../$(basename $(pwd))-integration"

# Create integration worktree
git worktree add "$INTEGRATION_PATH" -b "$INTEGRATION_BRANCH"
cd "$INTEGRATION_PATH"

# Merge all feature branches
for branch in $(git branch -r | grep 'origin/feature/' | sed 's/origin\///'); do
  echo "Merging $branch..."
  git merge "origin/$branch" --no-edit
done

# Run tests
npm test
echo "Integration test complete in $INTEGRATION_PATH"
```

### Neovim Integration Automation

**Worktree Switching Function:**
```lua
-- Add to your Neovim config
local function switch_worktree()
  local worktrees = {}
  local handle = io.popen("git worktree list --porcelain")
  local result = handle:read("*a")
  handle:close()
  
  for line in result:gmatch("[^\r\n]+") do
    if line:match("^worktree ") then
      local path = line:match("^worktree (.+)")
      table.insert(worktrees, path)
    end
  end
  
  vim.ui.select(worktrees, {
    prompt = "Select worktree:",
  }, function(choice)
    if choice then
      vim.cmd("cd " .. choice)
      print("Switched to worktree: " .. choice)
    end
  end)
end

vim.keymap.set("n", "<leader>gw", switch_worktree, { desc = "Switch git worktree" })
```

**OpenCode Integration Keymaps:**
```lua
-- OpenCode + Worktree keymaps
vim.keymap.set("n", "<leader>oo", function()
  local cwd = vim.fn.getcwd()
  local branch = vim.fn.system("git branch --show-current"):gsub("\n", "")
  require("opencode").ask("@cursor: Working on " .. branch .. " in " .. cwd)
end, { desc = "OpenCode with worktree context" })

vim.keymap.set("n", "<leader>os", function()
  local session_name = vim.fn.input("Session name: ")
  if session_name ~= "" then
    vim.fn.system("opencode --session " .. session_name .. " &")
  end
end, { desc = "Start OpenCode session" })
```

### CI/CD Integration

**GitHub Actions Workflow:**
```yaml
name: Multi-Worktree Testing
on: [push, pull_request]

jobs:
  test-worktrees:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        worktree: [main, feature-a, feature-b]
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
          
      - name: Setup worktree
        run: |
          if [ "${{ matrix.worktree }}" != "main" ]; then
            git worktree add ../${{ matrix.worktree }} origin/${{ matrix.worktree }}
            cd ../${{ matrix.worktree }}
          fi
          
      - name: Run tests
        run: |
          npm test
```

**Pre-commit Hook:**
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Check all worktrees for uncommitted changes
for worktree in $(git worktree list --porcelain | grep "^worktree " | cut -d' ' -f2); do
  cd "$worktree"
  if [ -n "$(git status --porcelain)" ]; then
    echo "Warning: Uncommitted changes in worktree $worktree"
  fi
done
```

## Conclusion

Git Worktrees with OpenCode enable a powerful parallel development workflow that can significantly accelerate development velocity. By isolating contexts and enabling simultaneous work on multiple aspects of a project, this approach transforms how we think about AI-assisted development.

### Key Takeaways

1. **Isolation is Power**: Separate worktrees prevent context switching overhead
2. **Specialization Improves Quality**: Different agents for different types of work
3. **Parallel > Sequential**: Multiple agents working simultaneously beats sequential work
4. **Automation is Essential**: Scripts and tools reduce manual overhead
5. **Coordination Requires Discipline**: Clear naming, regular syncing, and good communication

### Next Steps

1. Start with simple feature-based parallelization
2. Develop custom scripts for your workflow
3. Experiment with different agent configurations
4. Build automation for common tasks
5. Share successful patterns with your team

This workflow represents the future of AI-assisted development: not just one AI helping one developer, but orchestrated teams of specialized AI agents working in parallel on complex projects.