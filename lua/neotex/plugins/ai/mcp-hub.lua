------------------------------------------------------------------------
-- MCP-Hub Integration Plugin
------------------------------------------------------------------------
-- This module provides integration with MCP-Hub for AI tools and extensions
-- It serves as a bridge between various AI services and NeoVim
--
-- Features:
-- 1. MCP-Hub connection management
-- 2. Extension configuration for Avante and other AI tools
-- 3. Cross-platform compatibility using UV package manager
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
  -- Use the bundled binary approach for compatibility with NixOS
  -- This installs MCP-Hub locally within the plugin directory
  -- See specs/BUNDLED.md for details on how this works with NixOS
  build = function()
    -- Use bundled_build.lua with proper error handling
    local script_path = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim/bundled_build.lua")
    if vim.fn.filereadable(script_path) == 1 then
      local ok, err = pcall(function()
        dofile(script_path)
      end)
      
      if not ok then
        vim.notify("Failed to run bundled_build.lua: " .. tostring(err), vim.log.levels.ERROR)
      end
    else
      vim.notify("bundled_build.lua not found", vim.log.levels.ERROR)
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

    -- Diagnostics function for NixOS and bundled binary
    utils.diagnose_nixos = function()
      local output = "MCP-Hub Diagnostics:\n"
      
      -- Check for NixOS
      local is_nixos = vim.fn.filereadable("/etc/NIXOS") == 1 or vim.fn.executable("nix-env") == 1
      output = output .. "- NixOS detected: " .. tostring(is_nixos) .. "\n"
      
      -- Check for Node.js
      local node_version = vim.fn.system("node --version 2>/dev/null"):gsub("\n", "")
      output = output .. "- Node.js version: " .. (node_version ~= "" and node_version or "not found") .. "\n"
      
      -- Check for npm
      local npm_version = vim.fn.system("npm --version 2>/dev/null"):gsub("\n", "")
      output = output .. "- npm version: " .. (npm_version ~= "" and npm_version or "not found") .. "\n"
      
      -- Check for MCP_HUB_PATH (legacy approach)
      local mcp_hub_path = vim.g.mcp_hub_path or os.getenv("MCP_HUB_PATH")
      output = output .. "- MCP_HUB_PATH: " .. tostring(mcp_hub_path or "not set") .. "\n"
      
      -- Check plugin status
      local mcphub_plugin_path = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim")
      output = output .. "- Plugin directory exists: " .. tostring(vim.fn.isdirectory(mcphub_plugin_path) == 1) .. "\n"
      
      -- Check bundled binary path
      local bundled_dir = mcphub_plugin_path .. "/bundled"
      local bundled_binary = bundled_dir .. "/mcp-hub/node_modules/.bin/mcp-hub"
      
      output = output .. "- Bundled dir exists: " .. tostring(vim.fn.isdirectory(bundled_dir) == 1) .. "\n"
      output = output .. "- Bundled binary exists: " .. tostring(vim.fn.filereadable(bundled_binary) == 1) .. "\n"
      
      if vim.fn.filereadable(bundled_binary) == 1 then
        output = output .. "- Bundled binary executable: " .. tostring(vim.fn.executable(bundled_binary) == 1) .. "\n"
        
        -- Check binary permissions
        local permissions = vim.fn.system("ls -l " .. bundled_binary):gsub("\n", "")
        output = output .. "- Binary permissions: " .. permissions .. "\n"
      end
      
      -- Check if server is running
      output = output .. "- Server running: " .. tostring(_G.mcp_hub_state and _G.mcp_hub_state.running or "false") .. "\n"
      
      -- Check if we have an error message
      if _G.mcp_hub_state and _G.mcp_hub_state.last_error then
        output = output .. "- Last error: " .. _G.mcp_hub_state.last_error .. "\n"
      end
      
      vim.notify(output, vim.log.levels.INFO)
    end

    -- Register user commands
    vim.api.nvim_create_user_command("MCPHubStatus", function()
      utils.check_status()
    end, { desc = "Check MCP-Hub connection status" })

    vim.api.nvim_create_user_command("MCPHubSettings", function()
      utils.show_settings_editor()
    end, { desc = "Edit MCP-Hub settings" })
    
    vim.api.nvim_create_user_command("MCPHubDiagnose", function()
      utils.diagnose_nixos()
    end, { desc = "Run diagnostics for MCP-Hub" })
    
    vim.api.nvim_create_user_command("MCPHubInstallManual", function()
      -- This command provides a simpler direct installation method for NixOS users
      -- It bypasses the build script and directly uses npm in the bundled directory
      
      local plugin_dir = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim")
      local bundled_dir = plugin_dir .. "/bundled"
      local mcp_hub_dir = bundled_dir .. "/mcp-hub"
      
      -- Create directories
      vim.fn.mkdir(bundled_dir, "p")
      vim.fn.mkdir(mcp_hub_dir, "p")
      
      -- Check write permissions
      local test_file = mcp_hub_dir .. "/test_write"
      local test_handle = io.open(test_file, "w")
      if not test_handle then
        vim.notify("No write permissions in " .. mcp_hub_dir, vim.log.levels.ERROR)
        return
      end
      test_handle:write("test")
      test_handle:close()
      os.remove(test_file)
      
      -- Create package.json
      local pkg_json = [[
{
  "name": "mcp-hub-bundled",
  "version": "1.0.0",
  "description": "Bundled MCP-Hub for NeoVim",
  "private": true,
  "dependencies": {
    "mcp-hub": "latest"
  }
}
]]
      local pkg_file = io.open(mcp_hub_dir .. "/package.json", "w")
      if pkg_file then
        pkg_file:write(pkg_json)
        pkg_file:close()
        vim.notify("Created package.json", vim.log.levels.INFO)
      else
        vim.notify("Failed to create package.json", vim.log.levels.ERROR)
        return
      end
      
      -- Create .npmrc for NixOS
      local npmrc = [[
prefix=${PWD}/.npm
cache=${PWD}/.npm-cache
tmp=${PWD}/.npm-tmp
]]
      local npmrc_file = io.open(mcp_hub_dir .. "/.npmrc", "w")
      if npmrc_file then
        npmrc_file:write(npmrc)
        npmrc_file:close()
        vim.notify("Created .npmrc for NixOS", vim.log.levels.INFO)
      end
      
      -- Create cache directories
      vim.fn.mkdir(mcp_hub_dir .. "/.npm", "p")
      vim.fn.mkdir(mcp_hub_dir .. "/.npm-cache", "p")
      vim.fn.mkdir(mcp_hub_dir .. "/.npm-tmp", "p")
      
      -- Run npm install
      vim.notify("Installing mcp-hub...", vim.log.levels.INFO)
      local npm_cmd = "cd " .. mcp_hub_dir .. " && npm install --no-global --prefix=" .. mcp_hub_dir .. " 2>&1"
      local npm_result = vim.fn.system(npm_cmd)
      vim.notify("npm install result: " .. npm_result, vim.log.levels.INFO)
      
      -- Check if binary was created
      local binary_path = mcp_hub_dir .. "/node_modules/.bin/mcp-hub"
      if vim.fn.filereadable(binary_path) == 1 then
        vim.fn.system("chmod +x " .. binary_path)
        vim.notify("Successfully installed mcp-hub binary at: " .. binary_path, vim.log.levels.INFO)
        
        -- Run diagnostics
        vim.defer_fn(function()
          utils.diagnose_nixos()
        end, 500)
      else
        -- Try to find it in a different location
        local find_result = vim.fn.system("find " .. mcp_hub_dir .. " -name mcp-hub -type f 2>/dev/null"):gsub("\n", "")
        if find_result ~= "" then
          vim.notify("Found binary at: " .. find_result, vim.log.levels.INFO)
          vim.fn.system("chmod +x " .. find_result)
          vim.notify("Made binary executable: " .. find_result, vim.log.levels.INFO)
        else
          vim.notify("Failed to install mcp-hub binary", vim.log.levels.ERROR)
          vim.notify("You may need to set MCP_HUB_PATH to a manually installed binary location", vim.log.levels.INFO)
        end
      end
    end, { desc = "Manually install MCP-Hub binary (alternative method for NixOS)" })
    
    vim.api.nvim_create_user_command("MCPHubRebuild", function()
      -- Path to the build script
      local plugin_dir = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim")
      local build_script = plugin_dir .. "/bundled_build.lua"
      
      if vim.fn.filereadable(build_script) == 1 then
        vim.notify("Rebuilding MCP-Hub bundled binary...", vim.log.levels.INFO)
        
        -- Debug output for NixOS
        local node_path = vim.fn.system("which node 2>/dev/null"):gsub("\n", "")
        local npm_path = vim.fn.system("which npm 2>/dev/null"):gsub("\n", "")
        
        vim.notify("NixOS detected: " .. tostring(vim.fn.filereadable("/etc/NIXOS") == 1), vim.log.levels.INFO)
        vim.notify("Using Node.js: " .. node_path, vim.log.levels.INFO)
        vim.notify("Using npm: " .. npm_path, vim.log.levels.INFO)
        
        -- Check npm permissions
        if npm_path ~= "" then
          vim.notify("npm global prefix: " .. vim.fn.system("npm config get prefix"):gsub("\n", ""), vim.log.levels.INFO)
          vim.notify("npm permissions: " .. vim.fn.system("ls -la " .. npm_path):gsub("\n", ""), vim.log.levels.INFO)
        end
        
        -- Create bundled directory first to ensure permissions
        local bundled_dir = plugin_dir .. "/bundled"
        if vim.fn.isdirectory(bundled_dir) == 0 then
          vim.fn.mkdir(bundled_dir, "p")
          vim.notify("Created bundled directory: " .. bundled_dir, vim.log.levels.INFO)
        end
        
        local mcp_hub_dir = bundled_dir .. "/mcp-hub"
        if vim.fn.isdirectory(mcp_hub_dir) == 0 then
          vim.fn.mkdir(mcp_hub_dir, "p")
          vim.notify("Created mcp-hub directory: " .. mcp_hub_dir, vim.log.levels.INFO)
        end
        
        -- Check that the directory was created
        if vim.fn.isdirectory(mcp_hub_dir) ~= 1 then
          vim.notify("Failed to create directory: " .. mcp_hub_dir, vim.log.levels.ERROR)
          return
        end
        
        -- Test write permissions in the mcp-hub directory
        local test_file = mcp_hub_dir .. "/test_write"
        local test_handle = io.open(test_file, "w")
        if test_handle then
          test_handle:write("test")
          test_handle:close()
          os.remove(test_file)
          vim.notify("Write permissions verified in " .. mcp_hub_dir, vim.log.levels.INFO)
        else
          vim.notify("No write permissions in " .. mcp_hub_dir, vim.log.levels.ERROR)
          return
        end
        
        local ok, err = pcall(function()
          -- Execute the build script in a safer way with more debugging
          local script_content = vim.fn.readfile(build_script)
          local fn, compile_err = loadstring(table.concat(script_content, "\n"))
          
          if compile_err then
            error("Failed to compile script: " .. compile_err)
          end
          
          -- Execute it with error handling
          local env = {
            vim = vim,
            print = print,
            error = error,
            dofile = dofile,
            os = os,
            io = io,
            table = table,
            string = string,
            debug = debug,
            coroutine = coroutine,
            pcall = pcall,
            loadstring = loadstring,
            unpack = unpack,
            tostring = tostring,
            type = type,
          }
          
          setfenv(fn, env)
          fn()
          
          -- Check if the directory and binary were created
          local binary_path = mcp_hub_dir .. "/node_modules/.bin/mcp-hub"
          
          vim.notify("Checking directory: " .. bundled_dir, vim.log.levels.INFO)
          vim.notify("Directory exists: " .. tostring(vim.fn.isdirectory(bundled_dir) == 1), vim.log.levels.INFO)
          
          vim.notify("Checking MCP-Hub dir: " .. mcp_hub_dir, vim.log.levels.INFO)
          vim.notify("MCP-Hub dir exists: " .. tostring(vim.fn.isdirectory(mcp_hub_dir) == 1), vim.log.levels.INFO)
          
          if vim.fn.isdirectory(mcp_hub_dir) == 1 then
            vim.notify("Contents of mcp-hub dir: " .. vim.fn.system("ls -la " .. mcp_hub_dir), vim.log.levels.INFO)
            
            -- Check for package.json
            if vim.fn.filereadable(mcp_hub_dir .. "/package.json") == 1 then
              vim.notify("package.json exists, content:", vim.log.levels.INFO)
              vim.notify(vim.fn.readfile(mcp_hub_dir .. "/package.json"), vim.log.levels.INFO)
            else
              vim.notify("package.json does not exist", vim.log.levels.WARN)
            end
            
            -- Check node_modules directory
            local node_modules = mcp_hub_dir .. "/node_modules"
            if vim.fn.isdirectory(node_modules) == 1 then
              vim.notify("node_modules exists: " .. vim.fn.system("ls -la " .. node_modules), vim.log.levels.INFO)
            else
              vim.notify("node_modules does not exist", vim.log.levels.WARN)
            end
          end
          
          vim.notify("Checking binary: " .. binary_path, vim.log.levels.INFO)
          vim.notify("Binary exists: " .. tostring(vim.fn.filereadable(binary_path) == 1), vim.log.levels.INFO)
          
          if vim.fn.filereadable(binary_path) == 1 then
            vim.notify("Making binary executable", vim.log.levels.INFO)
            vim.fn.system("chmod +x " .. binary_path)
            vim.notify("Binary permissions: " .. vim.fn.system("ls -la " .. binary_path):gsub("\n", ""), vim.log.levels.INFO)
          else
            -- Try to find the binary elsewhere
            vim.notify("Searching for binary in bundled directory...", vim.log.levels.INFO)
            local find_result = vim.fn.system("find " .. bundled_dir .. " -name mcp-hub -type f 2>/dev/null"):gsub("\n", "")
            
            if find_result ~= "" then
              vim.notify("Found binary at: " .. find_result, vim.log.levels.INFO)
              vim.fn.system("chmod +x " .. find_result)
              vim.notify("Made binary executable", vim.log.levels.INFO)
            else
              vim.notify("Binary not found in bundled directory", vim.log.levels.ERROR)
            end
          end
          
          -- Manual installation as fallback for NixOS
          if vim.fn.filereadable("/etc/NIXOS") == 1 and vim.fn.filereadable(binary_path) ~= 1 then
            vim.notify("Trying manual installation for NixOS...", vim.log.levels.INFO)
            
            -- Create package.json if missing
            if vim.fn.filereadable(mcp_hub_dir .. "/package.json") ~= 1 then
              local pkg_json = '{"name":"mcp-hub-bundled","version":"1.0.0","private":true}'
              local file = io.open(mcp_hub_dir .. "/package.json", "w")
              if file then
                file:write(pkg_json)
                file:close()
                vim.notify("Created package.json", vim.log.levels.INFO)
              end
            end
            
            -- Use npm directly in the directory
            local install_result = vim.fn.system("cd " .. mcp_hub_dir .. " && npm install mcp-hub@latest --no-global --prefix=" .. mcp_hub_dir .. " 2>&1")
            vim.notify("Manual npm install result: " .. install_result, vim.log.levels.INFO)
            
            -- Check if binary was created
            if vim.fn.filereadable(binary_path) == 1 then
              vim.fn.system("chmod +x " .. binary_path)
              vim.notify("Successfully created binary through manual installation", vim.log.levels.INFO)
            else
              vim.notify("Manual installation failed to create binary", vim.log.levels.ERROR)
            end
          end
        end)
        
        if ok then
          vim.notify("Successfully rebuilt MCP-Hub bundled binary", vim.log.levels.INFO)
          
          -- Run diagnostics after successful rebuild
          vim.defer_fn(function()
            utils.diagnose_nixos()
          end, 500)
        else
          vim.notify("Failed to rebuild: " .. tostring(err), vim.log.levels.ERROR)
          
          -- Display NPM error information
          vim.notify("NPM executable: " .. npm_path, vim.log.levels.INFO)
          vim.notify("NPM debug info:", vim.log.levels.INFO)
          vim.notify(vim.fn.system("npm config ls -l 2>/dev/null"), vim.log.levels.INFO)
          
          -- Suggest solutions
          vim.notify("Suggestions:", vim.log.levels.INFO)
          vim.notify("1. Try installing mcp-hub globally: npm install -g mcp-hub", vim.log.levels.INFO)
          vim.notify("2. Set MCP_HUB_PATH environment variable to a manually installed binary", vim.log.levels.INFO)
          vim.notify("3. For NixOS, refer to specs/BUNDLED.md for NixOS-specific solutions", vim.log.levels.INFO)
        end
      else
        vim.notify("Build script not found at: " .. build_script, vim.log.levels.ERROR)
      end
    end, { desc = "Manually rebuild the MCP-Hub bundled binary" })

    -- Load settings
    local settings = utils.settings.load()
    
    -- Check if we have a Nix-packaged MCP-Hub binary
    local mcp_hub_path = vim.g.mcp_hub_path or os.getenv("MCP_HUB_PATH")
    
    -- Configure MCP-Hub to use bundled binary for NixOS compatibility
    local setup_config = {
      -- Use the bundled binary approach
      use_bundled_binary = false,
      
      -- Explicitly set the path to our wrapper script
      cmd = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/mcp-hub-wrapper"),
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
      local err_message = "MCP-Hub setup failed: " .. tostring(err)
      vim.notify(err_message, vim.log.levels.ERROR)
      
      -- Check bundled binary path
      local plugin_dir = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim")
      local bundled_binary = plugin_dir .. "/bundled/mcp-hub/node_modules/.bin/mcp-hub"
      
      if vim.fn.filereadable(bundled_binary) == 0 then
        vim.notify("Bundled MCP-Hub binary not found.", vim.log.levels.ERROR)
        vim.notify("Try rebuilding the plugin: :Lazy build mcphub.nvim", vim.log.levels.INFO)
      elseif vim.fn.executable(bundled_binary) == 0 then
        vim.notify("Bundled MCP-Hub binary exists but is not executable. Check permissions.", vim.log.levels.ERROR)
        vim.notify("Try: chmod +x " .. bundled_binary, vim.log.levels.INFO)
      else
        vim.notify("Bundled MCP-Hub binary exists but failed to start. Check Node.js installation.", vim.log.levels.WARN)
      end
      
      vim.notify("For troubleshooting, see specs/BUNDLED.md", vim.log.levels.INFO)
      
      -- Run the diagnose command automatically to help troubleshoot
      vim.defer_fn(function()
        utils.diagnose_nixos()
      end, 500)
      
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
          vim.notify("MCP-Hub successfully integrated with Avante", vim.log.levels.INFO)
        end
      end)
    end
  end,
}

