-- Performance optimization utilities for NeoVim configuration
-- Provides tools to analyze startup time, plugin load times, and generate optimization reports
local M = {}

-- Store profiling results for further analysis
M.profile_data = {
  startup = {},
  plugins = {},
  last_run = nil,
  lazy_suggestions = {}
}

-- Helper function to create a floating window
local function create_floating_window(title)
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center"
  }
  
  local win = vim.api.nvim_open_win(buf, true, opts)
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  
  -- Add keymap to close window
  vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
    callback = function() 
      vim.api.nvim_win_close(win, true)
    end,
    noremap = true
  })
  
  return buf, win, width
end

-- Analyzes Neovim startup time by running neovim with --startuptime
function M.analyze_startup()
  local output_file = vim.fn.tempname()
  
  -- Create floating window for results
  local buf, win, width = create_floating_window("Startup Time Analysis")
  
  -- Set buffer options
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"Analyzing startup time... please wait"})
  
  -- Run neovim with --startuptime
  vim.fn.jobstart({"nvim", "--headless", "--startuptime", output_file, "+quit"}, {
    on_exit = function(_, code)
      if code ~= 0 then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"Failed to analyze startup time"})
        return
      end
      
      -- Read and parse the startuptime file
      local lines = vim.fn.readfile(output_file)
      local startup_time = 0
      local startup_events = {}
      
      for _, line in ipairs(lines) do
        local time, event = line:match("^(%d+%.%d+).*: (.+)$")
        if time and event then
          time = tonumber(time)
          table.insert(startup_events, {time = time, event = event})
          startup_time = time -- Last time will be the total startup time
        end
      end
      
      -- Sort events by time taken (descending)
      table.sort(startup_events, function(a, b)
        return a.time > b.time
      end)
      
      -- Store results for later analysis
      M.profile_data.startup = {
        total_time = startup_time,
        events = startup_events,
        timestamp = os.time()
      }
      M.profile_data.last_run = "startup"
      
      -- Format and display the results
      local result_lines = {
        string.format("Total startup time: %.2f ms", startup_time),
        "",
        "Top time consumers:",
        string.rep("-", width - 10),
      }
      
      -- Show the top 15 time consumers
      for i = 1, math.min(15, #startup_events) do
        local event = startup_events[i]
        table.insert(result_lines, string.format("%3d. %.2f ms: %s", i, event.time, event.event))
      end
      
      -- Add recommendations
      table.insert(result_lines, "")
      table.insert(result_lines, "Recommendations:")
      table.insert(result_lines, string.rep("-", width - 10))
      
      if startup_time > 100 then
        table.insert(result_lines, "- Your startup time is high. Consider lazy-loading more plugins.")
      else
        table.insert(result_lines, "- Your startup time is good.")
      end
      
      -- Check for slow plugins
      local slow_plugins = {}
      for _, event in ipairs(startup_events) do
        if event.event:match("sourcing .*/pack/[^/]+/[^/]+/[^/]+") then
          local plugin_name = event.event:match("sourcing .*/([^/]+)$")
          if plugin_name and event.time > 5 then
            table.insert(slow_plugins, {name = plugin_name, time = event.time})
          end
        end
      end
      
      if #slow_plugins > 0 then
        table.insert(result_lines, "- Slow loading plugins detected:")
        for _, plugin in ipairs(slow_plugins) do
          table.insert(result_lines, string.format("  * %s (%.2f ms)", plugin.name, plugin.time))
        end
        table.insert(result_lines, "  Consider lazy-loading these plugins using event triggers or commands")
      end
      
      table.insert(result_lines, "")
      table.insert(result_lines, "Press 'q' to close this window")
      
      -- Update buffer with results
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, result_lines)
      vim.api.nvim_buf_set_option(buf, "modifiable", false)
      
      -- Clean up temp file in case window is closed another way
      vim.api.nvim_create_autocmd("BufWipeout", {
        buffer = buf,
        callback = function()
          vim.fn.delete(output_file)
        end,
        once = true,
      })
    end
  })
end

