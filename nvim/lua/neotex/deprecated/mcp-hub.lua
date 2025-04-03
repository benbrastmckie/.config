return {
  "ravitemer/mcphub.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for Job and HTTP requests
  },
  cmd = "MCPHub",            -- lazy load by default
  build = function()
    -- Ensure mcp-hub is installed with uvx
    vim.notify("Checking mcp-hub installation with uvx...", vim.log.levels.INFO)

    -- First check if mcp-hub is already installed
    local check_job = require("plenary.job"):new({
      command = "uvx",
      args = { "list" },
      on_exit = function(j, return_val)
        if return_val == 0 then
          local output = table.concat(j:result(), "\n")
          if not string.find(output, "mcp%-hub") then
            -- Install mcp-hub if not found
            vim.notify("Installing mcp-hub with uvx...", vim.log.levels.INFO)
            require("plenary.job"):new({
              command = "uvx",
              args = { "install", "mcp-hub" },
              on_exit = function(install_j, install_return_val)
                if install_return_val == 0 then
                  vim.notify("Successfully installed mcp-hub with uvx", vim.log.levels.INFO)
                else
                  vim.notify("Failed to install mcp-hub with uvx: " ..
                    table.concat(install_j:stderr_result(), "\n"), vim.log.levels.ERROR)
                end
              end,
            }):sync()
          else
            vim.notify("mcp-hub is already installed with uvx", vim.log.levels.INFO)
          end
        else
          vim.notify("Failed to check uvx packages: " .. table.concat(j:stderr_result(), "\n"),
            vim.log.levels.ERROR)
        end
      end,
    }):sync()
  end,
  config = function()
    -- Get the full path to uvx
    local uvx_path = vim.fn.system("which uvx"):gsub("\n", "")

    require("mcphub").setup({
      -- Use absolute path to uvx to run mcp-hub
      use_bundled_binary = false,
      cmd = uvx_path,
      cmdArgs = { "run", "mcp-hub" },

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
