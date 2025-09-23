------------------------------------------------------------------------
-- Claude Task Delegation System
------------------------------------------------------------------------
-- This plugin provides hierarchical task delegation for Claude Code sessions.
-- It allows parent Claude sessions to spawn child tasks in isolated git worktrees
-- with WezTerm tab management and report-back mechanisms.
--
-- Features:
-- 1. Spawn child tasks in isolated git worktrees
-- 2. WezTerm tab management with branch-based naming
-- 3. Context file generation (TASK_DELEGATION.md, CLAUDE.md)
-- 4. Report-back mechanism with git integration
-- 5. Telescope monitoring interface
--
-- Commands:
-- :TaskDelegate - Spawn child task
-- :TaskMonitor - Monitor active tasks
-- :TaskReportBack - Report task completion
-- :TaskStatus - Show task status
-- :TaskCancel - Cancel current task
--
-- Key mappings: <leader>as* namespace
--

return {
  "claude-task-delegation",
  name = "claude-task-delegation",
  dir = vim.fn.stdpath("config"),
  lazy = false,
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    -- Load the task delegation system
    local ok, claude_agents = pcall(require, "neotex.core.claude-agents.init")

    if not ok then
      vim.notify("Failed to load Claude task delegation: " .. tostring(claude_agents), vim.log.levels.ERROR)
      return
    end

    if type(claude_agents) ~= "table" or type(claude_agents.setup) ~= "function" then
      vim.notify("Claude task delegation module malformed", vim.log.levels.ERROR)
      return
    end

    -- Initialize with configuration
    claude_agents.setup({
      task_delegation = {
        auto_start_claude = true,
        report_file_name = "REPORT_BACK.md",
        delegation_file_name = "TASK_DELEGATION.md",
        context_file_name = "CLAUDE.md",
        preferred_transport = "wezterm",

        terminal = {
          set_tab_title = true,
          use_branch_name = true,
          title_prefix = "",
          strip_task_prefix = true,
          activate_on_spawn = true,
        },

        report = {
          include_diff_stat = true,
          include_commits = true,
          include_files = true,
          auto_commit_report = true,
        }
      }
    })

    vim.notify("Claude Task Delegation system ready", vim.log.levels.INFO)
  end,
  keys = {
    { "<leader>ast", "<cmd>TaskDelegate<cr>", desc = "Spawn child task" },
    { "<leader>asm", "<cmd>TaskMonitor<cr>", desc = "Monitor active tasks" },
    { "<leader>asb", "<cmd>TaskReportBack<cr>", desc = "Report back to parent" },
    { "<leader>ass", "<cmd>TaskStatus<cr>", desc = "Show task status" },
    { "<leader>asc", "<cmd>TaskCancel<cr>", desc = "Cancel task" },
  },
  cmd = {
    "TaskDelegate",
    "TaskMonitor",
    "TaskReportBack",
    "TaskStatus",
    "TaskCancel"
  },
}