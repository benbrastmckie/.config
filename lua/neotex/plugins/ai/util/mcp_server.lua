-- lua/neotex/plugins/ai/util/mcp_server.lua

local M = {}

-- Single source of truth for server state
M.state = {
  loaded = false,   -- Plugin is loaded
  running = false,  -- Server is running
  ready = false,    -- Server is ready for use
  version = "1.0.0", -- Default version to prevent parsing errors
  error = nil       -- Last error message
}

-- Configure logging levels based on debug setting
-- Debug mode configuration
local debug_mode = vim.g.mcphub_debug_mode or false

local function log(message, level)
  level = level or vim.log.levels.INFO
  require('neotex.util.notifications').ai(message, require('neotex.util.notifications').categories.STATUS)
end

-- Debug-only logging function
local function debug_log(message)
  if debug_mode then
    log(message, vim.log.levels.INFO)
  end
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

-- Check if a port is in use
function M.is_port_in_use(port)
  -- Try to bind to the port
  local result = vim.fn.system("lsof -i:" .. port .. " -sTCP:LISTEN")
  return result ~= ""
end

-- Find an available port starting from base
function M.find_available_port(base)
  base = base or 37373
  local max_attempts = 10
  
  for i = 0, max_attempts do
    local port = base + i
    if not M.is_port_in_use(port) then
      return port
    end
  end
  
  -- If we reach here, just return the base port and hope for the best
  return base
end

-- Check if MCPHub server is running by testing connection
function M.check_status(port)
  -- Use provided port or default
  port = port or 37373
  
  -- Try to connect to the server
  local result = vim.fn.system("curl -s -o /dev/null -w '%{http_code}' http://localhost:" .. port .. "/version")
  
  -- Update state based on connection test
  local connected = tonumber(result) >= 200 and tonumber(result) < 400
  
  if connected then
    -- Update state on successful connection
    M.state.ready = true
    M.state.port = port
    
    -- Update the config file to ensure it's properly formatted
    pcall(function()
      local config_dir = vim.fn.expand("~/.config/mcphub")
      local servers_file = config_dir .. "/servers.json"
      
      -- Create fresh config
      local servers_config = {
        mcpServers = {
          {
            name = "default",
            description = "Default MCP Hub server",
            url = "http://localhost:" .. port,
            apiKey = "",
            default = true
          }
        }
      }
      
      -- Make sure the directory exists
      if vim.fn.isdirectory(config_dir) == 0 then
        vim.fn.mkdir(config_dir, "p")
      end
      
      -- Write the config
      local content = vim.json.encode(servers_config)
      vim.fn.writefile({content}, servers_file)
    end)
  else
    M.state.ready = false
  end
  
  return connected
end

-- Ensure MCPHub is loaded with consistent version
function M.load()
  -- Ensure we have a valid version string to prevent parsing errors
  vim.g.mcphub_version = M.get_actual_version()
  
  -- If already loaded, return immediately
  if M.state.loaded then
    return true
  end
  
  -- First check if we can require directly
  local ok, mcphub = pcall(require, "mcphub")
  if ok then
    -- Apply version fix
    M.fix_version()
    
    M.state.loaded = true
    return true
  end
  
  -- Try to load using packpath
  local mcphub_path = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim")
  if vim.fn.isdirectory(mcphub_path) == 1 then
    -- The plugin is installed, try to load it directly with pcall to catch errors
    local packadd_ok = pcall(function()
      vim.cmd("packadd mcphub.nvim")
    end)
    
    if packadd_ok then
      -- Now try to require it again
      ok, mcphub = pcall(require, "mcphub")
      if ok then
        -- Apply version fix
        M.fix_version()
        
        M.state.loaded = true
        return true
      end
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
    
    -- Apply version fix
    vim.defer_fn(function()
      M.fix_version()
    end, 100)
  end)
  
  -- One more try
  ok, mcphub = pcall(require, "mcphub")
  if ok then
    -- Apply version fix
    M.fix_version()
    
    M.state.loaded = true
    return true
  end
  
  -- We couldn't load it
  M.state.error = "Failed to load MCPHub plugin"
  log("MCPHub plugin could not be loaded", vim.log.levels.ERROR)
  return false
