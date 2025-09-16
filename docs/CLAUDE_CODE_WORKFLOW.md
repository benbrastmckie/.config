# Claude Code in Neovim: Advanced Multi-Agent Workflow with Git Worktrees

A comprehensive guide for leveraging Claude Code's multi-agent capabilities with git worktrees to maximize development efficiency and avoid conflicts.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Git Worktrees Setup](#git-worktrees-setup)
4. [Claude Code Multi-Agent Architecture](#claude-code-multi-agent-architecture)
5. [Neovim Integration](#neovim-integration)
6. [Workflow Patterns](#workflow-patterns)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)
9. [Advanced Techniques](#advanced-techniques)

## Overview

Claude Code supports running multiple concurrent sessions, each with specialized agents that can work on different aspects of your project simultaneously. By combining this with git worktrees, you can achieve true parallel development without context switching or merge conflicts.

### Key Benefits

- **Parallel Development**: Multiple Claude Code sessions working on different branches simultaneously
- **Context Isolation**: Each agent maintains its own working directory and conversation context
- **No Stashing Required**: Switch between features without committing incomplete work
- **Reduced Conflicts**: Isolated workspaces minimize merge conflicts
- **Specialized Agents**: Different agents optimized for different tasks (backend, frontend, testing, etc.)

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Main Repository (.git)                   │
└────────────────────┬────────────────────────────────────────┘
                     │
     ┌───────────────┼───────────────┬───────────────┐
     │               │               │               │
┌────▼────┐    ┌────▼────┐    ┌────▼────┐    ┌────▼────┐
│Worktree1│    │Worktree2│    │Worktree3│    │Worktree4│
│feature-a│    │feature-b│    │bugfix-c │    │refactor │
│         │    │         │    │         │    │         │
│ Claude  │    │ Claude  │    │ Claude  │    │ Claude  │
│ Build   │    │ Plan    │    │ Build   │    │ Build   │
│ Agent   │    │ Agent   │    │ Agent   │    │ Agent   │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
```

## Prerequisites

### Required Tools

```bash
# Git with worktree support (2.5+)
git --version

# Claude Code CLI
claude --version

# Neovim (0.9+)
nvim --version

# Node.js for MCP servers (optional but recommended)
node --version
```

### Claude Code Installation

```bash
# Install Claude Code globally
npm install -g @anthropic/claude-code

# Or use directly with npx
npx @anthropic/claude-code

# Verify installation
claude --help
```

## Git Worktrees Setup

### Basic Worktree Commands

```bash
# List all worktrees
git worktree list

# Add a new worktree with new branch
git worktree add ../project-feature-auth -b feature/auth

# Add worktree from existing branch
git worktree add ../project-bugfix bugfix/login-issue

# Remove a worktree
git worktree remove ../project-feature-auth

# Prune stale worktree references
git worktree prune
```

### Recommended Directory Structure

```
~/projects/
├── myproject/                 # Main repository
│   └── .git/                  # Git directory
├── myproject-feature-auth/    # Worktree for authentication
├── myproject-feature-api/     # Worktree for API development
├── myproject-bugfix-ui/       # Worktree for UI fixes
└── myproject-refactor-db/     # Worktree for database refactoring
```

### Worktree Setup Script

Create `~/.local/bin/create-worktree`:

```bash
#!/bin/bash
# Create a new worktree with Claude Code session

PROJECT_NAME=$(basename $(pwd))
FEATURE_NAME=$1
WORKTREE_TYPE=${2:-feature}  # feature, bugfix, refactor, experiment

if [ -z "$FEATURE_NAME" ]; then
    echo "Usage: create-worktree <name> [type]"
    exit 1
fi

WORKTREE_PATH="../${PROJECT_NAME}-${WORKTREE_TYPE}-${FEATURE_NAME}"
BRANCH_NAME="${WORKTREE_TYPE}/${FEATURE_NAME}"

# Create worktree
git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"

# Start Claude Code in new worktree
cd "$WORKTREE_PATH"
echo "Created worktree at: $WORKTREE_PATH"
echo "Branch: $BRANCH_NAME"
echo ""
echo "Start Claude Code with: claude"
```

## Claude Code Multi-Agent Architecture

### Understanding Claude Code Agents

Claude Code provides two primary agents you can switch between using the Tab key:

1. **Build Agent**: Full access to all tools (file operations, git, terminal)
2. **Plan Agent**: Limited tools for planning and analysis

### Subagents

Subagents are specialized assistants invoked for specific tasks:

- **general-purpose**: Complex searches, multi-step tasks
- **statusline-setup**: Configure status line settings
- **output-style-setup**: Create output styles

### Running Multiple Sessions

```bash
# Terminal 1: Feature development
cd ../myproject-feature-auth
claude
# Focus: "Implement JWT authentication with refresh tokens"

# Terminal 2: Bug fixing
cd ../myproject-bugfix-ui
claude
# Focus: "Fix responsive layout issues in dashboard"

# Terminal 3: Refactoring
cd ../myproject-refactor-db
claude
# Focus: "Optimize database queries and add indexes"
```

### Session Management Tips

1. **Clear Context**: Start each session with a clear task description
2. **Use Todo Lists**: Claude Code's TodoWrite tool helps track multi-step tasks
3. **Leverage Subagents**: Use `@general` for complex searches across the codebase
4. **Switch Agents**: Use Tab to switch between Build and Plan agents as needed

## Neovim Integration

### Setting Up Claude Code in Neovim

Add to your Neovim configuration:

```lua
-- ~/.config/nvim/lua/neotex/plugins/ai/claude-code.lua

return {
  "anthropic/claude-code.nvim",  -- Hypothetical plugin
  cmd = { "ClaudeCode", "ClaudeCodeAsk", "ClaudeCodePlan" },
  keys = {
    -- Start Claude Code in current directory
    { "<leader>cc", "<cmd>terminal claude<cr>", desc = "Start Claude Code" },
    
    -- Ask Claude Code with context
    { "<leader>ca", function()
      local prompt = vim.fn.input("Ask Claude: ")
      if prompt ~= "" then
        vim.cmd("terminal claude ask '" .. prompt .. "'")
      end
    end, desc = "Ask Claude Code" },
    
    -- Switch to worktree and start Claude
    { "<leader>cw", function()
      require("telescope").extensions.git_worktree.git_worktrees()
    end, desc = "Switch worktree with Claude" },
  },
  config = function()
    -- Custom configuration
    vim.g.claude_code_split_direction = "vertical"
    vim.g.claude_code_split_size = 80
  end,
}
```

### Worktree Management in Neovim

```lua
-- ~/.config/nvim/lua/neotex/plugins/git/worktree.lua

return {
  "ThePrimeagen/git-worktree.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  keys = {
    { "<leader>gw", function()
      require("telescope").extensions.git_worktree.git_worktrees()
    end, desc = "Switch git worktree" },
    
    { "<leader>gW", function()
      require("telescope").extensions.git_worktree.create_git_worktree()
    end, desc = "Create git worktree" },
  },
  config = function()
    require("git-worktree").setup({
      change_directory_command = "cd",
      update_on_change = true,
      update_on_change_command = "e .",
      clearjumps_on_change = true,
      autopush = false,
    })
    
    -- Automatically start Claude Code in new worktree
    local Worktree = require("git-worktree")
    Worktree.on_tree_change(function(op, metadata)
      if op == Worktree.Operations.Switch then
        print("Switched to " .. metadata.path)
        -- Optional: Start Claude Code automatically
        -- vim.cmd("terminal claude")
      end
    end)
  end,
}
```

### Integrated Workflow Commands

```lua
-- ~/.config/nvim/lua/neotex/core/claude-worktree.lua

local M = {}

-- Create worktree and start Claude Code
function M.create_feature_worktree()
  local feature_name = vim.fn.input("Feature name: ")
  if feature_name == "" then return end
  
  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  local worktree_path = "../" .. project_name .. "-feature-" .. feature_name
  local branch_name = "feature/" .. feature_name
  
  -- Create worktree
  vim.fn.system("git worktree add " .. worktree_path .. " -b " .. branch_name)
  
  -- Change to new worktree
  vim.cmd("cd " .. worktree_path)
  
  -- Start Claude Code in a terminal
  vim.cmd("vsplit | terminal claude")
  
  print("Created worktree: " .. worktree_path)
end

-- List all active Claude Code sessions
function M.list_claude_sessions()
  local sessions = vim.fn.systemlist("ps aux | grep 'claude' | grep -v grep")
  if #sessions > 0 then
    print("Active Claude Code sessions:")
    for _, session in ipairs(sessions) do
      print("  " .. session)
    end
  else
    print("No active Claude Code sessions")
  end
end

-- Quick switch between worktrees
function M.switch_worktree_with_claude()
  local worktrees = vim.fn.systemlist("git worktree list --porcelain | grep '^worktree' | cut -d' ' -f2")
  
  vim.ui.select(worktrees, {
    prompt = "Select worktree:",
    format_item = function(item)
      local branch = vim.fn.system("cd " .. item .. " && git branch --show-current"):gsub("\n", "")
      return item .. " (" .. branch .. ")"
    end,
  }, function(choice)
    if choice then
      vim.cmd("cd " .. choice)
      local start_claude = vim.fn.confirm("Start Claude Code?", "&Yes\n&No", 1)
      if start_claude == 1 then
        vim.cmd("vsplit | terminal claude")
      end
    end
  end)
end

-- Set up keymaps
function M.setup()
  vim.keymap.set("n", "<leader>cwf", M.create_feature_worktree, { desc = "Create feature worktree with Claude" })
  vim.keymap.set("n", "<leader>cws", M.switch_worktree_with_claude, { desc = "Switch worktree with Claude" })
  vim.keymap.set("n", "<leader>cwl", M.list_claude_sessions, { desc = "List Claude Code sessions" })
end

return M
```

## Workflow Patterns

### Pattern 1: Feature Development with Multiple Components

```bash
# Backend API development
cd ../myproject-feature-api-backend
claude
# "Implement REST API endpoints for user management with authentication"

# Frontend UI development
cd ../myproject-feature-api-frontend
claude
# "Create React components for user management dashboard"

# Database migrations
cd ../myproject-feature-api-db
claude
# "Design database schema and migrations for user management"
```

### Pattern 2: Bug Investigation and Fixing

```bash
# Reproduce and investigate
cd ../myproject-bugfix-investigation
claude
# "Help me reproduce and investigate the login timeout issue reported in #123"

# Implement fix
cd ../myproject-bugfix-implementation
claude
# "Fix the session timeout issue by implementing proper token refresh"

# Add tests
cd ../myproject-bugfix-tests
claude
# "Add comprehensive tests for session management and token refresh"
```

### Pattern 3: Refactoring with Safety

```bash
# Analyze current implementation
cd ../myproject-refactor-analysis
claude
# Use Plan agent (Tab to switch): "Analyze the current authentication system for refactoring opportunities"

# Implement refactoring
cd ../myproject-refactor-implementation
claude
# Use Build agent: "Refactor authentication to use dependency injection pattern"

# Verify no regressions
cd ../myproject-refactor-verification
claude
# "Run all tests and verify no functionality has been broken"
```

### Pattern 4: Experimental Development

```bash
# Try approach A
cd ../myproject-experiment-redis
claude
# "Implement caching using Redis with automatic invalidation"

# Try approach B
cd ../myproject-experiment-memcached
claude
# "Implement caching using Memcached with consistent hashing"

# Compare and merge best solution
cd ../myproject-experiment-final
claude
# "Compare both caching implementations and integrate the best approach"
```

## Best Practices

### 1. Context Management

```markdown
# Good: Clear, specific context
"Implement user authentication using JWT with the following requirements:
- Access tokens expire in 15 minutes
- Refresh tokens expire in 7 days
- Store refresh tokens in httpOnly cookies
- Implement token rotation on refresh"

# Bad: Vague context
"Add authentication"
```

### 2. Todo List Usage

Always use Claude Code's TodoWrite tool for complex tasks:

```markdown
"Create a todo list for implementing the payment system:
1. Design payment database schema
2. Implement Stripe integration
3. Create payment processing service
4. Add webhook handlers
5. Implement refund functionality
6. Add payment history API
7. Create payment notification system
8. Write comprehensive tests"
```

### 3. Subagent Utilization

```markdown
# Use general-purpose subagent for complex searches
"@general Search for all instances of direct database access that should use the repository pattern"

# Let Claude Code automatically invoke subagents
"Find and refactor all hardcoded configuration values to use environment variables"
```

### 4. Branch Synchronization

```bash
# Regular sync script
#!/bin/bash
# sync-worktrees.sh

for worktree in ../myproject-*; do
  if [ -d "$worktree/.git" ]; then
    echo "Syncing $worktree..."
    cd "$worktree"
    git fetch origin
    git rebase origin/main || git rebase --abort
    cd - > /dev/null
  fi
done
```

### 5. Commit Practices

```bash
# Use Claude Code's git commit feature
"Create a git commit for the authentication implementation. 
Make sure to:
- Include all changed files
- Write a clear commit message following conventional commits
- Run tests before committing"
```

## Troubleshooting

### Common Issues and Solutions

#### Issue: Claude Code context confusion between worktrees

**Solution**: Always start with clear context about which worktree/feature you're working on:

```markdown
"I'm in the feature/auth worktree working on JWT implementation. 
The current task is to add refresh token rotation."
```

#### Issue: Merge conflicts when integrating worktrees

**Solution**: Use integration branches:

```bash
# Create integration branch
git worktree add ../myproject-integration integration/combined-features

# Merge all feature branches
cd ../myproject-integration
git merge feature/auth
git merge feature/api
git merge feature/ui

# Resolve conflicts with Claude Code
claude
# "Help me resolve merge conflicts, prioritizing the newer implementation"
```

#### Issue: Claude Code performance with multiple sessions

**Solution**: Limit concurrent sessions and use appropriate models:

```bash
# Check active sessions
ps aux | grep claude | wc -l

# Kill unused sessions
pkill -f "claude.*feature-old"

# Use lighter models for simple tasks
claude --model claude-3-haiku-20240307
```

#### Issue: Lost Claude Code conversation context

**Solution**: Save important context to CLAUDE.md:

```markdown
# In CLAUDE.md or .claude/context.md
## Current Task Context

Working on feature/auth branch:
- JWT implementation complete
- Refresh tokens in progress
- Next: Add token rotation
- Tests: 15/20 complete
```

## Advanced Techniques

### 1. Automated Worktree Creation with Context

```bash
#!/bin/bash
# create-contextual-worktree.sh

FEATURE=$1
CONTEXT=$2
TYPE=${3:-feature}

WORKTREE="../myproject-$TYPE-$FEATURE"
BRANCH="$TYPE/$FEATURE"

# Create worktree
git worktree add "$WORKTREE" -b "$BRANCH"

# Create context file
cat > "$WORKTREE/.claude-context" << EOF
# Context for $BRANCH
$CONTEXT

## Todo List
- [ ] Initial implementation
- [ ] Add tests
- [ ] Documentation
- [ ] Code review

## Notes
Created: $(date)
Type: $TYPE
Feature: $FEATURE
EOF

# Start Claude Code with context
cd "$WORKTREE"
claude ask "Read .claude-context and help me get started"
```

### 2. Multi-Agent Coordination

```bash
# coordinator.sh - Coordinate multiple Claude Code agents

#!/bin/bash

# Start backend agent
tmux new-session -d -s backend -c ../myproject-backend 'claude'
tmux send-keys -t backend "Work on implementing the user service API" C-m

# Start frontend agent
tmux new-session -d -s frontend -c ../myproject-frontend 'claude'
tmux send-keys -t frontend "Create the user management UI components" C-m

# Start test agent
tmux new-session -d -s testing -c ../myproject-tests 'claude'
tmux send-keys -t testing "Write integration tests for user service" C-m

# Monitor all sessions
tmux new-session -s monitor \; \
  split-window -h \; \
  split-window -v \; \
  send-keys -t 0 'tmux attach -t backend' C-m \; \
  send-keys -t 1 'tmux attach -t frontend' C-m \; \
  send-keys -t 2 'tmux attach -t testing' C-m
```

### 3. Context Sharing Between Agents

```lua
-- ~/.config/nvim/lua/neotex/core/claude-sync.lua

local M = {}

-- Share context between Claude Code sessions
function M.share_context()
  local context_file = vim.fn.getcwd() .. "/.claude-shared-context.md"
  
  -- Get current buffer content
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines, "\n")
  
  -- Write to shared context
  local file = io.open(context_file, "w")
  file:write("# Shared Context\n")
  file:write("Updated: " .. os.date() .. "\n\n")
  file:write("## Current File\n")
  file:write(vim.fn.expand("%:p") .. "\n\n")
  file:write("## Content\n```\n")
  file:write(content)
  file:write("\n```\n")
  file:close()
  
  -- Notify all Claude Code sessions
  vim.fn.system("tmux list-sessions | grep -E 'claude|backend|frontend' | cut -d: -f1 | xargs -I{} tmux send-keys -t {} 'Read .claude-shared-context.md for updated context' C-m")
  
  print("Context shared with all Claude Code sessions")
end

vim.keymap.set("n", "<leader>cs", M.share_context, { desc = "Share context with Claude Code sessions" })

return M
```

### 4. Automated Testing Across Worktrees

```yaml
# .github/workflows/worktree-tests.yml
name: Test All Worktrees

on:
  schedule:
    - cron: '0 */4 * * *'  # Every 4 hours
  workflow_dispatch:

jobs:
  test-worktrees:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        worktree: 
          - { name: 'feature-auth', branch: 'feature/auth' }
          - { name: 'feature-api', branch: 'feature/api' }
          - { name: 'bugfix-ui', branch: 'bugfix/ui' }
    
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Setup worktree
        run: |
          git worktree add ../${{ matrix.worktree.name }} origin/${{ matrix.worktree.branch }}
          cd ../${{ matrix.worktree.name }}
      
      - name: Run tests
        run: |
          npm install
          npm test
      
      - name: Report status
        if: always()
        run: |
          echo "Worktree ${{ matrix.worktree.name }} test status: ${{ job.status }}"
```

### 5. Performance Monitoring

```bash
#!/bin/bash
# monitor-claude-sessions.sh

while true; do
  clear
  echo "Claude Code Session Monitor - $(date)"
  echo "================================"
  
  # Show active worktrees
  echo -e "\nActive Worktrees:"
  git worktree list | column -t
  
  # Show Claude Code processes
  echo -e "\nClaude Code Sessions:"
  ps aux | grep -E "claude|opencode" | grep -v grep | awk '{print $2, $11, $12}' | column -t
  
  # Show memory usage
  echo -e "\nMemory Usage:"
  free -h | grep -E "^Mem|^Swap"
  
  # Show disk usage for worktrees
  echo -e "\nWorktree Disk Usage:"
  du -sh ../myproject-* 2>/dev/null | sort -h
  
  sleep 5
done
```

## Conclusion

By combining Claude Code's multi-agent capabilities with git worktrees, you can achieve unprecedented development velocity through true parallel processing. Each agent can focus on its specific task without interference, while git worktrees ensure clean separation of changes.

### Key Takeaways

1. **Use worktrees liberally** - They're lightweight and prevent context switching
2. **Specialize your agents** - Different tasks benefit from different agent configurations
3. **Maintain clear context** - Always tell Claude Code what worktree and task it's working on
4. **Automate repetitive tasks** - Scripts and Neovim integration save significant time
5. **Monitor and optimize** - Keep track of active sessions and system resources

### Next Steps

1. Set up your first multi-worktree workflow
2. Create custom scripts for your specific needs
3. Integrate with your Neovim configuration
4. Experiment with different agent specializations
5. Share your patterns with your team

This workflow transforms Claude Code from a single assistant into a team of specialized agents, each working in parallel to accelerate your development process.
