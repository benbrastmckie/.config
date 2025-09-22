-----------------------------------------------------------
-- Git Information Helper Module
--
-- Provides git repository status and statistics functions
-- Used by claude-worktree for master branch previews
-----------------------------------------------------------

local M = {}

-- Cache for git information (5 second expiry)
local cache = {
  data = {},
  timestamp = 0,
  duration = 5000  -- milliseconds
}

-- Helper: Clear cache
function M.clear_cache()
  cache.data = {}
  cache.timestamp = 0
end

-- Helper: Get cached or fresh data
local function get_cached(key, fetcher)
  local now = vim.loop.now()
  if cache.timestamp + cache.duration > now and cache.data[key] then
    return cache.data[key]
  end
  
  local result = fetcher()
  cache.data[key] = result
  cache.timestamp = now
  return result
end

-- Check if repository has uncommitted changes
function M.is_repository_dirty()
  return get_cached("dirty", function()
    local result = vim.fn.system("git status --porcelain 2>/dev/null")
    return vim.v.shell_error == 0 and result ~= ""
  end)
end

-- Get detailed git status
function M.get_git_status()
  return get_cached("status", function()
    local status = {
      branch = "main",
      head = nil,
      head_message = nil,
      remote_ahead = 0,
      remote_behind = 0,
      staged = {},
      modified = {},
      untracked = {},
      total_changes = 0
    }
    
    -- Get current branch
    local branch = vim.fn.system("git branch --show-current 2>/dev/null")
    if vim.v.shell_error == 0 then
      status.branch = vim.trim(branch)
    end
    
    -- Get HEAD commit
    local head = vim.fn.system("git rev-parse --short HEAD 2>/dev/null")
    if vim.v.shell_error == 0 then
      status.head = vim.trim(head)
    end
    
    -- Get HEAD commit message
    local message = vim.fn.system("git log -1 --pretty=format:%s 2>/dev/null")
    if vim.v.shell_error == 0 then
      status.head_message = vim.trim(message)
    end
    
    -- Get ahead/behind counts
    local remote_status = vim.fn.system("git rev-list --left-right --count HEAD...@{u} 2>/dev/null")
    if vim.v.shell_error == 0 then
      local ahead, behind = remote_status:match("(%d+)%s+(%d+)")
      if ahead then status.remote_ahead = tonumber(ahead) end
      if behind then status.remote_behind = tonumber(behind) end
    end
    
    -- Get staged files
    local staged = vim.fn.system("git diff --cached --name-status 2>/dev/null")
    if vim.v.shell_error == 0 then
      for line in staged:gmatch("[^\n]+") do
        local stat, file = line:match("^(%S+)%s+(.+)$")
        if stat and file then
          table.insert(status.staged, { status = stat, file = file })
        end
      end
    end
    
    -- Get modified files
    local modified = vim.fn.system("git diff --name-status 2>/dev/null")
    if vim.v.shell_error == 0 then
      for line in modified:gmatch("[^\n]+") do
        local stat, file = line:match("^(%S+)%s+(.+)$")
        if stat and file then
          table.insert(status.modified, { status = stat, file = file })
        end
      end
    end
    
    -- Get untracked files
    local untracked = vim.fn.system("git ls-files --others --exclude-standard 2>/dev/null")
    if vim.v.shell_error == 0 then
      for file in untracked:gmatch("[^\n]+") do
        table.insert(status.untracked, { status = "?", file = file })
      end
    end
    
    status.total_changes = #status.staged + #status.modified + #status.untracked
    
    return status
  end)
end