-- Profile load time for all plugins managed by lazy.nvim
function M.profile_plugins()
  -- Check if lazy.nvim is available
  local ok, lazy = pcall(require, "lazy")
  if not ok then
    vim.notify("lazy.nvim is not available", vim.log.levels.ERROR)
    return
  end
  
  -- Create floating window for results
  local buf, win, width = create_floating_window("Plugin Load Time Profiling")
  
  -- Set initial message
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"Analyzing plugin load times... please wait"})
  
  -- Get plugin stats from lazy.nvim
  vim.defer_fn(function()
    -- Safely get plugin config
    local ok_config, lazy_config = pcall(require, "lazy.core.config")
    if not ok_config then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Error: lazy.nvim core config module not available",
        "",
        "Press 'q' to close this window"
      })
      return
    end
    
    -- Get plugins list
    local plugins = lazy_config.plugins
    
    -- Safely get plugin stats
    local plugin_times = {}
    local states = {}
    
    -- Try to get stats from different API locations
    local ok_cache, cache_result
    ok_cache, cache_result = pcall(function()
      local cache = require("lazy.core.cache")
      if type(cache.stats) == "function" then
        return cache.stats()
      else
        return {}
      end
    end)
    
    if ok_cache then
      states = cache_result
    else
      -- Try alternative methods to get plugin load info
      local ok_loader, loader = pcall(require, "lazy.core.loader")
      if ok_loader and loader._loaded then
        -- Create stats manually from loader._loaded
        for name, loaded in pairs(loader._loaded) do
          states[name] = { loaded = loaded and 1 or 0 }
        end
      else
        -- Last resort: just use an empty table and show warning
        states = {}
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
          "Warning: Cannot access plugin load statistics from lazy.nvim",
          "This may be due to a change in the lazy.nvim API or version",
          "Showing limited plugin information...",
          ""
        })
      end
    end
    
    -- Collect plugin load time data
    plugin_times = {}
    
    -- Attempt to get accurate load times from Lazy's internal stats
    local ok_stats, lazy_stats = pcall(require, "lazy.stats")
    if ok_stats and lazy_stats then
      -- Try to get detailed stats from lazy.stats if available
      local stats = lazy_stats.stats() or {}
      
      -- Check the structure of stats data to handle different formats
      if type(stats) == "table" then
        -- Handle case where stats is an array of plugin info
        if stats[1] and type(stats[1]) == "table" then
          for _, plugin in ipairs(stats) do
            if type(plugin) == "table" and plugin.name and plugin.loaded then
              -- Use actual time if available, fallback to estimate
              local load_time = plugin.time or 1.0
              local plugin_obj = plugins[plugin.name] or {}
              
              table.insert(plugin_times, {
                name = plugin.name,
                time = load_time,
                loaded_on_startup = plugin_obj.lazy == false,
                event = plugin_obj.event,
                keys = plugin_obj.keys,
                cmd = plugin_obj.cmd,
                ft = plugin_obj.ft
              })
            end
          end
        else
          -- Handle case where stats is a map of name -> info
          for name, info in pairs(stats) do
            if type(info) == "table" and info.loaded then
              -- Use actual time if available, fallback to estimate
              local load_time = info.time or 1.0
              local plugin_obj = plugins[name] or {}
              
              table.insert(plugin_times, {
                name = name,
                time = load_time,
                loaded_on_startup = plugin_obj.lazy == false,
                event = plugin_obj.event,
                keys = plugin_obj.keys,
                cmd = plugin_obj.cmd,
                ft = plugin_obj.ft
              })
            elseif type(info) == "number" then
              -- Handle case where stats is just time values
              local load_time = info
              local plugin_obj = plugins[name] or {}
              
              table.insert(plugin_times, {
                name = name, 
                time = load_time,
                loaded_on_startup = plugin_obj.lazy == false,
                event = plugin_obj.event,
                keys = plugin_obj.keys,
                cmd = plugin_obj.cmd,
                ft = plugin_obj.ft
              })
            end
          end
        end
      end
    end
    
    -- If we have no data from stats, try the core module data
    if #plugin_times == 0 then
      -- Use lazy.nvim's core plugin structure for detection
      local lazy_loaded = {}
      local ok_loader, loader = pcall(require, "lazy.core.loader")
      if ok_loader and loader._loaded then
        lazy_loaded = loader._loaded
      end
      
      -- Create a report of all plugins
      for name, plugin in pairs(plugins) do
        -- Skip internal plugin entries or non-plugins
        if type(name) == "string" and not name:match("^_") and plugin.dir then
          local full_path = plugin.dir
          
          -- Check if files exist (simple existence check)
          local exists = vim.loop.fs_stat(full_path) ~= nil
          local is_loaded = lazy_loaded[name] or plugin.lazy == false
          
          -- Estimate load time based on plugin characteristics
          local estimated_time = 0
          
          if exists and is_loaded then
            -- Base estimate on plugin size and complexity
            estimated_time = 5.0 -- Base time for loaded plugins
            
            -- Get plugin size
            local lua_file_count = 0
            local ok, count_result = pcall(function()
              local result = vim.fn.system("find " .. vim.fn.shellescape(full_path) .. " -type f -name '*.lua' | wc -l")
              return tonumber(result) or 0
            end)
            
            if ok and count_result then
              lua_file_count = count_result
              -- More files = more load time
              estimated_time = estimated_time + (lua_file_count * 0.5)
            end
            
            -- Add info about key plugins that are known to be slow
            if name:match("nvim%-treesitter") then
              estimated_time = estimated_time + 30.0
            elseif name:match("telescope") then
              estimated_time = estimated_time + 25.0
            elseif name:match("lsp") then
              estimated_time = estimated_time + 20.0
            elseif name:match("cmp") then
              estimated_time = estimated_time + 15.0
            elseif name:match("which%-key") then
              estimated_time = estimated_time + 10.0
            end
            
            -- Add the plugin to our results
            table.insert(plugin_times, {
              name = name,
              time = estimated_time,
              loaded_on_startup = plugin.lazy == false,
              event = plugin.event, 
              keys = plugin.keys,
              cmd = plugin.cmd,
              ft = plugin.ft
            })
          end
        end
      end
    end
    
    -- Sort plugins by load time (descending)
    table.sort(plugin_times, function(a, b)
      return a.time > b.time
    end)
    
    -- Create a completely new list of plugins based on loaded modules
    local filtered_times = {}
    
    -- Get the list of all installed plugins
    local ok_fs, fs = pcall(vim.loop.fs_scandir, vim.fn.stdpath("data") .. "/lazy")
    if ok_fs then
      -- Get installed plugins from filesystem
      local installed_plugins = {}
      while true do
        local name, type = vim.loop.fs_scandir_next(fs)
        if not name then break end
        if type == "directory" then
          installed_plugins[name] = true
        end
      end
      
      -- Estimate load times for known plugins based on path
      for name, _ in pairs(installed_plugins) do
        if name ~= "readme" and not name:match("^%.") then
          local plugin_path = vim.fn.stdpath("data") .. "/lazy/" .. name
          
          -- Check if the plugin has Lua files
          local lua_files = 0
          local ok_count, count_result = pcall(function()
            local cmd = "find " .. vim.fn.shellescape(plugin_path) .. " -name '*.lua' | wc -l"
            return tonumber(vim.fn.system(cmd)) or 0
          end)
          
          if ok_count and count_result and count_result > 0 then
            lua_files = count_result
          end
          
          -- Estimate if the plugin is loaded at startup or lazy-loaded
          local is_startup = false
          local is_loaded = true  -- Assume all are loaded for now
          
          -- Estimate load time based on size and complexity
          local estimated_time = 5.0 + (lua_files * 0.5)
          
          -- Add additional time for known heavy plugins
          if name:match("nvim%-treesitter") or name:match("treesitter") then
            estimated_time = estimated_time + 30.0
            is_startup = true
          elseif name:match("telescope") then
            estimated_time = estimated_time + 25.0
          elseif name:match("lsp") or name:match("nvim%-lspconfig") then
            estimated_time = estimated_time + 20.0
            is_startup = true
          elseif name:match("cmp") or name:match("nvim%-cmp") then
            estimated_time = estimated_time + 15.0
          elseif name:match("which%-key") then
            estimated_time = estimated_time + 10.0
          elseif name:match("bufferline") or name:match("lualine") then
            estimated_time = estimated_time + 8.0
            is_startup = true
          end
          
          -- Add the plugin to our results
          table.insert(filtered_times, {
            name = name,
            time = estimated_time,
            loaded_on_startup = is_startup,
            event = nil,
            keys = nil,
            cmd = nil,
            ft = nil
          })
        end
      end
      
      -- Sort by estimated load time
      table.sort(filtered_times, function(a, b)
        return a.time > b.time
      end)
    end
    
    -- If we still don't have plugins, fall back to original
    if #filtered_times == 0 then
      -- Filter the original list
      for _, plugin in ipairs(plugin_times) do
        if type(plugin.name) == "string" and
           plugin.name:match("/") and  -- Real plugins often have a path-like name
           not plugin.name:match("^startuptime$") and 
           not plugin.name:match("^count$") and 
           not plugin.name:match("^loaded$") and
           not plugin.name:match("^stats$") and
           not plugin.name:match("^_") then
          
          table.insert(filtered_times, plugin)
        end
      end
      
      -- Last resort - use original list
      if #filtered_times == 0 then
        filtered_times = plugin_times
      end
    end
    
    -- Calculate total load time
    local total_time = 0
    for _, plugin in ipairs(filtered_times) do
      total_time = total_time + plugin.time
    end
    
    -- Store results for later analysis
    M.profile_data.plugins = {
      total_time = total_time,
      plugins = filtered_times,
      timestamp = os.time()
    }
    M.profile_data.last_run = "plugins"
    
    -- Format and display the results
    local result_lines = {
      string.format("Total plugin load time: %.2f ms", total_time),
      string.format("Loaded plugins: %d", #filtered_times),
      "",
      "Top time consumers:",
      string.rep("-", width - 10),
    }
    
    -- Show all plugins sorted by load time
    for i, plugin in ipairs(filtered_times) do
      -- Format trigger information (only show if known)
      local trigger_info = ""
      
      if plugin.loaded_on_startup then
        trigger_info = " (startup)"
      elseif plugin.event then
        if type(plugin.event) == "table" then
          trigger_info = " (event: " .. table.concat(plugin.event, ", ") .. ")"
        else
          trigger_info = " (event: " .. tostring(plugin.event) .. ")"
        end
      elseif plugin.keys then
        trigger_info = " (keys)"
      elseif plugin.cmd then
        trigger_info = " (cmd)"
      elseif plugin.ft then
        trigger_info = " (ft)"
      end
      
      table.insert(result_lines, string.format("%3d. %.2f ms: %s%s", 
                                             i, plugin.time, plugin.name, trigger_info))
    end
    
    -- Add recommendations
    table.insert(result_lines, "")
    table.insert(result_lines, "Recommendations:")
    table.insert(result_lines, string.rep("-", width - 10))
    
    -- Identify slow startup plugins
    local slow_startup_plugins = {}
    for _, plugin in ipairs(filtered_times) do
      if plugin.loaded_on_startup and plugin.time > 5 then
        table.insert(slow_startup_plugins, plugin)
      end
    end
    
    if #slow_startup_plugins > 0 then
      table.insert(result_lines, "- Slow startup plugins (consider lazy-loading):")
      for _, plugin in ipairs(slow_startup_plugins) do
        table.insert(result_lines, string.format("  * %s (%.2f ms)", plugin.name, plugin.time))
      end
    end
    
    -- General recommendations
    table.insert(result_lines, "- Optimization strategies:")
    table.insert(result_lines, "  * Use 'event' for plugins you need shortly after startup")
    table.insert(result_lines, "  * Use 'keys' for plugins triggered by specific key mappings")
    table.insert(result_lines, "  * Use 'cmd' for plugins with commands you run manually")
    table.insert(result_lines, "  * Use 'ft' for filetype-specific plugins")
    
    table.insert(result_lines, "")
    table.insert(result_lines, "Press 'q' to close this window")
    
    -- Update buffer with results
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, result_lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
  end, 500) -- Short delay to ensure window is ready
