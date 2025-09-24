-- Git utility functions for Claude AI integration
local M = {}

-- Get the current git branch
function M.get_current_branch()
  return vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", "")
end

-- Get the git root directory
function M.get_git_root()
  return vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
end

-- Check if current directory is a git repository
function M.is_git_repo()
  local git_dir = vim.fn.system("git rev-parse --git-dir 2>/dev/null"):gsub("\n", "")
  return git_dir:match("%.git") ~= nil
end

-- Get list of worktrees
function M.get_worktree_list()
  return vim.fn.system("git worktree list 2>/dev/null")
end

-- Get detailed worktree list (porcelain format)
function M.get_worktree_list_porcelain()
  return vim.fn.systemlist("git worktree list --porcelain")
end

-- Add a new worktree
function M.add_worktree(path, branch)
  return vim.fn.system("git worktree add " .. path .. " -b " .. branch)
end

-- Remove a worktree
function M.remove_worktree(path, force)
  local force_flag = force and " --force" or ""
  return vim.fn.system("git worktree remove " .. path .. force_flag)
end

-- Check if a branch exists in any worktree
function M.branch_exists_in_worktree(branch)
  local existing = vim.fn.system("git worktree list | grep " .. branch)
  return existing ~= ""
end

return M