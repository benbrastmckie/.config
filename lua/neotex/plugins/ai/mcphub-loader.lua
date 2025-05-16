------------------------------------------------------------------------
-- MCP-Hub Loader Plugin
------------------------------------------------------------------------
-- This is a special plugin that only loads MCP-Hub on demand
-- It's designed to completely isolate MCP-Hub from regular startup
-- and only load it when explicitly requested via commands or events

return {
  -- Custom plugin that handles MCPHub loading
  "ravitemer/mcphub.nvim",
  name = "mcphub.nvim", -- Must match directory name for Lazy to find it
  -- Required dependencies
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  -- Make this plugin completely lazy and isolated 
  lazy = true,
  cond = false, -- Never load at startup no matter what
  -- Only load when explicitly commanded
  cmd = { "MCPHub", "MCPHubStatus", "MCPHubSettings" },
  -- Also load on the special event for Avante integration
  -- Use the standard Lazy event format for User events
  event = "User AvantePreLoad",
  -- No keys, no modules, no auto-loading
  keys = false,
  
  -- Use the bundled binary approach for compatibility with NixOS
  -- This installs MCP-Hub locally within the plugin directory
  -- See specs/BUNDLED.md for details on how this works with NixOS
  build = function()
    -- Use native shell commands instead of Job for build which may run in FastEvent context
    local function run_shell_command(command)
      local handle = io.popen(command .. " 2>&1")
      if not handle then return nil, "Failed to execute command" end
      
      local result = handle:read("*a")
      handle:close()
      return result
    end
    
    -- NixOS Auto-installation - Run this first before any other build steps
    -- This ensures the binary is available when the plugin is configured
    local is_nixos = vim.fn.filereadable("/etc/NIXOS") == 1 or vim.fn.executable("nix-env") == 1
    
    if is_nixos then
      -- Flag file to track if we've already run the installation
      local install_flag_file = vim.fn.stdpath("data") .. "/mcp-hub/nixos_installed"
      local mcp_data_dir = vim.fn.stdpath("data") .. "/mcp-hub"
      
      -- Create directory if needed
      if vim.fn.isdirectory(mcp_data_dir) == 0 then
        vim.fn.mkdir(mcp_data_dir, "p")
      end
      
      -- Check if we need to install
      local should_install = false
      if vim.fn.filereadable(install_flag_file) == 0 then
        should_install = true
      end
      
      -- Also verify the binary exists - even if we have the flag file
      local bundled_binary = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/node_modules/.bin/mcp-hub")
      local wrapper_script = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/mcp-hub-wrapper")
      
      if vim.fn.filereadable(bundled_binary) == 0 or vim.fn.filereadable(wrapper_script) == 0 then
        should_install = true
      end
      
      -- Run installation script if needed
      if should_install then
        local install_script = vim.fn.expand("~/.config/nvim/scripts/mcp-hub-nixos-install.sh")
        
        if vim.fn.filereadable(install_script) == 1 then
          -- Run the installation script synchronously during build
          -- This ensures the binary is available when mcphub.setup() is called
          local result = run_shell_command("bash " .. install_script)
          
          -- Create flag file to prevent future runs
          local file = io.open(install_flag_file, "w")
          if file then
            file:write("Installed on " .. os.date("%Y-%m-%d %H:%M:%S"))
            file:close()
          end
        end
      end
    end
    
    -- Create required configuration directories
    local config_dir = vim.fn.expand("~/.config/mcphub")
    if vim.fn.isdirectory(config_dir) == 0 then
      vim.fn.mkdir(config_dir, "p")
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
        
        -- Run bundled_build.lua script to prepare the environment
        local script_path = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim/bundled_build.lua")
        if vim.fn.filereadable(script_path) == 1 then
          -- Even though we'll use UVX to run, still prepare the bundled binary
          -- as a fallback mechanism
          dofile(script_path)
        end
        
        build_info.install_method = "nixos_uvx"
        build_info.use_bundled = false
      else
        -- On NixOS without UVX, use the bundled binary
        
        -- Run bundled_build.lua script to prepare the environment
        local script_path = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim/bundled_build.lua")
        if vim.fn.filereadable(script_path) == 1 then
          dofile(script_path)
        end
        
        build_info.install_method = "nixos_bundled"
        build_info.use_bundled = true
      end
    else
      if build_info.npm_installed then
        -- Non-NixOS with npm, use the recommended npm install method
        local install_output = run_shell_command("npm install -g mcp-hub@latest")
        
        build_info.install_method = "npm_global"
        build_info.use_bundled = false
      else
        -- Non-NixOS without npm, use the bundled binary
        
        -- Run bundled_build.lua script to prepare the environment
        local script_path = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim/bundled_build.lua")
        if vim.fn.filereadable(script_path) == 1 then
          dofile(script_path)
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
  end,

  -- Main config function to initialize MCPHub when loaded
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

    -- Initialize global state for tracking MCP-Hub status if not already set
    if not _G.mcp_hub_state then
      _G.mcp_hub_state = {
        running = false,
        port = 37373,
        last_error = nil,
        avante_integrated = false
      }
    end

    -- Create MCP data directory if it doesn't exist
    local mcp_data_dir = vim.fn.stdpath("data") .. "/mcp-hub"
    if vim.fn.isdirectory(mcp_data_dir) == 0 then
      vim.fn.mkdir(mcp_data_dir, "p")
    end

    -- Load settings
    local settings = utils.settings.load()
    
    -- Load build_info to determine the appropriate configuration approach
    local build_info_file = vim.fn.stdpath("data") .. "/mcp-hub/build_info.lua"
    local build_info = {
      is_nixos = vim.fn.filereadable("/etc/NIXOS") == 1,
      npm_installed = false,
      uvx_installed = false,
      use_bundled = false,
      install_method = "unknown"
    }

    -- Try to load the build info file if it exists
    if vim.fn.filereadable(build_info_file) == 1 then
      local ok, info = pcall(dofile, build_info_file)
      if ok and info then
        build_info = info
      end
    end

    -- Check if MCP_HUB_PATH is set - this overrides all other methods
    local mcp_hub_path = vim.g.mcp_hub_path or os.getenv("MCP_HUB_PATH")
    
    -- Configure MCP-Hub based on the environment and build info
    local setup_config = {
      -- Use the appropriate binary approach based on the environment
      use_bundled_binary = build_info.use_bundled,
      
      -- Configure cmd based on multiple factors:
      -- 1. If MCP_HUB_PATH is set, use that explicitly
      -- 2. If we're on NixOS, use the wrapper script (verify it exists first)
      -- 3. If bundled approach is being used, set the binary path
      -- 4. For standard users with global installation, don't set cmd (plugin will find it in PATH)
      cmd = mcp_hub_path or 
            (build_info.is_nixos and (function()
              local wrapper_script = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/mcp-hub-wrapper")
              if vim.fn.filereadable(wrapper_script) == 1 then
                return wrapper_script
              else
                return nil  -- Return nil so global binary will be used if available
              end
            end)()) or 
            (build_info.use_bundled and (function()
              local bundled_binary = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/node_modules/.bin/mcp-hub")
              if vim.fn.filereadable(bundled_binary) == 1 then
                return bundled_binary
              else
                return nil  -- Return nil so global binary will be used if available
              end
            end)()),
      cmdArgs = {},
      
      -- Server configuration with fallbacks
      port = settings.port or 37373,
      config = settings.config_path or vim.fn.expand("~/.config/mcphub/servers.json"),
      native_servers = {},
      auto_approve = settings.auto_approve or false,
      
      -- Add error handling
      debug = true, -- Enable debug mode for better error messages

      -- Extensions configuration
      extensions = {
        -- Avante integration following official recommendations
        avante = {
          make_slash_commands = true,     -- Create /slash commands from MCP server prompts
          auto_approve = true,            -- Auto-approve MCP tools for Avante to use
          make_vars = true,               -- Make MCP resources available as chat variables
          show_result_in_chat = true,     -- Show tool results in chat
          -- Default system prompt to include MCP capabilities
          system_prompt = "You have access to MCP tools and resources, which extend your capabilities. Use the tools when appropriate."
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
        
        -- Register integration with Avante when hub is ready
        vim.defer_fn(function()
          -- Try to load Avante extension explicitly
          local ok, mcphub = pcall(require, "mcphub")
          if ok then
            -- Load the Avante extension
            pcall(function()
              mcphub.load_extension("avante")
            end)
          end
          
          -- Set integration state without any notification
          _G.mcp_hub_state.avante_integrated = true
          -- Don't show any notification at all
        end, 500)
      end,

      on_error = function(err)
        _G.mcp_hub_state.running = false
        _G.mcp_hub_state.last_error = err
        _G.mcp_hub_state.avante_integrated = false
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
      -- Only log detailed error at debug level to avoid cluttering the UI
      local err_message = "MCP-Hub setup failed: " .. tostring(err)
      vim.notify(err_message, vim.log.levels.DEBUG)
      
      -- Check bundled binary path
      local plugin_dir = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim")
      local bundled_binary = plugin_dir .. "/bundled/mcp-hub/node_modules/.bin/mcp-hub"
      local wrapper_script = plugin_dir .. "/bundled/mcp-hub/mcp-hub-wrapper"
      
      -- For NixOS users, suggest the installation script if wrapper doesn't exist
      if build_info.is_nixos and vim.fn.filereadable(wrapper_script) == 0 then
        -- Only show this notification - it's the most relevant for NixOS users
        vim.notify("MCP-Hub wrapper script not found for NixOS. Run installer: bash ~/.config/nvim/scripts/mcp-hub-nixos-install.sh", vim.log.levels.WARN)
      elseif vim.fn.filereadable(bundled_binary) == 0 then
        -- Only show this for non-NixOS users or if both binary and wrapper are missing
        vim.notify("MCP-Hub binary not found. Try rebuilding with :Lazy build mcphub.nvim", vim.log.levels.WARN)
      elseif vim.fn.executable(bundled_binary) == 0 then
        vim.notify("MCP-Hub binary not executable. Try: chmod +x " .. bundled_binary, vim.log.levels.WARN)
      end
      
      -- Store error in global state
      if _G.mcp_hub_state then
        _G.mcp_hub_state.last_error = "Setup failed: " .. tostring(err)
      end
    end
  end,
}