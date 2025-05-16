-- Utility module for ensuring MCPHub is loaded and functional
-- To be used by Avante AI integration functions

local M = {}

-- Function to check if MCPHub server is running by testing the port
function M.is_server_running()
  -- Default MCP port is 37373
  local port = 37373
  
  -- Use curl to check if the server is responding
  local result = vim.fn.system("curl -s -o /dev/null -w '%{http_code}' http://localhost:" .. port .. "/version")
  
  -- If we get a 2xx or 3xx response, the server is running
  return tonumber(result) >= 200 and tonumber(result) < 400
end

-- Function to directly start the MCPHub server
function M.start_mcphub_server()
  -- First check if the server is already running by testing the connection
  if M.is_server_running() then
    vim.notify("MCPHub server is already running", vim.log.levels.INFO)
    _G.mcphub_server_started = true
    return true
  end
  
  -- Skip if server startup flag is set (even if not actually running yet)
  if _G.mcphub_server_started then
    return true
  end
  
  -- Set flag to prevent multiple starts
  _G.mcphub_server_started = true
  
  -- Start the server directly by finding and executing the binary
  local plugin_dir = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim")
  local wrapper_script = plugin_dir .. "/bundled/mcp-hub/mcp-hub-wrapper"
  local bundled_binary = plugin_dir .. "/bundled/mcp-hub/node_modules/.bin/mcp-hub"
  
  local started = false
  
  -- First try the wrapper script for NixOS users
  if vim.fn.filereadable(wrapper_script) == 1 and vim.fn.executable(wrapper_script) == 1 then
    -- Start MCPHub using the wrapper script
    local job_id = vim.fn.jobstart(wrapper_script, {
      detach = true,
      on_exit = function(id, code)
        if code ~= 0 then
          vim.notify("MCPHub server failed to start (exit code: " .. code .. ")", vim.log.levels.ERROR)
          _G.mcphub_server_started = false
        else
          -- Wait a moment and verify the server is actually running
          vim.defer_fn(function()
            if not M.is_server_running() then
              vim.notify("MCPHub server failed to initialize correctly", vim.log.levels.ERROR)
              _G.mcphub_server_started = false
            end
          end, 1000)
        end
      end
    })
    
    started = job_id > 0
    if started then
      vim.notify("Started MCPHub server using NixOS wrapper script", vim.log.levels.INFO)
    end
  -- Then try the bundled binary
  elseif vim.fn.filereadable(bundled_binary) == 1 then
    -- Start MCPHub in the background 
    local job_id = vim.fn.jobstart(bundled_binary, {
      detach = true,
      on_exit = function(id, code)
        if code ~= 0 then
          vim.notify("MCPHub server failed to start (exit code: " .. code .. ")", vim.log.levels.ERROR)
          _G.mcphub_server_started = false
        else
          -- Wait a moment and verify the server is actually running
          vim.defer_fn(function()
            if not M.is_server_running() then
              vim.notify("MCPHub server failed to initialize correctly", vim.log.levels.ERROR)
              _G.mcphub_server_started = false
            end
          end, 1000)
        end
      end
    })
    
    started = job_id > 0
    if started then
      vim.notify("Started MCPHub server from bundled binary", vim.log.levels.INFO)
    end
  else
    -- Reset flag if we couldn't start the server
    _G.mcphub_server_started = false
    vim.notify("Could not find MCPHub binary. Try running :Lazy build mcphub.nvim", vim.log.levels.ERROR)
  end
  
  return started
end

-- Function that loads MCPHub and prepares it for Avante
function M.load_and_run_mcphub_for_avante(avante_command)
  -- Always ensure MCPHub is loaded first
  _G.ensure_mcphub_loaded()
  
  -- Check if server is actually running by testing connection
  local server_running = M.is_server_running()
  
  if not server_running then
    -- If not running, start it directly
    if not _G.mcphub_server_started then
      M.start_mcphub_server()
    else
      -- If flag was set but server not running, reset flag and try again
      _G.mcphub_server_started = false
      M.start_mcphub_server()
    end
    
    -- Give the server time to initialize (longer than before)
    vim.defer_fn(function()
      -- Verify server is running before continuing
      if M.is_server_running() then
        -- Run the Avante command
        vim.cmd(avante_command)
      else
        -- Let the user know there's a problem but run Avante anyway
        vim.notify("MCPHub server did not initialize properly, but continuing with Avante", vim.log.levels.WARN)
        vim.cmd(avante_command)
      end
    end, 1000) -- Much longer delay to ensure server has time to start
  else
    -- Server is already running, run Avante immediately
    vim.cmd(avante_command)
  end
end

return M