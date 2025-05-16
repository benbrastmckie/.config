-- lua/neotex/util/mcp_server.lua

local M = {}

-- Single source of truth for server state
M.state = {
  loaded = false,   -- Plugin is loaded
  running = false,  -- Server is running
  ready = false,    -- Server is ready for use
  error = nil       -- Last error message
}

-- Configure logging levels based on debug setting
local function log(message, level)
  level = level or vim.log.levels.INFO
  vim.notify("[MCPHub] " .. message, level)
end

-- Check if we're on NixOS
local function is_nixos()
  return vim.fn.filereadable("/etc/NIXOS") == 1 or vim.fn.executable("nix-env") == 1
end

-- Find the executable to use for MCPHub
local function find_executable()
  -- Cache the executable path to avoid repeated file system checks
  if M._cached_exe_path then
    -- Verify the cached path is still valid
    if vim.fn.filereadable(M._cached_exe_path) == 1 and vim.fn.executable(M._cached_exe_path) == 1 then
      return M._cached_exe_path
    end
  end
  
  -- Check multiple possible locations
  local locations = {
    -- 1. Environment variable
    os.getenv("MCP_HUB_PATH"),
    
    -- 2. NixOS wrapper script
    vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/mcp-hub-wrapper"),
    
    -- 3. Bundled binary direct path
    vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/node_modules/.bin/mcp-hub"),
    
    -- 4. Bundled binary through node
    vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/node_modules/mcp-hub/dist/cli.js"),
    
    -- 5. Global binary (non-NixOS)
    vim.fn.exepath("mcp-hub")
  }
  
  for _, path in ipairs(locations) do
    if path and vim.fn.filereadable(path) == 1 then
      -- For symlinks or files that might not have executable bit
      vim.fn.system("chmod +x " .. vim.fn.shellescape(path))
      
      -- For JS files, create a node runner
      if path:match("%.js$") then
        -- We need to run with node
        local node_path = vim.fn.exepath("node")
        if node_path and node_path ~= "" then
          M._cached_exe_path = node_path .. " " .. path
          return M._cached_exe_path
        end
      else
        -- For binary files
        M._cached_exe_path = path
        return path
      end
    end
  end
  
  -- As a last resort, try building it
  local plugin_dir = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim")
  if vim.fn.isdirectory(plugin_dir) == 1 then
    -- Silently try to build without logging
    vim.fn.system("cd " .. plugin_dir .. " && npm install")
    
    -- Check if it worked
    local bundled_binary = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/node_modules/.bin/mcp-hub")
    if vim.fn.filereadable(bundled_binary) == 1 then
      vim.fn.system("chmod +x " .. bundled_binary)
      M._cached_exe_path = bundled_binary
      return bundled_binary
    end
  end
  
  return nil
end

-- Check if MCPHub server is running by testing connection
function M.check_status()
  -- Try to connect to the server
  local port = 37373 -- Default port
  local result = vim.fn.system("curl -s -o /dev/null -w '%{http_code}' http://localhost:" .. port .. "/version")
  
  -- Update state based on connection test
  local connected = tonumber(result) >= 200 and tonumber(result) < 400
  M.state.ready = connected
  
  return connected
end

-- Ensure MCPHub is loaded
function M.load()
  -- If already loaded, return immediately
  if M.state.loaded then
    return true
  end
  
  -- First check if we can require directly
  local ok, mcphub = pcall(require, "mcphub")
  if ok then
    M.state.loaded = true
    return true
  end
  
  -- Try to load using packpath
  local mcphub_path = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim")
  if vim.fn.isdirectory(mcphub_path) == 1 then
    -- The plugin is installed, let's load it directly
    vim.cmd("packadd mcphub.nvim")
    
    -- Now try to require it again
    ok, mcphub = pcall(require, "mcphub")
    if ok then
      M.state.loaded = true
      return true
    end
  end
  
  -- Create a flag to prevent infinite recursive calls
  if _G._mcp_loading then
    M.state.error = "MCPHub plugin not found or could not be loaded"
    log("MCPHub plugin not found or could not be loaded", vim.log.levels.ERROR)
    return false
  end
  
  -- Try triggering the event and loading sequence once
  _G._mcp_loading = true
  
  -- Trigger the event
  pcall(function()
    vim.api.nvim_exec_autocmds("User", { pattern = "AvantePreLoad" })
  end)
  
  -- Use vim.schedule to let the event handlers run
  vim.schedule(function()
    -- Then try the direct Lazy command
    pcall(function()
      vim.cmd([[Lazy load mcphub.nvim]])
    end)
    
    -- Clear the flag
    _G._mcp_loading = nil
  end)
  
  -- One more try
  ok, mcphub = pcall(require, "mcphub")
  if ok then
    M.state.loaded = true
    return true
  end
  
  -- We couldn't load it
  M.state.error = "Failed to load MCPHub plugin"
  log("MCPHub plugin could not be loaded", vim.log.levels.ERROR)
  return false
end

