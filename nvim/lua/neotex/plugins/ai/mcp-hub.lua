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
    "nvim-lua/plenary.nvim",                            -- Required for Job and HTTP requests
  },
  cmd = { "MCPHub", "MCPHubStatus", "MCPHubSettings" }, -- Lazy load by default
  build = function()
    -- Simple build function that checks if uvx is available
    -- and installs mcp-hub for non-NixOS users
    local is_nixos = vim.fn.filereadable("/etc/NIXOS") == 1 or vim.fn.executable("nix-env") == 1
    
    if not is_nixos then
      -- Only try to auto-install for non-NixOS users
      local function run_shell_command(command)
        local handle = io.popen(command .. " 2>&1")
        if not handle then return nil, "Failed to execute command" end
        
        local result = handle:read("*a")
        handle:close()
        return result
      end
      
      -- Check if uvx is available
      local uvx_path = run_shell_command("which uvx"):gsub("\n", "")
      
      if uvx_path ~= "" then
        print("Installing mcp-hub with uvx for non-NixOS system...")
        local install_output = run_shell_command(uvx_path .. " install mcp-hub")
        print(install_output)
      else
        print("Warning: uvx not found. Unable to install mcp-hub.")
        print("Please install uvx first, then run 'uvx install mcp-hub'")
      end
    else
      print("NixOS detected. Please install mcp-hub manually.")
      print("See specs/NIXOS_MCPHUB.md for installation instructions.")
    end
  end,

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

  -- Build function - Choose the right installation method based on environment
  build = function()
    -- Use native shell commands instead of Job for build which may run in FastEvent context
    local function run_shell_command(command)
      local handle = io.popen(command .. " 2>&1")
      if not handle then return nil, "Failed to execute command" end
      
      local result = handle:read("*a")
      handle:close()
      return result
    end
    
    -- Create required configuration directories
    local config_dir = vim.fn.expand("~/.config/mcphub")
    if vim.fn.isdirectory(config_dir) == 0 then
      vim.fn.mkdir(config_dir, "p")
      print("Created MCP-Hub config directory at " .. config_dir)
    end
    
    -- Create a default servers.json if it doesn't exist
    local servers_file = config_dir .. "/servers.json"
    if vim.fn.filereadable(servers_file) == 0 then
      local default_config = [[
{
  "servers": [
    {
      "name": "default",
      "description": "Default MCP Hub server",
      "url": "http://localhost:37373",
      "apiKey": "",
      "default": true
    }
  ]
}
]]
      local file = io.open(servers_file, "w")
      if file then
        file:write(default_config)
        file:close()
        print("Created default servers.json at " .. servers_file)
      end
    end
    
    -- Detect environment
    local is_nixos = vim.fn.filereadable("/etc/NIXOS") == 1
    
    -- Create a file to store build info
    local build_info_file = vim.fn.stdpath("data") .. "/mcp-hub/build_info.lua"
    local build_info = {
      is_nixos = is_nixos,
      npm_installed = false,
      uvx_installed = false,
      use_bundled = false,
      install_method = "unknown"
    }
    
    -- First try to see if npm is available
    local npm_path = run_shell_command("which npm"):gsub("\n", "")
    build_info.npm_installed = npm_path ~= ""
    
    -- Then check if uvx is available
    local uvx_path = run_shell_command("which uvx"):gsub("\n", "")
    build_info.uvx_installed = uvx_path ~= ""
    
    if is_nixos then
      if build_info.uvx_installed then
        -- On NixOS with UVX, use UVX approach but with direct execution
        print("NixOS detected with UVX available. Using UVX for MCP-Hub...")
        
        -- Run bundled_build.lua script to prepare the environment
        local script_path = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim/bundled_build.lua")
        if vim.fn.filereadable(script_path) == 1 then
          -- Even though we'll use UVX to run, still prepare the bundled binary
          -- as a fallback mechanism
          dofile(script_path)
          print("Successfully prepared bundled binary as fallback")
        end
        
        build_info.install_method = "nixos_uvx"
        build_info.use_bundled = false
      else
        -- On NixOS without UVX, use the bundled binary
        print("NixOS detected without UVX. Using bundled binary for MCP-Hub...")
        
        -- Run bundled_build.lua script to prepare the environment
        local script_path = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim/bundled_build.lua")
        if vim.fn.filereadable(script_path) == 1 then
          dofile(script_path)
          print("Successfully prepared bundled binary")
        else
          print("Warning: Could not find bundled_build.lua script")
        end
        
        build_info.install_method = "nixos_bundled"
        build_info.use_bundled = true
      end
    else
      if build_info.npm_installed then
        -- Non-NixOS with npm, use the recommended npm install method
        print("Standard environment with npm. Using npm to install MCP-Hub...")
        local install_output = run_shell_command("npm install -g mcp-hub@latest")
        print(install_output)
        
        build_info.install_method = "npm_global"
        build_info.use_bundled = false
      else
        -- Non-NixOS without npm, use the bundled binary
        print("Standard environment without npm. Using bundled binary for MCP-Hub...")
        
        -- Run bundled_build.lua script to prepare the environment
        local script_path = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim/bundled_build.lua")
        if vim.fn.filereadable(script_path) == 1 then
          dofile(script_path)
          print("Successfully prepared bundled binary")
        else
          print("Warning: Could not find bundled_build.lua script")
        end
        
        build_info.install_method = "standard_bundled"
        build_info.use_bundled = true
      end
    end
    
    -- Save build info for config function to use
    local file = io.open(build_info_file, "w")
    if file then
      file:write("return " .. vim.inspect(build_info) .. "\n")
      file:close()
    end
    
    print("MCP-Hub build configuration complete. Installation method: " .. build_info.install_method)
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
        { key = "port",         name = "Port",               default = settings.port,         type = "number" },
        { key = "config_path",  name = "Config File Path",   default = settings.config_path,  type = "string" },
        { key = "auto_approve", name = "Auto Approve Tools", default = settings.auto_approve, type = "boolean" },
        { key = "debug",        name = "Debug Mode",         default = settings.debug,        type = "boolean" },
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

    -- Load settings
    local settings = utils.settings.load()
    
    -- Get the path to uvx for running MCP-Hub
    local uvx_path = vim.fn.system("which uvx"):gsub("\n", "")
    
    -- Configure MCP-Hub to use UVX
    local setup_config = {
      -- Don't use the bundled binary
      use_bundled_binary = false,
      
      -- Use UVX to run MCP-Hub
      cmd = uvx_path,
      cmdArgs = { "run", "mcp-hub" },
      
      -- Server configuration with fallbacks
      port = settings.port or 37373,
      config = settings.config_path or vim.fn.expand("~/.config/mcphub/servers.json"),
      native_servers = {},
      auto_approve = settings.auto_approve or false,
      
      -- Add error handling
      debug = true, -- Enable debug mode for better error messages

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

      debug = settings.debug or true,
    }
    
    -- Try to set up MCP-Hub with proper error handling
    local setup_ok, err = pcall(function()
      require("mcphub").setup(setup_config)
    end)
    
    if not setup_ok then
      vim.notify("MCP-Hub setup failed: " .. tostring(err), vim.log.levels.ERROR)
      -- Store error in global state
      if _G.mcp_hub_state then
        _G.mcp_hub_state.last_error = "Setup failed: " .. tostring(err)
      end
    else
      -- Initialize integration with Avante if MCP-Hub setup succeeds
      pcall(function()
        local integration = require("neotex.plugins.ai.util.mcp-avante-integration")
        if integration and integration.init then
          integration.init()
        end
      end)
    end
  end,
}