-- Get branch comparison information
function M.get_branch_comparison(base_branch)
  base_branch = base_branch or "main"
  
  return get_cached("branches", function()
    local comparison = {
      active = {},
      merged = {},
      stale = {}
    }
    
    -- Get all branches with info
    local branches_info = vim.fn.system("git for-each-ref --format='%(refname:short)|%(committerdate:relative)|%(committerdate:unix)' refs/heads/ 2>/dev/null")
    if vim.v.shell_error ~= 0 then
      return comparison
    end
    
    -- Get worktree branches
    local worktree_output = vim.fn.system("git worktree list 2>/dev/null")
    local worktree_branches = {}
    if vim.v.shell_error == 0 then
      for line in worktree_output:gmatch("[^\n]+") do
        local branch = line:match("%[(.+)%]")
        if branch then
          worktree_branches[branch] = true
        end
      end
    end
    
    -- Get merged branches
    local merged_output = vim.fn.system("git branch --merged " .. base_branch .. " 2>/dev/null")
    local merged_branches = {}
    if vim.v.shell_error == 0 then
      for branch in merged_output:gmatch("[^\n]+") do
        branch = vim.trim(branch:gsub("^%*", ""))
        if branch ~= base_branch then
          merged_branches[branch] = true
        end
      end
    end
    
    local now = os.time()
    local thirty_days = 30 * 24 * 60 * 60
    
    for line in branches_info:gmatch("[^\n]+") do
      local branch, relative_date, unix_time = line:match("^([^|]+)|([^|]+)|(.+)$")
      
      if branch and branch ~= base_branch then
        -- Get ahead/behind
        local rev_list = vim.fn.system(string.format("git rev-list --left-right --count %s...%s 2>/dev/null", base_branch, branch))
        local behind, ahead = 0, 0
        if vim.v.shell_error == 0 then
          behind, ahead = rev_list:match("(%d+)%s+(%d+)")
          behind = tonumber(behind) or 0
          ahead = tonumber(ahead) or 0
        end
        
        local branch_info = {
          name = branch,
          ahead = ahead,
          behind = behind,
          date = relative_date,
          has_worktree = worktree_branches[branch] or false
        }
        
        -- Categorize branch
        if merged_branches[branch] then
          table.insert(comparison.merged, branch_info)
        elseif tonumber(unix_time) and (now - tonumber(unix_time)) > thirty_days then
          branch_info.is_stale = true
          table.insert(comparison.stale, branch_info)
        else
          table.insert(comparison.active, branch_info)
        end
      end
    end
    
    -- Sort active branches by date (most recent first)
    table.sort(comparison.active, function(a, b)
      return a.date < b.date  -- "2 days ago" < "3 days ago"
    end)
    
    -- Limit results by taking only first N items
    local function limit_table(tbl, max)
      local result = {}
      for i = 1, math.min(#tbl, max) do
        result[i] = tbl[i]
      end
      return result
    end
    
    comparison.active = limit_table(comparison.active, 5)
    comparison.merged = limit_table(comparison.merged, 3)
    comparison.stale = limit_table(comparison.stale, 3)
    
    return comparison
  end)
end

-- Get repository statistics
function M.get_repository_stats()
  return get_cached("stats", function()
    local stats = {
      repo_name = nil,
      default_branch = "main",
      total_commits = 0,
      contributors = 0,
      worktrees = 0,
      branches_local = 0,
      branches_remote = 0,
      disk_usage = nil
    }
    
    -- Repository name
    local toplevel = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null")
    if vim.v.shell_error == 0 then
      stats.repo_name = vim.fn.fnamemodify(vim.trim(toplevel), ":t")
    end
    
    -- Default branch
    local default = vim.fn.system("git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null")
    if vim.v.shell_error == 0 then
      local branch = default:match("refs/remotes/origin/(.+)")
      if branch then
        stats.default_branch = vim.trim(branch)
      end
    end
    
    -- Total commits
    local commits = vim.fn.system("git rev-list --all --count 2>/dev/null")
    if vim.v.shell_error == 0 then
      stats.total_commits = tonumber(vim.trim(commits)) or 0
    end
    
    -- Contributors
    local contributors = vim.fn.system("git shortlog -sn --all 2>/dev/null | wc -l")
    if vim.v.shell_error == 0 then
      stats.contributors = tonumber(vim.trim(contributors)) or 0
    end
    
    -- Worktrees
    local worktrees = vim.fn.system("git worktree list 2>/dev/null | wc -l")
    if vim.v.shell_error == 0 then
      stats.worktrees = tonumber(vim.trim(worktrees)) or 0
    end
    
    -- Branch counts
    local local_branches = vim.fn.system("git branch | wc -l 2>/dev/null")
    if vim.v.shell_error == 0 then
      stats.branches_local = tonumber(vim.trim(local_branches)) or 0
    end
    
    local remote_branches = vim.fn.system("git branch -r | wc -l 2>/dev/null")
    if vim.v.shell_error == 0 then
      stats.branches_remote = tonumber(vim.trim(remote_branches)) or 0
    end
    
    -- Disk usage
    local disk = vim.fn.system("du -sh .git 2>/dev/null | cut -f1")
    if vim.v.shell_error == 0 then
      stats.disk_usage = vim.trim(disk)
    end
    
    return stats
  end)
end

-- Format status view for preview
function M.format_status_preview(status_data)
  local lines = {}
  
  -- Header
  table.insert(lines, "# Main Branch Status")
  table.insert(lines, "")
  table.insert(lines, "## Current State")
  table.insert(lines, string.format("**Branch**: %s", status_data.branch))
  
  if status_data.head then
    local head_line = string.format("**HEAD**: %s", status_data.head)
    if status_data.head_message then
      head_line = head_line .. " " .. status_data.head_message
    end
    table.insert(lines, head_line)
  end
  
  if status_data.remote_ahead > 0 or status_data.remote_behind > 0 then
    table.insert(lines, string.format("**Remote**: origin/%s (ahead %d, behind %d)",
      status_data.branch, status_data.remote_ahead, status_data.remote_behind))
  end
  
  table.insert(lines, "")
  table.insert(lines, string.format("## Uncommitted Changes (%d files)", status_data.total_changes))
  table.insert(lines, "")
  
  -- Staged files
  if #status_data.staged > 0 then
    table.insert(lines, string.format("### Staged (%d)", #status_data.staged))
    for i, item in ipairs(status_data.staged) do
      if i <= 10 then
        table.insert(lines, string.format("- %s  %s", item.status, item.file))
      end
    end
    if #status_data.staged > 10 then
      table.insert(lines, string.format("... (%d more)", #status_data.staged - 10))
    end
    table.insert(lines, "")
  end
  
  -- Modified files
  if #status_data.modified > 0 then
    table.insert(lines, string.format("### Modified (%d)", #status_data.modified))
    for i, item in ipairs(status_data.modified) do
      if i <= 10 then
        table.insert(lines, string.format("- %s  %s", item.status, item.file))
      end
    end
    if #status_data.modified > 10 then
      table.insert(lines, string.format("... (%d more)", #status_data.modified - 10))
    end
    table.insert(lines, "")
  end
  
  -- Untracked files
  if #status_data.untracked > 0 then
    table.insert(lines, string.format("### Untracked (%d)", #status_data.untracked))
    for i, item in ipairs(status_data.untracked) do
      if i <= 5 then
        table.insert(lines, string.format("- %s  %s", item.status, item.file))
      end
    end
    if #status_data.untracked > 5 then
      table.insert(lines, string.format("... (%d more)", #status_data.untracked - 5))
    end
    table.insert(lines, "")
  end
  
  return lines
end

-- Format branch comparison for preview
function M.format_branch_preview(branch_data)
  local lines = {}
  
  -- Header
  table.insert(lines, "# Main Branch Overview")
  table.insert(lines, "")
  table.insert(lines, "## Current State")
  table.insert(lines, "**Branch**: main")
  table.insert(lines, "**Status**: ✓ Clean (no uncommitted changes)")
  table.insert(lines, "")
  
  -- Branch comparison
  table.insert(lines, "## Branch Comparison")
  table.insert(lines, "")
  
  -- Active branches
  if #branch_data.active > 0 then
    table.insert(lines, string.format("### Active Development (%d)", #branch_data.active))
    for _, branch in ipairs(branch_data.active) do
      local line = string.format("- %-25s ↑%-3d ↓%-3d (%s)",
        branch.name, branch.ahead, branch.behind, branch.date)
      if branch.has_worktree then
        line = line .. "  [has worktree]"
      end
      table.insert(lines, line)
    end
    table.insert(lines, "")
  end
  
  -- Recently merged
  if #branch_data.merged > 0 then
    table.insert(lines, string.format("### Recently Merged (%d)", #branch_data.merged))
    for _, branch in ipairs(branch_data.merged) do
      table.insert(lines, string.format("- %-25s (merged %s)", branch.name, branch.date))
    end
    table.insert(lines, "")
  end
  
  -- Stale branches
  if #branch_data.stale > 0 then
    table.insert(lines, string.format("### Stale Branches (%d)", #branch_data.stale))
    for _, branch in ipairs(branch_data.stale) do
      table.insert(lines, string.format("- %-25s (%s, ↑%d ↓%d)",
        branch.name, branch.date, branch.ahead, branch.behind))
    end
    table.insert(lines, "")
  end
  
  return lines
end

-- Format statistics section
function M.format_stats_section(stats_data, claude_sessions)
  local lines = {}
  
  table.insert(lines, "---")
  table.insert(lines, "## Quick Stats")
  
  if stats_data.repo_name then
    table.insert(lines, string.format("- Repository: %s", stats_data.repo_name))
  end
  
  table.insert(lines, string.format("- Default branch: %s", stats_data.default_branch))
  table.insert(lines, string.format("- Total commits: %s", 
    stats_data.total_commits > 0 and tostring(stats_data.total_commits) or "N/A"))
  
  if stats_data.contributors > 0 then
    table.insert(lines, string.format("- Contributors: %d", stats_data.contributors))
  end
  
  table.insert(lines, string.format("- Worktrees: %d active", stats_data.worktrees))
  
  -- Count Claude sessions
  local session_count = 0
  if claude_sessions then
    for _, session in pairs(claude_sessions) do
      if session.session_id then
        session_count = session_count + 1
      end
    end
  end
  table.insert(lines, string.format("- Claude sessions: %d active", session_count))
  
  if stats_data.disk_usage then
    table.insert(lines, string.format("- Disk usage: %s", stats_data.disk_usage))
  end
  
  table.insert(lines, string.format("- Total branches: %d (local), %d (remote)",
    stats_data.branches_local, stats_data.branches_remote))
  
  return lines
end

return M