-- Start the MCPHub server
function M.start()
  -- First check if server is already running
  if M.check_status() then
    M.state.running = true
    M.state.ready = true
    return true
  end
  
  -- Skip if already marked as running (might be starting up)
  if M.state.running then
    return true
  end
  
  -- Mark as running to prevent multiple starts
  M.state.running = true
  
  -- Find the executable
  local exe_path = find_executable()
  
  if not exe_path then
    M.state.error = "MCPHub executable not found"
    M.state.running = false
    -- Silent error - don't log
    return false
  end
  
  -- Start the server
  local job_id
  
  -- Check if this is a node.js script
  if type(exe_path) == "string" and exe_path:match("^/usr/bin/node ") then
    -- Parse the command into executable and args
    local node_exe, js_path = exe_path:match("^(%S+)%s+(.+)$")
    
    job_id = vim.fn.jobstart({node_exe, js_path}, {
      detach = true,
      on_exit = function(id, code)
        if code ~= 0 then
          M.state.error = "Server exited with code " .. code
          M.state.running = false
          -- Silent error
        end
      end
    })
  else
    -- Standard executable 
    job_id = vim.fn.jobstart(exe_path, {
      detach = true,
      on_exit = function(id, code)
        if code ~= 0 then
          M.state.error = "Server exited with code " .. code
          M.state.running = false
          -- Silent error
        end
      end
    })
  end
  
  if job_id <= 0 then
    M.state.error = "Failed to start server job"
    M.state.running = false
    return false
  end
  
  -- Don't log server started message
  
  -- Verify the server is actually running after a delay
  -- Use multiple checks with increasing delays to account for slow startup
  local check_attempts = 0
  local max_attempts = 5
  local check_interval = 500 -- ms
  
  local function check_server_status()
    check_attempts = check_attempts + 1
    local is_ready = M.check_status()
    
    if is_ready then
      -- Server is ready
      M.state.ready = true
      log("MCPHub server ready", vim.log.levels.INFO)
    else
      -- Not ready yet, try again if we haven't exceeded max attempts
      if check_attempts < max_attempts then
        vim.defer_fn(check_server_status, check_interval)
      else
        -- Give up after max attempts but don't show a message
        M.state.error = "Server did not initialize properly"
      end
    end
  end
  
  -- Start the first check after a short delay
  vim.defer_fn(check_server_status, check_interval)
  
  return true
end

-- Get MCPHub instance (or nil if not available)
function M.get_instance()
  if not M.state.loaded then
    return nil
  end
  
  local ok, mcphub = pcall(require, "mcphub")
  if not ok then
    return nil
  end
  
  return mcphub.get_hub_instance()
end

-- Display status information
function M.show_status()
  local status = {
    "MCPHub Status:",
    "- Plugin loaded: " .. tostring(M.state.loaded),
    "- Server running: " .. tostring(M.state.running),
    "- Server ready: " .. tostring(M.state.ready)
  }
  
  if M.state.error then
    table.insert(status, "- Last error: " .. M.state.error)
  end
  
  log(table.concat(status, "\n"), vim.log.levels.INFO)
end

-- Register user commands
function M.setup_commands()
  -- First unregister any existing commands to avoid conflicts
  pcall(vim.api.nvim_del_user_command, "MCPHubStatus")
  pcall(vim.api.nvim_del_user_command, "MCPHubStart")
  
  -- MCPHub status command
  vim.api.nvim_create_user_command("MCPHubStatus", function()
    M.show_status()
  end, { desc = "Show MCPHub status" })
  
  -- MCPHub start command
  vim.api.nvim_create_user_command("MCPHubStart", function()
    -- Ensure plugin is loaded
    if not M.load() then
      log("Failed to load MCPHub plugin", vim.log.levels.ERROR)
      return
    end
    
    -- Start the server
    M.start()
  end, { desc = "Start MCPHub server" })
  
  -- Also create a trigger for AvantePreLoad and a wrapper for MCPHub command
  vim.api.nvim_create_user_command("MCPAvanteTrigger", function()
    -- Trigger the event to load MCPHub
    vim.api.nvim_exec_autocmds("User", { pattern = "AvantePreLoad" })
    log("Triggered AvantePreLoad event", vim.log.levels.INFO)
  end, { desc = "Trigger AvantePreLoad event to load MCPHub" })
  
  -- Create a proxy command for the original MCPHub command
  pcall(vim.api.nvim_del_user_command, "MCPHub")
  vim.api.nvim_create_user_command("MCPHub", function(opts)
    -- First trigger the event to load MCPHub
    vim.api.nvim_exec_autocmds("User", { pattern = "AvantePreLoad" })
    
    -- Then make sure MCPHub is loaded
    if not M.load() then
      log("Failed to load MCPHub plugin, cannot open interface", vim.log.levels.ERROR)
      return
    end
    
    -- If it's loaded, we can safely open the UI
    local ok, err = pcall(function()
      -- Get the state object from mcphub
      local mcphub = require('mcphub')
      local state = mcphub.get_state()
      
      -- Check if we have a UI instance
      if state and state.ui_instance then
        -- Use the toggle method on the UI instance
        state.ui_instance:toggle()
      else
        -- The UI instance isn't ready, try to load MCPHub again
        vim.cmd([[MCPHubStart]])
        
        -- Try again with a delay
        vim.defer_fn(function()
          local mcphub2 = require('mcphub')
          local state2 = mcphub2.get_state()
          
          if state2 and state2.ui_instance then
            state2.ui_instance:toggle()
          else
            -- Fall back to the standard command
            vim.cmd("MCPHub")
          end
        end, 200)
      end
    end)
    
    if not ok then
      log("Failed to open MCPHub interface: " .. tostring(err), vim.log.levels.ERROR)
    end
  end, { desc = "Open MCPHub interface", nargs = "*" })
end

return M