------------------------------------------------------------------------
-- Avante AI Assistant Plugin Configuration
------------------------------------------------------------------------
-- This module provides a powerful AI assistant with MCP-Hub integration
--
-- Features:
-- 1. Multiple AI provider support (Claude, GPT, Gemini)
-- 2. MCP-Hub integration for custom tools and prompts
-- 3. System prompt management and custom keybindings
-- 4. UI enhancements with inline suggestions and markdown rendering
--
-- Commands:
-- See README.md for complete keybinding reference
-- Key mappings in <leader>h... namespace
--
-- See: https://github.com/yetone/avante.nvim

return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  -- Fix version format to prevent parsing error
  version = false, -- Using latest version to get the most recent fixes
  -- Explicitly checking for Neovim 0.10.1+ compatibility
  cond = function()
    if vim.fn.has("nvim-0.10.1") == 0 then
      vim.notify("Avante requires Neovim 0.10.1 or later", vim.log.levels.WARN)
      return false
    end
    return true
  end,
  init = function()
    -- Set recommended vim option for best Avante view compatibility
    -- Views can only be fully collapsed with the global statusline
    vim.opt.laststatus = 3

    -- Set up theme-aware highlighting for Avante
    local ok, highlights = pcall(require, "neotex.plugins.ai.util.avante-highlights")
    if ok and highlights.setup then
      -- Initialize the streamlined highlighting system
      -- This provides essential diff and suggestion highlighting with theme integration
      highlights.setup()
    end
    
    -- Create Avante commands that trigger MCPHub loading first
    local function create_avante_command(name, command)
      vim.api.nvim_create_user_command(name, function(opts)
        -- First trigger the event to load MCPHub
        vim.api.nvim_exec_autocmds("User", { pattern = "AvantePreLoad" })
        
        -- Use our helper function to ensure MCPHub is loaded and run Avante
        local avante_mcp = require("neotex.plugins.ai.util.avante_mcp")
        avante_mcp.with_mcp(command .. " " .. (opts.args or ""))
      end, { nargs = "*" })
    end
    
    -- Set up command wrappers that ensure MCPHub is loaded
    create_avante_command("AvanteAsk", "AvanteAsk")
    create_avante_command("AvanteChat", "AvanteChat")
    create_avante_command("AvanteToggle", "AvanteToggle")
    create_avante_command("AvanteEdit", "AvanteEdit")
    
    -- Add special handling for MCPHub integration when Avante starts
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "Avante", "AvanteInput" },
      callback = function()
        -- Only run once per buffer
        if vim.b.mcphub_integrated then
          return
        end
        vim.b.mcphub_integrated = true
        
        -- Try to integrate MCPHub with Avante now that both are loaded
        vim.defer_fn(function()
          -- Try to load mcphub
          local ok, mcphub = pcall(require, "mcphub")
          if ok then
            -- Try to update Avante's system prompt with MCPHub's prompt
            pcall(function()
              local hub = mcphub.get_hub_instance()
              if hub then
                local mcp_prompt = hub:get_active_servers_prompt()
                if mcp_prompt then
                  local avante = require("avante")
                  if avante.config and avante.config.override then
                    avante.config.override({ system_prompt = mcp_prompt })
                  end
                end
              end
            end)
            
            -- Try to add MCPHub extension
            pcall(function()
              -- Load the Avante extension
              mcphub.load_extension("avante")
              
              -- Add MCPHub tools to Avante
              local ok_ext, mcphub_ext = pcall(require, "mcphub.extensions.avante")
              if ok_ext and mcphub_ext and mcphub_ext.mcp_tool then
                local avante = require("avante")
                if avante.config and avante.config.override then
                  avante.config.override({ 
                    custom_tools = { mcphub_ext.mcp_tool() }
                  })
                end
              end
            end)
            
            -- The integration is now complete and quiet - no notifications
          end
        end, 300)
      end
    })

    -- Load avante support module first to get provider models
    local avante_support = require("neotex.plugins.ai.util.avante-support")

    -- Get provider models and update global state
    -- This makes models available throughout the configuration
    local provider_models = avante_support.get_provider_models()

    -- Initialize state with the settings from our support module
    -- This sets up _G.avante_cycle_state and returns the settings
    local settings = avante_support.init()

    -- Add additional autocmd to enforce model after fully loaded
    -- No notification here - will show when window is first opened
    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyDone",
      callback = function()
        vim.defer_fn(function()
          local ok, avante = pcall(require, "avante")
          if ok then
            -- Load settings from our support module
            -- Using the avante_support variable from the outer scope
            local lazy_settings = avante_support.init()

            -- Create model config from settings
            local model_config = lazy_settings

            -- First try: config.override
            local success = pcall(function()
              if avante.config and avante.config.override then
                avante.config.override(model_config)
                return true
              end
            end)

            -- Second try: direct override
            if not success then
              success = pcall(function()
                if type(avante.override) == "function" then
                  avante.override(model_config)
                  return true
                end
              end)
            end

            -- Third try: require config module
            if not success then
              pcall(function()
                local config_module = require("avante.config")
                if config_module and config_module.override then
                  config_module.override(model_config)
                end
              end)
            end

            -- Set a flag to show notification on first window open
            _G.avante_first_open = true
          end
        end, 1000) -- Longer delay to ensure everything is loaded
      end
    })

    -- Add VimEnter event to enforce model configuration without disrupting UI settings
    -- No notification here to keep the interface clean
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        vim.defer_fn(function()
          local ok, avante = pcall(require, "avante")
          if ok then
            -- Load settings from our support module
            -- Using the avante_support variable from the outer scope
            local vim_settings = avante_support.init()

            -- Create model config from settings
            local model_config = vim_settings

            -- Try different paths to update configuration
            local success = false

            -- First try: config.override
            success = pcall(function()
              if avante.config and avante.config.override then
                avante.config.override(model_config)
                return true
              end
            end)

            -- Second try: direct override
            if not success then
              success = pcall(function()
                if type(avante.override) == "function" then
                  avante.override(model_config)
                  return true
                end
              end)
            end

            -- Third try: require config module
            if not success then
              pcall(function()
                local config_module = require("avante.config")
                if config_module and config_module.override then
                  config_module.override(model_config)
                end
              end)
            end
          end
        end, 300) -- Delay after Vim is fully started
      end
    })

    -- Set up Avante commands using the support module
    avante_support.setup_commands()

    -- Create autocmd for Avante buffer-specific mappings
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "AvanteInput", "Avante" },
      callback = function()
        -- Show model notification on first window open in a session
        -- Use local variable to prevent race condition with multiple notifications
        local filetype = vim.bo.filetype
        if _G.avante_first_open and filetype == "Avante" then
          -- Immediately clear the flag to prevent multiple notifications
          _G.avante_first_open = false

          vim.defer_fn(function()
            -- Use support module to show the notification
            -- Using the avante_support variable from the outer scope
            avante_support.show_model_notification()
          end, 100)
        end

        -- Set up buffer keymaps using the function in keymaps.lua
        -- This centralizes all keymappings in one place
        _G.set_avante_keymaps()

        vim.opt_local.scrolloff = 999
      end
    })
  end,
  opts = function()
    -- Default configuration
    local config = {
      -- Gemini configuration
      provider = "gemini",
      model = "gemini-2.5-pro-preview-03-25",
      -- Claude configuration
      -- provider = "claude",
      -- model = "claude-3-5-sonnet-20241022",
      -- endpoint = "https://api.anthropic.com",
      -- Claude configuration
      -- provider = "claude",
      -- endpoint = "https://api.anthropic.com",
      -- model = "claude-3-5-sonnet-20241022",
      -- Removed force_model which isn't supported
      temperature = 0.1, -- Slight increase for more creative responses
      max_tokens = 4096,
      top_p = 0.95,      -- Add top_p for better response quality
      top_k = 40,        -- Add top_k for better response filtering
      timeout = 60000,   -- Increase timeout for complex queries
      auto_suggestions_provider = "claude",
      -- Explicitly set model in provider config for priority
      claude = {
        model = "claude-3-5-sonnet-20241022",
        temperature = 0.1,
        max_tokens = 4096,
        top_p = 0.95,
        timeout = 60000,
      },
      -- OpenAI configuration
      openai = {
        api_key = os.getenv("OPENAI_API_KEY"),
        model = "gpt-4o",
        temperature = 0.1,
        max_tokens = 4096,
        top_p = 0.95,
        timeout = 60000,
      },
      -- Gemini configuration
      gemini = {
        model = "gemini-2.5-pro-preview-03-25",
        temperature = 0.1,
        max_tokens = 8192,
      },

      -- The system_prompt type supports both a string and a function that returns a string
      -- Here we use a simple string prompt first, and MCPHub integration happens later
      -- This prevents MCPHub from loading at startup
      system_prompt = "You are an expert mathematician, logician and computer scientist with deep knowledge of Neovim, Lua, and programming languages. Provide concise, accurate responses with code examples when appropriate. For mathematical content, use clear notation and step-by-step explanations. Use the memory tool to store and retrieve information as needed.",

      -- The custom_tools type supports both a list and a function that returns a list
      -- We'll use an empty array first, then MCPHub tools get added later when needed
      -- This prevents MCPHub from being required at startup
      custom_tools = {},

      -- Disable all tools that could modify the system
      disable_tools = {
        "file_creation",
        "git_operations",
        "system_commands",
        "file_modifications",
      },

      dual_boost = {
        enabled = false,
        first_provider = "claude",
        second_provider = "openai",
        prompt =
        "Based on the two reference outputs below, generate a response that incorporates elements from both but reflects your own judgment and unique perspective. Do not provide any explanation, just give the response directly. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]",
        timeout = 60000,
      },
      fallback = {
        enabled = false,                      -- Enable fallback model if primary fails
        model = "claude-3-5-sonnet-20241022", -- More stable fallback model
        auto_retry = false,
      },
      behaviour = {
        enable_claude_text_editor_tool_mode = true,
        enable_cursor_planning_mode = false,    -- Experimental feature for more focused cursor-based planning
        auto_suggestions = false,
        auto_suggestions_respect_ignore = true, -- Honor .gitignore when searching for context
        auto_set_highlight_group = false,
        auto_set_keymaps = false,
        auto_apply_diff_after_generation = false,
        support_paste_from_clipboard = true,
        minimize_diff = true,
        preserve_state = true,                   -- Add safe mode to handle potential iteration errors
        require_confirmation_for_actions = true, -- Require confirmation for any actions
        disable_file_creation = true,            -- Prevent automatic file creation
        disable_git_operations = true,           -- Prevent automatic git operations
        respect_enter_key = true,                -- Add this to make <CR> behave normally in insert mode
        use_cwd_as_project_root = false,         -- Use current working directory as project root
      },

      -- Token counting configuration (helps track token usage)
      token_counting = {
        enabled = true,              -- Enable token counting for cost awareness
        show_in_status_line = false, -- Don't show in status line to keep it clean
      },
      mappings = {
        diff = {
          ours = "o",       -- Accept our version
          theirs = "t",     -- Accept their version
          all_theirs = "a", -- Accept all their changes
          both = "b",       -- Keep both versions
          cursor = "c",     -- Accept at cursor
          next = "<C-j>",   -- Go to next difference
          prev = "<C-k>",   -- Go to previous difference
          quit = "q",       -- Close diff view
          help = "?",       -- Show help
        },
        suggestion = {
          accept = "<C-l>",  -- Accept current suggestion
          next = "<C-j>",    -- Next suggestion
          prev = "<C-k>",    -- Previous suggestion
          dismiss = "<C-h>", -- Dismiss suggestion
          preview = "p",     -- Preview suggestion
        },
        jump = {
          next = "n", -- Jump to next match
          prev = "N", -- Jump to previous match
        },
        submit = {
          normal = "<CR>",  -- Submit in normal mode
          insert = "<C-l>", -- Submit in insert mode (avoid conflicts with <CR>)
        },
        sidebar = {
          apply_all = "A",                    -- Apply all changes
          apply_cursor = "a",                 -- Apply change at cursor
          switch_windows = "<Tab>",           -- Switch to next window
          reverse_switch_windows = "<S-Tab>", -- Switch to previous window
          toggle = "s",                       -- Toggle sidebar
          focus = "f",                        -- Focus sidebar
        },
      },
      hints = { enabled = false },
      windows = {
        position = "right", -- the position of the sidebar (right|left|top|bottom)
        wrap = true,        -- wrap long lines
        width = 45,         -- optimal width for readability while preserving screen space
        sidebar_header = {
          enabled = false,  -- enable header for better visual hierarchy
          align = "center", -- centered header for balanced look
          rounded = true,   -- rounded corners for modern UI
        },
        input = {
          prefix = "󰭹 ", -- keeping your custom prefix
          height = 10, -- comfortable input height
          border = "rounded", -- consistent rounded borders
          start_insert = true, -- automatically enter insert mode in input window
        },
        edit = {
          border = "rounded",
          start_insert = true, -- automatically enter insert mode in edit window
        },
        ask = {
          floating = true,         -- floating window for better focus
          start_insert = true,     -- automatically enter insert mode
          border = "rounded",
          focus_on_apply = "ours", -- focus on our changes after applying
        },
      },
      -- Adding highlight configurations for better visual distinction
      highlights = {
        diff = {
          current = "DiffText",
          incoming = "DiffAdd",
        },
        sidebar = {
          header = "Title",      -- make header more prominent
          selected = "PmenuSel", -- highlight selected items
          separator = "Comment", -- subtle separator color
        },
      },
      diff = {
        autojump = true,
        list_opener = "copen",
        override_timeoutlen = 500,
        inline_preview = true,   -- Enable inline preview of changes
        gutter_markers = true,   -- Show markers in the gutter for changes
        enhanced_display = true, -- Use enhanced display features
      },
    }

    -- Override with saved settings if they exist
    -- Note: Using new variable names to avoid confusion with the init function scope
    local opts_support = require("neotex.plugins.ai.util.avante-support")
    local opts_settings = opts_support.init()

    -- Apply settings to config
    if opts_settings then
      for k, v in pairs(opts_settings) do
        if type(v) == "table" then
          if config[k] then
            for sk, sv in pairs(v) do
              config[k][sk] = sv
            end
          else
            config[k] = v
          end
        else
          config[k] = v
        end
      end
    end

    return config
  end,
  build = "make",
  dependencies = {
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "hrsh7th/nvim-cmp",
    "nvim-tree/nvim-web-devicons",
    -- MCPHub is loaded on-demand, not as a direct dependency
    -- "ravitemer/mcphub.nvim",
    {
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          use_absolute_path = true,
        },
      },
    },
    {
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}