end

-- Function to clean up any existing server processes - very thorough to eliminate conflicts
function M.cleanup_existing_processes()
  -- Reset state first to ensure consistent behavior
  M.state.running = false
  M.state.ready = false
  M.state.error = nil
  
  -- Kill any process named mcp-hub - even background ones
  vim.fn.system("pkill -f mcp-hub 2>/dev/null")
  vim.fn.system("pkill -9 -f mcp-hub 2>/dev/null")  -- Force kill any stubborn processes
  
  -- Kill any Node.js process that might be running mcp-hub
  vim.fn.system("pkill -f 'node.*mcp-hub' 2>/dev/null")
  vim.fn.system("pkill -9 -f 'node.*mcp-hub' 2>/dev/null")
  
  -- Kill any process on port 37373
  vim.fn.system("fuser -k -TERM 37373/tcp 2>/dev/null")
  vim.fn.system("fuser -k -KILL 37373/tcp 2>/dev/null")
  
  -- Alternative method to kill processes on the MCP port
  vim.fn.system("lsof -ti:37373 | xargs kill -9 2>/dev/null")
  
  -- Additional sleep to ensure processes are fully terminated and port is free
  vim.cmd("sleep 100m")
  
  -- Log that cleanup was done (debug mode only)
  debug_log("Cleaned up any existing MCP-Hub processes")
end

-- Start the MCPHub server with proper version handling
function M.start()
  -- Ensure we have a valid version string to prevent version format errors
  vim.g.mcphub_version = M.get_actual_version()
  
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
  
  -- Clean up any existing server processes
  M.cleanup_existing_processes()
  
  -- Find an available port
  local port = M.find_available_port(37373)
  M.state.port = port
  
  -- Find the executable
  local exe_path = find_executable()
  
  if not exe_path then
    M.state.error = "MCPHub executable not found"
    M.state.running = false
    -- Silent error - don't log
    return false
  end
  
  -- Start the server with output handling to prevent version parsing issues
  local job_id
  
  -- Common job options to suppress output that would trigger version parsing
  local job_opts = {
    detach = true,
    -- Suppress standard output to prevent version parsing issues 
    on_stdout = function(_, data) 
      -- Optionally parse for useful information but don't return it
      -- This prevents the version parser from seeing output
      
      -- Log startup completion for debugging
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line:match("Server listening on") then
            vim.schedule(function()
              log("Server startup complete", vim.log.levels.DEBUG)
            end)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      -- Only log actual errors, not startup messages
      if data and #data > 0 and data[1] ~= "" then
        local error_msg = table.concat(data, "\n"):match("Error:.*")
        if error_msg then
          vim.schedule(function()
            log("Error from server: " .. error_msg, vim.log.levels.ERROR)
          end)
        end
      end
    end,
    on_exit = function(id, code)
      if code ~= 0 then
        M.state.error = "Server exited with code " .. code
        M.state.running = false
        -- Silent error
      end
    end
  }
  
  -- Prepare command with explicit port
  local cmd
  if type(exe_path) == "string" and exe_path:match("^/usr/bin/node ") then
    -- Parse the command into executable and args
    local node_exe, js_path = exe_path:match("^(%S+)%s+(.+)$")
    cmd = {node_exe, js_path, "serve", "--port=" .. port}
  else
    -- Standard executable with port argument
    cmd = {exe_path, "serve", "--port=" .. port}
  end
  
  -- Start the server
  job_id = vim.fn.jobstart(cmd, job_opts)
  
  if job_id <= 0 then
    M.state.error = "Failed to start server job"
    M.state.running = false
    return false
  end
  
  -- Save job ID for potential cleanup
  M.state.job_id = job_id
  log("MCP-Hub server starting on port " .. port, vim.log.levels.INFO)
  
  -- Verify the server is actually running after a delay
  -- Use multiple checks with increasing delays to account for slow startup
  local check_attempts = 0
  local max_attempts = 10 -- Increased for more reliability
  local check_interval = 500 -- ms
  
  local function check_server_status()
    check_attempts = check_attempts + 1
    local is_ready = M.check_status(port)
    
    if is_ready then
      -- Server is ready
      M.state.ready = true
      
      -- Apply version fixes when server is ready
      M.fix_version()
      
      log("MCPHub server ready on port " .. port, vim.log.levels.INFO)
    else
      -- Not ready yet, try again if we haven't exceeded max attempts
      if check_attempts < max_attempts then
        -- Increase the interval for later attempts
        local adjusted_interval = check_interval + (check_attempts * 100)
        vim.defer_fn(check_server_status, adjusted_interval)
      else
        -- Give up after max attempts
        M.state.error = "Server did not initialize properly - SSE connection might have failed"
        log("Server did not initialize properly. Try stopping any existing MCP-Hub processes and restart.", vim.log.levels.ERROR)
      end
    end
  end
  
  -- Start the first check after a delay that increases with each attempt
  vim.defer_fn(check_server_status, check_interval + 500)
  
  return true
