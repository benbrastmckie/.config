return {
  "ravitemer/mcphub.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for Job and HTTP requests
  },
  cmd = "MCPHub",            -- lazy load by default
  config = function()
    require("mcphub").setup({
      -- NixOS specific settings
      use_bundled_binary = false, -- Don't use the plugin's bundled binary
      cmd = "uvx",                -- Use uvx directly
      cmdArgs = { "mcp-hub" },    -- Pass mcp-hub as an argument to uvx

      -- Server configuration
      port = 37373,                                            -- Default port for MCP Hub
      config = vim.fn.expand("~/.config/mcphub/servers.json"), -- Absolute path to config file location
      native_servers = {},                                     -- Add your native servers here
      auto_approve = false,                                    -- Auto approve mcp tool calls

      -- Extensions configuration
      extensions = {
        avante = {},
        codecompanion = {
          -- Show the mcp tool result in the chat buffer
          show_result_in_chat = false,
          make_vars = true, -- Make chat #variables from MCP server resources
        },
      },

      -- UI configuration
      ui = {
        window = {
          width = 0.8,  -- 0-1 (ratio); "50%" (percentage); 50 (raw number)
          height = 0.8, -- 0-1 (ratio); "50%" (percentage); 50 (raw number)
          relative = "editor",
          zindex = 50,
          border = "rounded", -- "none", "single", "double", "rounded", "solid", "shadow"
        },
      },

      -- Event callbacks
      on_ready = function(hub)
        -- Called when hub is ready
      end,
      on_error = function(err)
        -- Called on errors
      end,

      -- Logging configuration
      log = {
        level = vim.log.levels.WARN,
        to_file = false,
        file_path = nil,
        prefix = "MCPHub"
      },

      debug = true, -- Keep your existing debug setting
    })
  end,
}
