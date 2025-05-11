------------------------------------------------------------------------
-- MCP-Hub Integration Plugin
------------------------------------------------------------------------
-- This module provides integration with MCP-Hub for AI tools and extensions
-- It serves as a bridge between various AI services and NeoVim
--
-- Features:
-- 1. MCP-Hub connection management
-- 2. Extension configuration for Avante and other AI tools
-- 3. NixOS compatibility with uvx
-- 4. Persistent settings between sessions
--
-- Commands:
-- - :MCPHub          - Launch the MCP-Hub interface
-- - :MCPHubStatus    - Check connection status
-- - :MCPHubSettings  - Open settings configuration
--
-- See: https://github.com/ravitemer/mcphub.nvim

return {
  "ravitemer/mcphub.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for Job and HTTP requests
  },
  cmd = { "MCPHub", "MCPHubStatus", "MCPHubSettings" }, -- Lazy load by default
  
  -- Initialize settings files and global state
  init = function()
    -- Create MCP data directory if it doesn't exist
    local mcp_data_dir = vim.fn.stdpath("data") .. "/mcp-hub"
    if vim.fn.isdirectory(mcp_data_dir) == 0 then
      vim.fn.mkdir(mcp_data_dir, "p")
    end
    
    -- Initialize global state for tracking MCP-Hub status
    if not _G.mcp_hub_state then
      _G.mcp_hub_state = {
        running = false,
        port = 37373,
        last_error = nil,
        avante_integrated = false
      }
    end
  end,
  
  -- Build function - Install MCP-Hub with uvx
  build = function()
    -- Notify user we're checking installation
    vim.notify("Checking mcp-hub installation with uvx...", vim.log.levels.INFO)
    
    -- Check if uvx is available
    local uvx_job = require("plenary.job"):new({
      command = "which",
      args = { "uvx" },
      on_exit = function(j, uvx_code)
        if uvx_code ~= 0 then
          vim.notify("uvx is not available in PATH. MCP-Hub requires uvx for NixOS compatibility.", vim.log.levels.ERROR)
          return
        end
        
        -- Check if mcp-hub is already installed with uvx
        require("plenary.job"):new({
          command = "uvx",
          args = { "list" },
          on_exit = function(j, list_code)
            if list_code == 0 then
              local output = table.concat(j:result(), "\n")
              
              if not string.find(output, "mcp%-hub") then
                -- Install mcp-hub if not found
                vim.notify("Installing mcp-hub with uvx...", vim.log.levels.INFO)
                require("plenary.job"):new({
                  command = "uvx",
                  args = { "install", "mcp-hub" },
                  on_exit = function(install_j, install_code)
                    if install_code == 0 then
                      vim.notify("Successfully installed mcp-hub with uvx", vim.log.levels.INFO)
                    else
                      local error_msg = table.concat(install_j:stderr_result(), "\n")
                      vim.notify("Failed to install mcp-hub with uvx: " .. error_msg, vim.log.levels.ERROR)
                      
                      -- Store error in global state
                      _G.mcp_hub_state.last_error = error_msg
                    end
                  end,
                }):sync()
              else
                vim.notify("mcp-hub is already installed with uvx", vim.log.levels.INFO)
              end
            else
              local error_msg = table.concat(j:stderr_result(), "\n")
              vim.notify("Failed to check uvx packages: " .. error_msg, vim.log.levels.ERROR)
              
              -- Store error in global state
              _G.mcp_hub_state.last_error = error_msg
            end
          end,
        }):sync()
      end,
    }):sync()
  end,
  
  -- Config function - Setup MCP-Hub with improved configuration
  config = function()
    local utils = {}
    
    -- Settings management functions
    utils.settings = {}
    utils.settings.file = vim.fn.stdpath("data") .. "/mcp-hub/settings.lua"
    
    -- Save settings to file
    utils.settings.save = function(settings)
      local settings_content = string.format([[
-- MCP-Hub settings
-- Generated on: %s
return {
  port = %d,
  config_path = %s,
  auto_approve = %s,
  debug = %s,
  log_level = %s
}
]], 
        os.date("%Y-%m-%d %H:%M:%S"),
        settings.port or 37373,
        vim.inspect(settings.config_path or vim.fn.expand("~/.config/mcphub/servers.json")),
        tostring(settings.auto_approve or false),
        tostring(settings.debug or true),
        vim.inspect(settings.log_level or vim.log.levels.WARN)
      )
      
      -- Write settings to file
      local file = io.open(utils.settings.file, "w")
      if file then
        file:write(settings_content)
        file:close()
        return true
      else
        vim.notify("Failed to save MCP-Hub settings", vim.log.levels.ERROR)
        return false
      end
    end
    
    -- Load settings from file
    utils.settings.load = function()
      -- Default settings
      local default_settings = {
        port = 37373,
        config_path = vim.fn.expand("~/.config/mcphub/servers.json"),
        auto_approve = false,
        debug = true,
        log_level = vim.log.levels.WARN
      }
      
      -- Check if settings file exists
      if vim.fn.filereadable(utils.settings.file) == 1 then
        local ok, settings = pcall(dofile, utils.settings.file)
        if ok and settings then
          -- Merge with defaults for any missing values
          for k, v in pairs(default_settings) do
            if settings[k] == nil then
              settings[k] = v
            end
          end
          return settings
        end
      end
      
      -- Create default settings file if it doesn't exist
      utils.settings.save(default_settings)
      return default_settings
    end
    
    -- Show settings editor UI
    utils.show_settings_editor = function()
      local settings = utils.settings.load()
      
      -- Create a table for the prompts in order we want them displayed
      local prompts = {
        { key = "port", name = "Port", default = settings.port, type = "number" },
        { key = "config_path", name = "Config File Path", default = settings.config_path, type = "string" },
        { key = "auto_approve", name = "Auto Approve Tools", default = settings.auto_approve, type = "boolean" },
        { key = "debug", name = "Debug Mode", default = settings.debug, type = "boolean" },
      }
      
      -- Function to handle the next prompt in sequence
      local function show_next_prompt(index, new_settings)
        -- If we've gone through all prompts, save settings
        if index > #prompts then
          if utils.settings.save(new_settings) then
            vim.notify("MCP-Hub settings saved. Restart MCP-Hub to apply.", vim.log.levels.INFO)
          end
          return
        end
        
        local prompt = prompts[index]
        local prompt_text = prompt.name .. ": "
        
        -- Format default based on type
        local default_value
        if prompt.type == "boolean" then
          default_value = prompt.default and "true" or "false"
        else
          default_value = tostring(prompt.default)
        end
        
        vim.ui.input({
          prompt = prompt_text,
          default = default_value,
        }, function(input)
          -- If input is canceled, stop the prompt sequence
          if input == nil then
            vim.notify("Settings update cancelled", vim.log.levels.INFO)
            return
          end
          
          -- Parse input based on type
          if prompt.type == "number" then
            new_settings[prompt.key] = tonumber(input) or prompt.default
          elseif prompt.type == "boolean" then
            new_settings[prompt.key] = (input:lower() == "true")
          else
            new_settings[prompt.key] = input
          end
          
          -- Show the next prompt
          show_next_prompt(index + 1, new_settings)
        end)
      end
      
      -- Start the prompt sequence
      show_next_prompt(1, vim.deepcopy(settings))
    end
    
    -- Status check function
    utils.check_status = function()
      local status = "MCP-Hub Status:\n"
      status = status .. "- Running: " .. tostring(_G.mcp_hub_state.running) .. "\n"
      status = status .. "- Port: " .. tostring(_G.mcp_hub_state.port) .. "\n"
      status = status .. "- Avante Integration: " .. tostring(_G.mcp_hub_state.avante_integrated) .. "\n"
      
      if _G.mcp_hub_state.last_error then
        status = status .. "- Last Error: " .. _G.mcp_hub_state.last_error .. "\n"
      end
      
      vim.notify(status, vim.log.levels.INFO)
    end
    
    -- Register user commands
    vim.api.nvim_create_user_command("MCPHubStatus", function()
      utils.check_status()
    end, { desc = "Check MCP-Hub connection status" })
    
    vim.api.nvim_create_user_command("MCPHubSettings", function()
      utils.show_settings_editor()
    end, { desc = "Edit MCP-Hub settings" })
    
    -- Get the full path to uvx for more reliable execution
    local uvx_path = vim.fn.system("which uvx"):gsub("\n", "")
    
    -- Load settings
    local settings = utils.settings.load()
    
    -- Configure MCP-Hub
    require("mcphub").setup({
      -- Use absolute path to uvx to run mcp-hub
      use_bundled_binary = false,
      cmd = uvx_path,
      cmdArgs = { "run", "mcp-hub" },
      
      -- Server configuration
      port = settings.port,
      config = settings.config_path,
      native_servers = {},
      auto_approve = settings.auto_approve,
      
      -- Extensions configuration
      extensions = {
        avante = {
          -- Options will be populated later when Avante integration is enabled
        },
        codecompanion = {
          show_result_in_chat = false,
          make_vars = true,
        },
      },
      
      -- UI configuration
      ui = {
        window = {
          width = 0.8,
          height = 0.8,
          relative = "editor",
          zindex = 50,
          border = "rounded",
        },
      },
      
      -- Event callbacks
      on_ready = function(hub)
        _G.mcp_hub_state.running = true
        _G.mcp_hub_state.port = settings.port
        vim.notify("MCP-Hub is ready on port " .. settings.port, vim.log.levels.INFO)
      end,
      
      on_error = function(err)
        _G.mcp_hub_state.running = false
        _G.mcp_hub_state.last_error = err
        vim.notify("MCP-Hub error: " .. err, vim.log.levels.ERROR)
      end,
      
      -- Logging configuration
      log = {
        level = settings.log_level,
        to_file = false,
        file_path = nil,
        prefix = "MCPHub"
      },
      
      debug = settings.debug,
    })
  end,
}