end

-- Function to get the actual MCP-Hub version if possible
function M.get_actual_version()
  -- Try to get the actual version from the binary
  local version_string = nil
  
  -- Try to find the executable
  local exe_path = find_executable()
  if exe_path then
    -- Extract version information using --version flag
    local cmd
    if type(exe_path) == "string" and exe_path:match("^/usr/bin/node ") then
      -- Node script
      local node_exe, js_path = exe_path:match("^(%S+)%s+(.+)$")
      cmd = node_exe .. " " .. js_path .. " --version"
    else
      -- Regular binary
      cmd = exe_path .. " --version"
    end
    
    local handle = io.popen(cmd .. " 2>&1")
    if handle then
      local result = handle:read("*a")
      handle:close()
      
      -- Try to extract a version number
      local version = result:match("(%d+%.%d+%.%d+)")
      if version then
        version_string = version
      end
    end
  end
  
  -- If we couldn't get the version, use a fallback
  if not version_string then
    -- Check if we can get it from config
    local ok, mcphub = pcall(require, "mcphub")
    if ok and mcphub._version then
      version_string = mcphub._version
    elseif ok and mcphub.version then
      version_string = mcphub.version
    else
      -- Ultimate fallback - semantic version
      version_string = "0.1.0"
    end
  end
  
  return version_string
end

-- Function to fix version issues in all relevant places
function M.fix_version()
  -- Get actual version if possible
  local version = M.get_actual_version()
  
  -- Set version in our state
  M.state.version = version
  
  -- Set global variable
  vim.g.mcphub_version = version
  
  -- Try to patch the loaded instance
  pcall(function()
    local mcphub = require("mcphub")
    
    -- Fix version in config if possible
    if mcphub._config then
      mcphub._config.version_override = version
    end
    
    -- Fix version in hub instance if available
    pcall(function()
      local hub = mcphub.get_hub_instance()
      if hub then
        hub.version = version
      end
    end)
  end)
end

