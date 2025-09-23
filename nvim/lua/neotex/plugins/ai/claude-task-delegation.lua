-----------------------------------------------------------
-- Claude Task Delegation Plugin Specification
--
-- Integrates the claude-agents task delegation system with
-- the existing plugin infrastructure using Lazy.nvim
-----------------------------------------------------------

-- This is a virtual plugin spec for the built-in task delegation system
return {
  "claude-task-delegation",
  name = "claude-task-delegation",
  dir = vim.fn.stdpath("config"), -- Use the config directory as the plugin source
  lazy = false, -- Load immediately since this is a local module
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    -- Set up the task delegation system
    local claude_agents = require("neotex.plugins.ai.claude-agents.init")

    -- Initialize with default configuration
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

    -- Notify that the system is ready
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