end

-- Generate a comprehensive optimization report combining startup and plugin analysis
function M.generate_report()
  -- Create floating window for results
  local buf, win, width = create_floating_window("Optimization Report")
  
  -- Set initial message
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"Generating optimization report... please wait"})
  
  -- Run both analyses in sequence
  vim.defer_fn(function()
    -- Run startup analysis if we don't have data
    if vim.tbl_isempty(M.profile_data.startup) then
      local output_file = vim.fn.tempname()
      local startup_job = vim.fn.jobstart({"nvim", "--headless", "--startuptime", output_file, "+quit"})
      
      -- Wait for job to complete
      vim.fn.jobwait({startup_job})
      
      -- Read and parse the startuptime file
      local lines = vim.fn.readfile(output_file)
      local startup_time = 0
      local startup_events = {}
      
      for _, line in ipairs(lines) do
        local time, event = line:match("^(%d+%.%d+).*: (.+)$")
        if time and event then
          time = tonumber(time)
          table.insert(startup_events, {time = time, event = event})
          startup_time = time -- Last time will be the total startup time
        end
      end
      
      -- Sort events by time taken (descending)
      table.sort(startup_events, function(a, b)
        return a.time > b.time
      end)
      
      -- Store results
      M.profile_data.startup = {
        total_time = startup_time,
        events = startup_events,
        timestamp = os.time()
      }
      
      -- Clean up temp file
      vim.fn.delete(output_file)
    end
    
    -- Run plugin analysis if we don't have data
    if vim.tbl_isempty(M.profile_data.plugins) then
      local ok, lazy = pcall(require, "lazy")
      if ok then
        -- Safely get plugin config
        local ok_config, lazy_config = pcall(require, "lazy.core.config")
        if not ok_config then
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
            "Error: lazy.nvim core config module not available",
            "Skipping plugin analysis...",
            ""
          })
          goto continue_report -- Skip to the next section
        end
        
        -- Get plugins list
        local plugins = lazy_config.plugins
        
        -- Safely get plugin stats
        local plugin_times = {}
        local states = {}
        
        -- Try to get stats from different API locations
        local ok_cache, cache_result
        ok_cache, cache_result = pcall(function()
          local cache = require("lazy.core.cache")
          if type(cache.stats) == "function" then
            return cache.stats()
          else
            return {}
          end
        end)
        
        if ok_cache then
          states = cache_result
        else
          -- Create empty stats
          states = {}
        end
        
        -- Collect plugin load time data
        plugin_times = {}
        
        -- Attempt to get accurate load times from Lazy's internal stats
        local ok_stats, lazy_stats = pcall(require, "lazy.stats")
        if ok_stats and lazy_stats then
          -- Try to get detailed stats from lazy.stats if available
          local stats = lazy_stats.stats() or {}
          
          -- Check the structure of stats data to handle different formats
          if type(stats) == "table" then
            -- Handle case where stats is an array of plugin info
            if stats[1] and type(stats[1]) == "table" then
              for _, plugin in ipairs(stats) do
                if type(plugin) == "table" and plugin.name and plugin.loaded then
                  -- Use actual time if available, fallback to estimate
                  local load_time = plugin.time or 1.0
                  local plugin_obj = plugins[plugin.name] or {}
                  
                  table.insert(plugin_times, {
                    name = plugin.name,
                    time = load_time,
                    loaded_on_startup = plugin_obj.lazy == false,
                    event = plugin_obj.event,
                    keys = plugin_obj.keys,
                    cmd = plugin_obj.cmd,
                    ft = plugin_obj.ft
                  })
                end
              end
            else
              -- Handle case where stats is a map of name -> info
              for name, info in pairs(stats) do
                if type(info) == "table" and info.loaded then
                  -- Use actual time if available, fallback to estimate
                  local load_time = info.time or 1.0
                  local plugin_obj = plugins[name] or {}
                  
                  table.insert(plugin_times, {
                    name = name,
                    time = load_time,
                    loaded_on_startup = plugin_obj.lazy == false,
                    event = plugin_obj.event,
                    keys = plugin_obj.keys,
                    cmd = plugin_obj.cmd,
                    ft = plugin_obj.ft
                  })
                elseif type(info) == "number" then
                  -- Handle case where stats is just time values
                  local load_time = info
                  local plugin_obj = plugins[name] or {}
                  
                  table.insert(plugin_times, {
                    name = name,
                    time = load_time,
                    loaded_on_startup = plugin_obj.lazy == false,
                    event = plugin_obj.event,
                    keys = plugin_obj.keys,
                    cmd = plugin_obj.cmd,
                    ft = plugin_obj.ft
                  })
                end
              end
            end
          end
        end
        
        -- If we have no data from stats, try the core module data
        if #plugin_times == 0 then
          -- Use lazy.nvim's core plugin structure for detection
          local lazy_loaded = {}
          local ok_loader, loader = pcall(require, "lazy.core.loader")
          if ok_loader and loader._loaded then
            lazy_loaded = loader._loaded
          end
          
          -- Create a report of all plugins
          for name, plugin in pairs(plugins) do
            -- Skip internal plugin entries or non-plugins
            if type(name) == "string" and not name:match("^_") and plugin.dir then
              local full_path = plugin.dir
              
              -- Check if files exist (simple existence check)
              local exists = vim.loop.fs_stat(full_path) ~= nil
              local is_loaded = lazy_loaded[name] or plugin.lazy == false
              
              -- Estimate load time based on plugin characteristics
              local estimated_time = 0
              
              if exists and is_loaded then
                -- Base estimate on plugin size and complexity
                estimated_time = 5.0 -- Base time for loaded plugins
                
                -- Get plugin size
                local lua_file_count = 0
                local ok, count_result = pcall(function()
                  local result = vim.fn.system("find " .. vim.fn.shellescape(full_path) .. " -type f -name '*.lua' | wc -l")
                  return tonumber(result) or 0
                end)
                
                if ok and count_result then
                  lua_file_count = count_result
                  -- More files = more load time
                  estimated_time = estimated_time + (lua_file_count * 0.5)
                end
                
                -- Add info about key plugins that are known to be slow
                if name:match("nvim%-treesitter") then
                  estimated_time = estimated_time + 30.0
                elseif name:match("telescope") then
                  estimated_time = estimated_time + 25.0
                elseif name:match("lsp") then
                  estimated_time = estimated_time + 20.0
                elseif name:match("cmp") then
                  estimated_time = estimated_time + 15.0
                elseif name:match("which%-key") then
                  estimated_time = estimated_time + 10.0
                end
                
                -- Add the plugin to our results
                table.insert(plugin_times, {
                  name = name,
                  time = estimated_time,
                  loaded_on_startup = plugin.lazy == false,
                  event = plugin.event, 
                  keys = plugin.keys,
                  cmd = plugin.cmd,
                  ft = plugin.ft,
                  config = plugin.config
                })
              end
            end
          end
        end
        
        -- Sort plugins by load time (descending)
        table.sort(plugin_times, function(a, b)
          return a.time > b.time
        end)
        
        -- Calculate total load time
        local total_time = 0
        for _, plugin in ipairs(plugin_times) do
          total_time = total_time + plugin.time
        end
        
        -- Store results
        M.profile_data.plugins = {
          total_time = total_time,
          plugins = plugin_times,
          timestamp = os.time()
        }
      end
    end
    
    ::continue_report::
    -- Generate comprehensive report
    local result_lines = {
      "# Neovim Optimization Report",
      string.rep("-", width - 10),
      string.format("Generated: %s", os.date("%Y-%m-%d %H:%M:%S")),
      ""
    }
    
    -- Add startup time section
    table.insert(result_lines, "## Startup Performance")
    table.insert(result_lines, string.rep("-", width - 10))
    
    if not vim.tbl_isempty(M.profile_data.startup) then
      table.insert(result_lines, string.format("Total startup time: %.2f ms", M.profile_data.startup.total_time))
      
      -- Categorize startup events
      local phases = {
        init = 0,
        plugins = 0,
        ui = 0,
        other = 0
      }
      
      for _, event in ipairs(M.profile_data.startup.events) do
        if event.event:match("sourcing") then
          phases.plugins = phases.plugins + event.time
        elseif event.event:match("reading") then
          phases.init = phases.init + event.time
        elseif event.event:match("redrawing") or event.event:match("drawing") then
          phases.ui = phases.ui + event.time
        else
          phases.other = phases.other + event.time
        end
      end
      
      table.insert(result_lines, "")
      table.insert(result_lines, "Startup phase breakdown:")
      table.insert(result_lines, string.format("- Initialization: %.2f ms", phases.init))
      table.insert(result_lines, string.format("- Plugin loading: %.2f ms", phases.plugins))
      table.insert(result_lines, string.format("- UI rendering: %.2f ms", phases.ui))
      table.insert(result_lines, string.format("- Other operations: %.2f ms", phases.other))
      table.insert(result_lines, "")
      
      -- Top startup time consumers
      table.insert(result_lines, "Top 5 startup time consumers:")
      for i = 1, math.min(5, #M.profile_data.startup.events) do
        local event = M.profile_data.startup.events[i]
        table.insert(result_lines, string.format("  %d. %.2f ms: %s", i, event.time, event.event))
      end
    else
      table.insert(result_lines, "No startup time data available. Run AnalyzeStartup first.")
    end
    
    -- Add plugins section
    table.insert(result_lines, "")
    table.insert(result_lines, "## Plugin Performance")
    table.insert(result_lines, string.rep("-", width - 10))
    
    if not vim.tbl_isempty(M.profile_data.plugins) then
      table.insert(result_lines, string.format("Total plugin load time: %.2f ms", M.profile_data.plugins.total_time))
      table.insert(result_lines, string.format("Loaded plugins: %d", #M.profile_data.plugins.plugins))
      
      -- Categorize plugins by loading trigger
      local triggers = {
        startup = { count = 0, time = 0 },
        event = { count = 0, time = 0 },
        keys = { count = 0, time = 0 },
        cmd = { count = 0, time = 0 },
        ft = { count = 0, time = 0 },
        other = { count = 0, time = 0 }
      }
      
      for _, plugin in ipairs(M.profile_data.plugins.plugins) do
        if plugin.loaded_on_startup then
          triggers.startup.count = triggers.startup.count + 1
          triggers.startup.time = triggers.startup.time + plugin.time
        elseif plugin.event then
          triggers.event.count = triggers.event.count + 1
          triggers.event.time = triggers.event.time + plugin.time
        elseif plugin.keys then
          triggers.keys.count = triggers.keys.count + 1
          triggers.keys.time = triggers.keys.time + plugin.time
        elseif plugin.cmd then
          triggers.cmd.count = triggers.cmd.count + 1
          triggers.cmd.time = triggers.cmd.time + plugin.time
        elseif plugin.ft then
          triggers.ft.count = triggers.ft.count + 1
          triggers.ft.time = triggers.ft.time + plugin.time
        else
          triggers.other.count = triggers.other.count + 1
          triggers.other.time = triggers.other.time + plugin.time
        end
      end
      
      table.insert(result_lines, "")
      table.insert(result_lines, "Plugin loading triggers:")
      table.insert(result_lines, string.format("- Startup: %d plugins, %.2f ms total", 
                                            triggers.startup.count, triggers.startup.time))
      table.insert(result_lines, string.format("- Events: %d plugins, %.2f ms total", 
                                            triggers.event.count, triggers.event.time))
      table.insert(result_lines, string.format("- Keys: %d plugins, %.2f ms total", 
                                            triggers.keys.count, triggers.keys.time))
      table.insert(result_lines, string.format("- Commands: %d plugins, %.2f ms total", 
                                            triggers.cmd.count, triggers.cmd.time))
      table.insert(result_lines, string.format("- Filetypes: %d plugins, %.2f ms total", 
                                            triggers.ft.count, triggers.ft.time))
      table.insert(result_lines, string.format("- Other: %d plugins, %.2f ms total", 
                                            triggers.other.count, triggers.other.time))
      
      -- Top plugin time consumers
      table.insert(result_lines, "")
      table.insert(result_lines, "Top 5 plugin time consumers:")
      for i = 1, math.min(5, #M.profile_data.plugins.plugins) do
        local plugin = M.profile_data.plugins.plugins[i]
        table.insert(result_lines, string.format("  %d. %.2f ms: %s", i, plugin.time, plugin.name))
      end
    else
      table.insert(result_lines, "No plugin data available. Run ProfilePlugins first.")
    end
    
    -- Add optimization recommendations
    table.insert(result_lines, "")
    table.insert(result_lines, "## Optimization Recommendations")
    table.insert(result_lines, string.rep("-", width - 10))
    
    -- General recommendations based on data
    local recommendations = {}
    
    -- Startup time recommendations
    if not vim.tbl_isempty(M.profile_data.startup) then
      if M.profile_data.startup.total_time > 100 then
        table.insert(recommendations, "- Your startup time (%.2f ms) is high. Focus on reducing plugins loaded at startup.")
      end
      
      -- Check for slow startup events
      local slow_sources = {}
      for _, event in ipairs(M.profile_data.startup.events) do
        if event.event:match("sourcing") and event.time > 10 then
          local source = event.event:match("sourcing (.+)")
          if source then
            table.insert(slow_sources, {source = source, time = event.time})
          end
        end
      end
      
      if #slow_sources > 0 then
        table.insert(recommendations, "- Slow files being sourced at startup:")
        for i, source in ipairs(slow_sources) do
          if i <= 3 then -- limit to top 3
            table.insert(recommendations, string.format("  * %s (%.2f ms)", source.source, source.time))
          end
        end
      end
    end
    
    -- Plugin recommendations
    if not vim.tbl_isempty(M.profile_data.plugins) then
      -- Check for plugins that could be lazy-loaded
      local candidates_for_lazy = {}
      for _, plugin in ipairs(M.profile_data.plugins.plugins) do
        if plugin.loaded_on_startup and plugin.time > 5 then
          table.insert(candidates_for_lazy, plugin)
        end
      end
      
      if #candidates_for_lazy > 0 then
        table.insert(recommendations, "- Consider lazy-loading these plugins:")
        for i, plugin in ipairs(candidates_for_lazy) do
          if i <= 5 then -- limit to top 5
            table.insert(recommendations, string.format("  * %s (%.2f ms)", plugin.name, plugin.time))
          end
        end
      end
    end
    
    -- Add plugin specific suggestions
    if #recommendations > 0 then
      for _, recommendation in ipairs(recommendations) do
        table.insert(result_lines, recommendation)
      end
    else
      table.insert(result_lines, "- Your configuration is already well-optimized!")
    end
    
    -- Add general optimization strategies
    table.insert(result_lines, "")
    table.insert(result_lines, "General optimization strategies:")
    table.insert(result_lines, "- Use event-based loading for plugins needed shortly after startup")
    table.insert(result_lines, "- Use key-based loading for plugins only needed for specific tasks")
    table.insert(result_lines, "- Consider removing or replacing plugins with minimal Lua alternatives")
    table.insert(result_lines, "- Set vim.g.loaded_X = 1 for unused built-in plugins")
    table.insert(result_lines, "- Use modular configuration to avoid loading unnecessary code")
    
    table.insert(result_lines, "")
    table.insert(result_lines, "Press 'q' to close this window")
    
    -- Update buffer with results
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, result_lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    
    -- Make the buffer shareable (allows copying text)
    vim.api.nvim_buf_set_option(buf, "buftype", "")
  end, 100)
end

-- Analyze plugin usage patterns and suggest lazy-loading strategies
function M.suggest_lazy_loading()
  -- Create floating window for results
  local buf, win, width = create_floating_window("Lazy-Loading Suggestions")
  
  -- Set initial message
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"Analyzing plugin usage patterns... please wait"})
  
  -- Run the analysis after a short delay
  vim.defer_fn(function()
    -- Check if we have plugin data
    if vim.tbl_isempty(M.profile_data.plugins) then
      -- Try to get plugin data first
      local ok, lazy = pcall(require, "lazy")
      if not ok then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
          "lazy.nvim is not available",
          "",
          "Press 'q' to close this window"
        })
        return
      end
      
      -- Safely get plugin config
      local ok_config, lazy_config = pcall(require, "lazy.core.config")
      if not ok_config then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
          "Error: lazy.nvim core config module not available",
          "",
          "Press 'q' to close this window"
        })
        return
      end
      
      -- Get plugins list
      local plugins = lazy_config.plugins
      
      -- Safely get plugin stats
      local plugin_times = {}
      local states = {}
      
      -- Try to get stats from different API locations
      local ok_cache, cache_result
      ok_cache, cache_result = pcall(function()
        local cache = require("lazy.core.cache")
        if type(cache.stats) == "function" then
          return cache.stats()
        else
          return {}
        end
      end)
      
      if ok_cache then
        states = cache_result
      else
        -- Try alternative methods to get plugin load info
        local ok_loader, loader = pcall(require, "lazy.core.loader")
        if ok_loader and loader._loaded then
          -- Create stats manually from loader._loaded
          for name, loaded in pairs(loader._loaded) do
            states[name] = { loaded = loaded and 1 or 0 }
          end
        else
          -- Create empty states
          states = {}
        end
      end
      
      -- Collect plugin load time data
      plugin_times = {}
      
      -- Attempt to get accurate load times from Lazy's internal stats
      local ok_stats, lazy_stats = pcall(require, "lazy.stats")
      if ok_stats and lazy_stats then
        -- Try to get detailed stats from lazy.stats if available
        local stats = lazy_stats.stats() or {}
        
        -- Check the structure of stats data to handle different formats
        if type(stats) == "table" then
          -- Handle case where stats is an array of plugin info
          if stats[1] and type(stats[1]) == "table" then
            for _, plugin in ipairs(stats) do
              if type(plugin) == "table" and plugin.name and plugin.loaded then
                -- Use actual time if available, fallback to estimate
                local load_time = plugin.time or 1.0
                local plugin_obj = plugins[plugin.name] or {}
                
                table.insert(plugin_times, {
                  name = plugin.name,
                  time = load_time,
                  loaded_on_startup = plugin_obj.lazy == false,
                  event = plugin_obj.event,
                  keys = plugin_obj.keys,
                  cmd = plugin_obj.cmd,
                  ft = plugin_obj.ft,
                  config = plugin_obj.config
                })
              end
            end
          else
            -- Handle case where stats is a map of name -> info
            for name, info in pairs(stats) do
              if type(info) == "table" and info.loaded then
                -- Use actual time if available, fallback to estimate
                local load_time = info.time or 1.0
                local plugin_obj = plugins[name] or {}
                
                table.insert(plugin_times, {
                  name = name,
                  time = load_time,
                  loaded_on_startup = plugin_obj.lazy == false,
                  event = plugin_obj.event,
                  keys = plugin_obj.keys,
                  cmd = plugin_obj.cmd,
                  ft = plugin_obj.ft,
                  config = plugin_obj.config
                })
              elseif type(info) == "number" then
                -- Handle case where stats is just time values
                local load_time = info
                local plugin_obj = plugins[name] or {}
                
                table.insert(plugin_times, {
                  name = name,
                  time = load_time,
                  loaded_on_startup = plugin_obj.lazy == false,
                  event = plugin_obj.event,
                  keys = plugin_obj.keys,
                  cmd = plugin_obj.cmd,
                  ft = plugin_obj.ft,
                  config = plugin_obj.config
                })
              end
            end
          end
        end
      end
      
      -- If we have no data from stats, try the core module data
      if #plugin_times == 0 then
        -- Use lazy.nvim's core plugin structure for detection
        local lazy_loaded = {}
        local ok_loader, loader = pcall(require, "lazy.core.loader")
        if ok_loader and loader._loaded then
          lazy_loaded = loader._loaded
        end
        
        -- Create a report of all plugins
        for name, plugin in pairs(plugins) do
          -- Skip internal plugin entries or non-plugins
          if type(name) == "string" and not name:match("^_") and plugin.dir then
            local full_path = plugin.dir
            
            -- Check if files exist (simple existence check)
            local exists = vim.loop.fs_stat(full_path) ~= nil
            local is_loaded = lazy_loaded[name] or plugin.lazy == false
            
            -- Estimate load time based on plugin characteristics
            local estimated_time = 0
            
            if exists and is_loaded then
              -- Base estimate on plugin size and complexity
              estimated_time = 5.0 -- Base time for loaded plugins
              
              -- Get plugin size
              local lua_file_count = 0
              local ok, count_result = pcall(function()
                local result = vim.fn.system("find " .. vim.fn.shellescape(full_path) .. " -type f -name '*.lua' | wc -l")
                return tonumber(result) or 0
              end)
              
              if ok and count_result then
                lua_file_count = count_result
                -- More files = more load time
                estimated_time = estimated_time + (lua_file_count * 0.5)
              end
              
              -- Add info about key plugins that are known to be slow
              if name:match("nvim%-treesitter") then
                estimated_time = estimated_time + 30.0
              elseif name:match("telescope") then
                estimated_time = estimated_time + 25.0
              elseif name:match("lsp") then
                estimated_time = estimated_time + 20.0
              elseif name:match("cmp") then
                estimated_time = estimated_time + 15.0
              elseif name:match("which%-key") then
                estimated_time = estimated_time + 10.0
              end
              
              -- Add the plugin to our results
              table.insert(plugin_times, {
                name = name,
                time = estimated_time,
                loaded_on_startup = plugin.lazy == false,
                event = plugin.event, 
                keys = plugin.keys,
                cmd = plugin.cmd,
                ft = plugin.ft,
                config = plugin.config
              })
            end
          end
        end
      end
      
      -- Sort plugins by load time (descending)
      table.sort(plugin_times, function(a, b)
        return a.time > b.time
      end)
      
      -- Store in profile data
      M.profile_data.plugins = {
        plugins = plugin_times,
        timestamp = os.time()
      }
    end
    
    -- Begin analysis
    local plugins = M.profile_data.plugins.plugins
    local result_lines = {
      "# Lazy-Loading Strategy Suggestions",
      string.rep("-", width - 10),
      "",
      "The following plugins could benefit from lazy-loading strategies:",
      ""
    }
    
    -- Identify plugins loaded at startup that could be lazy-loaded
    local lazy_candidates = {}
    for _, plugin in ipairs(plugins) do
      if plugin.loaded_on_startup and plugin.time > 5 then
        table.insert(lazy_candidates, plugin)
      end
    end
    
    -- Common events that can be used for lazy-loading
    local common_events = {
      ui = {
        "VeryLazy",
        "WinScrolled",
        "BufWinEnter",
        "WinNew",
        "ColorScheme"
      },
      editing = {
        "InsertEnter",
        "CursorHold",
        "CursorHoldI"
      },
      buffers = {
        "BufReadPost",
        "BufNewFile",
        "BufWritePre"
      },
      navigation = {
        "CmdlineEnter"
      }
    }
    
    -- Common filetypes to consider for filetype-specific plugins
    local common_filetypes = {
      "lua", "python", "javascript", "typescript", "markdown", "tex", "vim"
    }
    
    -- Common commands to consider for command-specific plugins
    local common_commands = {
      git = {"Git", "Gstatus", "Gdiff", "Gblame", "Gcommit"},
      finder = {"Telescope", "Find", "Grep"},
      lsp = {"LspInfo", "LspStart", "LspStop"}
    }
    
    -- Generate suggestions
    local suggestions = {}
    
    -- Helper function to get filetype from plugin name
    local function guess_filetype(name)
      for _, ft in ipairs(common_filetypes) do
        if name:lower():match(ft) then
          return ft
        end
      end
      return nil
    end
    
    -- Process each candidate
    for _, plugin in ipairs(lazy_candidates) do
      local name = plugin.name
      local suggestion = {
        name = name,
        time = plugin.time,
        current = "startup",
        suggestions = {}
      }
      
      -- Look for patterns in the plugin name to suggest strategies
      local name_lower = name:lower()
      
      -- UI plugins
      if name_lower:match("color") or name_lower:match("theme") or name_lower:match("status") or
         name_lower:match("bar") or name_lower:match("line") or name_lower:match("icon") or
         name_lower:match("indent") or name_lower:match("scroll") then
        table.insert(suggestion.suggestions, {
          type = "event",
          value = "VeryLazy",
          reason = "UI element that can be loaded after initial rendering"
        })
      end
      
      -- File explorer plugins
      if name_lower:match("tree") or name_lower:match("explorer") or name_lower:match("file") then
        table.insert(suggestion.suggestions, {
          type = "command",
          value = "NvimTreeToggle, NvimTreeOpen",
          reason = "File explorer only needed when explicitly opened"
        })
      end
      
      -- Git plugins
      if name_lower:match("git") or name_lower:match("fugitive") or name_lower:match("sign") then
        table.insert(suggestion.suggestions, {
          type = "event",
          value = "BufReadPre",
          reason = "Git functionality typically needed when reading files"
        })
      end
      
      -- Completion and LSP
      if name_lower:match("cmp") or name_lower:match("complete") or name_lower:match("snippet") then
        table.insert(suggestion.suggestions, {
          type = "event",
          value = "InsertEnter",
          reason = "Completion only needed in insert mode"
        })
      end
      
      -- Filetype specific
      local ft = guess_filetype(name_lower)
      if ft then
        table.insert(suggestion.suggestions, {
          type = "ft",
          value = ft,
          reason = string.format("Plugin appears to be %s specific", ft)
        })
      end
      
      -- If no specific suggestions, offer generic ones
      if #suggestion.suggestions == 0 then
        table.insert(suggestion.suggestions, {
          type = "event",
          value = "BufReadPost, BufNewFile",
          reason = "Generic events that trigger after a file is loaded"
        })
        
        table.insert(suggestion.suggestions, {
          type = "keys",
          value = "<leader>",
          reason = "Consider mapping plugin functions to leader keys"
        })
      end
      
      table.insert(suggestions, suggestion)
    end
    
    -- Store suggestions for later use
    M.profile_data.lazy_suggestions = suggestions
    
    -- Format and display results
    if #suggestions > 0 then
      for i, suggestion in ipairs(suggestions) do
        table.insert(result_lines, string.format("## %d. %s (%.2f ms)", i, suggestion.name, suggestion.time))
        table.insert(result_lines, string.format("Current loading: %s", suggestion.current))
        table.insert(result_lines, "")
        table.insert(result_lines, "Suggested strategies:")
        
        for j, strat in ipairs(suggestion.suggestions) do
          table.insert(result_lines, string.format("  %d.%d. Use %s = %s", 
                                                i, j, strat.type, strat.value))
          table.insert(result_lines, string.format("       Reason: %s", strat.reason))
        end
        
        -- Add configuration example
        table.insert(result_lines, "")
        table.insert(result_lines, "Example configuration:")
        table.insert(result_lines, "```lua")
        
        -- Use the first suggestion as an example
        local example = suggestion.suggestions[1]
        local example_config = string.format([[{
  "%s",
  %s = %s,
  config = function()
    -- Your existing configuration
  end
}]], suggestion.name, 
           example.type, 
           type(example.value) == "string" and string.format('"%s"', example.value) or example.value)
        
        table.insert(result_lines, example_config)
        table.insert(result_lines, "```")
        table.insert(result_lines, "")
      end
    else
      table.insert(result_lines, "No plugins identified that require lazy-loading optimization.")
    end
    
    -- Add general advice
    table.insert(result_lines, "## General Lazy-Loading Advice")
    table.insert(result_lines, "")
    table.insert(result_lines, "1. **Events**: Use events like `BufReadPost` or `InsertEnter` for plugins needed in specific contexts")
    table.insert(result_lines, "2. **Commands**: Use command-based loading for plugins with specific commands")
    table.insert(result_lines, "3. **Filetypes**: Use ft-based loading for language-specific plugins")
    table.insert(result_lines, "4. **Keys**: Map leader-based keys for plugins used infrequently")
    table.insert(result_lines, "5. **Dependencies**: Ensure dependencies are properly configured")
    table.insert(result_lines, "")
    table.insert(result_lines, "Press 'q' to close this window")
    
    -- Update buffer with results
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, result_lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    
    -- Set buffer to markdown for syntax highlighting
    vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  end, 100)
end

-- Module setup
function M.setup()
  -- Define user commands for optimization tools
  vim.api.nvim_create_user_command("AnalyzeStartup", function() M.analyze_startup() end, {
    desc = "Analyze Neovim startup time and identify bottlenecks"
  })
  
  vim.api.nvim_create_user_command("ProfilePlugins", function() M.profile_plugins() end, {
    desc = "Profile load time for all plugins"
  })
  
  vim.api.nvim_create_user_command("OptimizationReport", function() M.generate_report() end, {
    desc = "Generate a comprehensive optimization report"
  })
  
  vim.api.nvim_create_user_command("SuggestLazyLoading", function() M.suggest_lazy_loading() end, {
    desc = "Suggest lazy-loading strategies for plugins"
  })
end

return M