-- Function to restart server - useful when having connection issues
function M.restart_server()
  -- Clean up existing processes
  M.cleanup_existing_processes()
  
  -- Reset state
  M.state.running = false
  M.state.ready = false
  
  -- Create fresh config file
  local config_dir = vim.fn.expand("~/.config/mcphub")
  if vim.fn.isdirectory(config_dir) == 0 then
    vim.fn.mkdir(config_dir, "p")
  end
  
  local servers_file = config_dir .. "/servers.json"
  local servers_config = {
    mcpServers = {
      {
        name = "default",
        description = "Default MCP Hub server",
        url = "http://localhost:37373",
        apiKey = "",
        default = true
      }
    }
  }
  
  -- Always overwrite the config file
  local file = io.open(servers_file, "w")
  if file then
    file:write(vim.json.encode(servers_config))
    file:close()
  end
  
  -- Check if we're on NixOS
  local is_nixos = vim.fn.filereadable("/etc/NIXOS") == 1 or vim.fn.executable("nix-env") == 1
  
  -- Start server with appropriate command
  if is_nixos then
    -- Use NixOS command directly
    pcall(vim.cmd, "MCPNix")
  else
    -- Use our start function
    M.start()
  end
  
  -- Fix version
  M.fix_version()
  
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
  pcall(vim.api.nvim_del_user_command, "MCPHubRestart")
  
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
  
  -- Add restart command for easy recovery
  vim.api.nvim_create_user_command("MCPHubRestart", function()
    M.restart_server()
  end, { desc = "Restart MCPHub server by killing existing ones" })
  
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
    pcall(function() 
      vim.api.nvim_exec_autocmds("User", { pattern = "AvantePreLoad" })
    end)
    
    -- Give some time for the event to process
    vim.cmd("sleep 10m")
    
    -- Then try to ensure MCPHub is loaded
    local load_success = M.load()
    
    if not load_success then
      -- Try direct Lazy load as a fallback
      pcall(function()
        vim.cmd([[Lazy load mcphub.nvim]])
      end)
      
      -- Try loading again
      load_success = M.load()
      
      if not load_success then
        log("Failed to load MCPHub plugin, cannot open interface", vim.log.levels.ERROR)
        return
      end
    end
    
    -- If it's loaded, we can safely open the UI
    local ok, err = pcall(function()
      -- Get the state object from mcphub
      local mcphub = require('mcphub')
      local state = pcall(function() return mcphub.get_state() end) and mcphub.get_state() or nil
      local hub_instance = pcall(function() return mcphub.get_hub_instance() end) and mcphub.get_hub_instance() or nil
      
      -- Option 1: Check if we have a UI instance directly
      if state and state.ui_instance then
        -- Use the toggle method on the UI instance
        pcall(function() state.ui_instance:toggle() end)
        return
      end
      
      -- Option 2: Try via hub_instance
      if hub_instance and hub_instance.ui and hub_instance.ui.toggle then
        pcall(function() hub_instance.ui.toggle() end)
        return
      end
      
      -- Option 3: Try via api
      if mcphub.api and mcphub.api.show_ui then
        pcall(function() mcphub.api.show_ui() end)
        return
      end
      
      -- Option 4: The UI instance isn't ready, try to start the server first
      pcall(function() vim.cmd([[MCPHubStart]]) end)
      
      -- Give the server some time to start
      vim.defer_fn(function()
        -- Try all options again
        pcall(function()
          local mcphub2 = require('mcphub')
          local state2 = pcall(function() return mcphub2.get_state() end) and mcphub2.get_state() or nil
          local hub_instance2 = pcall(function() return mcphub2.get_hub_instance() end) and mcphub2.get_hub_instance() or nil
          
          if state2 and state2.ui_instance then
            state2.ui_instance:toggle()
          elseif hub_instance2 and hub_instance2.ui and hub_instance2.ui.toggle then
            hub_instance2.ui:toggle()
          elseif mcphub2.api and mcphub2.api.show_ui then
            mcphub2.api.show_ui()
          else
            log("MCPHub plugin loaded but UI not available", vim.log.levels.WARN)
          end
        end)
      end, 500)
    end)
    
    if not ok and err then
      log("Failed to open MCPHub interface: " .. tostring(err), vim.log.levels.ERROR)
    end
  end, { desc = "Open MCPHub interface", nargs = "*" })
end

return M