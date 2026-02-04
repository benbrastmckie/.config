-- MCP Integration with lean-lsp-mcp
-- ===================================
-- This plugin integrates with lean-lsp-mcp Model Context Protocol server
-- for AI-assisted theorem proving via Claude Code.
--
-- Configuration:
--   - Create .mcp.json in Lean project root (see template below)
--   - Invoke Claude Code with <leader>a mappings
--   - MCP tools available: lean_file_outline, lean_diagnostic_messages,
--     lean_goal, lean_hover, lean_leansearch, lean_loogle, lean_local_search, etc.
--
-- Example .mcp.json:
--   {
--     "mcpServers": {
--       "lean-lsp": {
--         "type": "stdio",
--         "command": "uvx",
--         "args": ["lean-lsp-mcp"],
--         "env": {
--           "LEAN_LOG_LEVEL": "WARNING",
--           "LEAN_PROJECT_PATH": "${workspaceFolder}"
--         }
--       }
--     }
--   }
--
-- Example Claude Prompts:
--   - "Show me the proof goals at line 42"
--   - "Find theorems about list concatenation in Mathlib"
--   - "Help me prove theorem add_comm: a + b = b + a"
--   - "What errors are in this file?"
--   - "Search local project for definitions of 'monad'"
--
-- Keybindings:
--   - <leader>ri: Toggle Lean infoview (direct lean.nvim, faster than MCP)
--   - <leader>a:  Invoke Claude Code (primary MCP interface)
--
-- Performance Tips:
--   - Run `lake build` before MCP session to avoid timeout
--   - Use local search (lean_local_search) first to avoid rate limits
--   - External search tools limited to 3 requests/30 seconds
--
-- Troubleshooting:
--   - MCP server not appearing: Verify .mcp.json in project root
--   - Timeout on startup: Run `lake build` to compile project first
--   - Rate limit errors: Wait 30 seconds between external search calls
--   - Verbose logging: Set LEAN_LOG_LEVEL=INFO in .mcp.json
--
-- AI-Assisted Theorem Proving Workflow:
-- 1. Open Lean file: nvim MyTheorem.lean
-- 2. Verify project built: :!lake build
-- 3. Toggle infoview: <leader>ri
-- 4. Invoke Claude Code: <leader>a
-- 5. Request assistance: "Help me prove this theorem"
-- 6. Claude queries:
--    - Current goal state (lean_goal)
--    - Relevant theorems (lean_leansearch, lean_loogle)
--    - Local definitions (lean_local_search)
-- 7. Claude suggests proof tactics
-- 8. User applies tactics, iterates

return {
  'Julian/lean.nvim',
  event = { 'BufReadPre *.lean', 'BufNewFile *.lean' },
  dependencies = {
    'nvim-lua/plenary.nvim',
    -- nvim-lspconfig removed - lean.nvim uses vim.lsp.config directly (Neovim 0.11+)
    -- nvim-cmp dependencies removed - project uses blink.cmp
  },

  -- Keybindings for Lean-specific operations
  keys = {
    {
      "<leader>ri",
      function() require('lean').infoview.toggle() end,
      desc = "lean infoview",
      ft = "lean"
    },
  },

  -- Configuration options for lean.nvim
  opts = {
    abbreviations = {
      enabled = false
    },
    -- For notifications
    stderr = {
      enable = true,
      on_lines = function(lines)
        vim.schedule(function()
          vim.notify(lines)
        end)
      end
    },
    mappings = true, -- Enable default key mappings
    infoview = {
      autoopen = true,
    }
  },

  -- Configuration function to set up lean.nvim and related settings
  config = function(_, opts)
    -- NixOS fix: Configure Lean LSP with TZ environment variable
    -- This prevents "Watchdog error: no such file or directory /etc/localtime"
    vim.lsp.config('leanls', {
      cmd_env = {
        TZ = os.getenv("TZ") or "UTC"
      }
    })

    -- Add protected semantic token handling
    local semantic_tokens_handler = function(err, result, ctx, config)
      if err then return end

      -- Protect against invalid results
      if not result or not result.data then return end

      -- Use pcall to safely handle semantic tokens
      pcall(function()
        vim.lsp.semantic_tokens.on_full(err, result, ctx, config)
      end)
    end

    -- Override the semantic tokens handler
    vim.lsp.handlers['textDocument/semanticTokens/full'] = semantic_tokens_handler

    -- Initialize lean.nvim with the provided options
    require('lean').setup(opts)

    -- Create an augroup for Lean-related autocommands
    local lean_group = vim.api.nvim_create_augroup("LeanCloseInfoview", { clear = true })

    -- Close infoview before buffer deletion to prevent "Invalid buffer id" error
    -- in lean.nvim's WinLeave autocmd (infoview.lua:964 __update_extmark_style)
    -- See: Task #41 - fix_leanls_lsp_client_exit_error
    vim.api.nvim_create_autocmd("BufDelete", {
      group = lean_group,
      pattern = "*.lean",
      callback = function()
        pcall(function()
          local infoview = require("lean.infoview")
          if infoview.get_current_infoview() then
            infoview.close()
          end
        end)
      end,
      desc = "Close infoview before Lean buffer deletion",
    })

    -- Prevent Infoview Buffer from Appearing in Buffer Lists
    vim.api.nvim_create_autocmd("FileType", {
      group = lean_group,
      pattern = "leaninfo", -- Infoview buffer filetype
      callback = function()
        -- Set buffer options to exclude it from buffer lists and normal operations
        vim.bo.buflisted = false  -- Exclude from buffer lists
        vim.bo.bufhidden = "hide" -- Hide the buffer when it's no longer displayed
        vim.bo.buftype = "nofile" -- Specify that it's not associated with a file
        -- Optional: Prevent modifications to the Infoview buffer
        vim.bo.modifiable = false
        vim.bo.swapfile = false
      end,
    })

  end
}
