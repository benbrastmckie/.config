-- Notification Migration Utility
-- Helper tools for migrating vim.notify calls to the unified notification system

local M = {}

-- Pattern mapping for common notification migrations
M.migration_patterns = {
  -- Error notifications
  {
    pattern = "vim%.notify%((.-),%s*vim%.log%.levels%.ERROR%)",
    replacement = "require('neotex.util.notifications').%s('%1', require('neotex.util.notifications').categories.ERROR)",
    description = "Error notifications"
  },
  
  -- Warning notifications
  {
    pattern = "vim%.notify%((.-),%s*vim%.log%.levels%.WARN%)",
    replacement = "require('neotex.util.notifications').%s('%1', require('neotex.util.notifications').categories.WARNING)",
    description = "Warning notifications"
  },
  
  -- Info notifications (user actions)
  {
    pattern = "vim%.notify%('([^']*successfully[^']*)',%s*vim%.log%.levels%.INFO%)",
    replacement = "require('neotex.util.notifications').%s('%1', require('neotex.util.notifications').categories.USER_ACTION)",
    description = "Success notifications"
  },
  
  -- Info notifications (status)
  {
    pattern = "vim%.notify%((.-),%s*vim%.log%.levels%.INFO%)",
    replacement = "require('neotex.util.notifications').%s('%1', require('neotex.util.notifications').categories.STATUS)",
    description = "General info notifications"
  },
  
  -- Debug notifications
  {
    pattern = "vim%.notify%((.-),%s*vim%.log%.levels%.DEBUG%)",
    replacement = "require('neotex.util.notifications').%s('%1', require('neotex.util.notifications').categories.BACKGROUND)",
    description = "Debug notifications"
  }
}

-- Module type mapping for different file paths
M.module_mapping = {
  ["himalaya"] = "himalaya",
  ["ai"] = "ai",
  ["lsp"] = "lsp", 
  ["editor"] = "editor",
  ["util"] = "editor",
  ["config"] = "startup"
}

-- Determine the appropriate module function based on file path
function M.get_module_function(filepath)
  for pattern, module in pairs(M.module_mapping) do
    if filepath:match(pattern) then
      return module
    end
  end
  return "editor" -- Default fallback
end

-- Analyze a file for notification patterns
function M.analyze_file(filepath)
  local file = io.open(filepath, 'r')
  if not file then
    return { error = "Could not open file: " .. filepath }
  end
  
  local content = file:read('*all')
  file:close()
  
  local findings = {}
  local module_func = M.get_module_function(filepath)
  
  for i, pattern_info in ipairs(M.migration_patterns) do
    local matches = {}
    for match in content:gmatch(pattern_info.pattern) do
      table.insert(matches, match)
    end
    
    if #matches > 0 then
      table.insert(findings, {
        pattern = pattern_info.description,
        count = #matches,
        replacement_template = pattern_info.replacement:format(module_func),
        matches = matches
      })
    end
  end
  
  return {
    filepath = filepath,
    module = module_func,
    total_notifications = #findings,
    findings = findings
  }
end

-- Generate migration commands for a file
function M.generate_migration_commands(filepath)
  local analysis = M.analyze_file(filepath)
  if analysis.error then
    return analysis
  end
  
  local commands = {}
  local module_func = analysis.module
  
  for _, pattern_info in ipairs(M.migration_patterns) do
    local replacement = pattern_info.replacement:format(module_func)
    table.insert(commands, string.format(
      "-- %s: %s",
      pattern_info.description,
      replacement
    ))
  end
  
  return {
    filepath = filepath,
    commands = commands,
    analysis = analysis
  }
end

-- Show migration analysis for a file
function M.show_analysis(filepath)
  local analysis = M.analyze_file(filepath)
  
  if analysis.error then
    vim.notify(analysis.error, vim.log.levels.ERROR)
    return
  end
  
  local lines = {}
  table.insert(lines, "=== Notification Migration Analysis ===")
  table.insert(lines, "")
  table.insert(lines, "File: " .. analysis.filepath)
  table.insert(lines, "Module: " .. analysis.module)
  table.insert(lines, "Total patterns found: " .. analysis.total_notifications)
  table.insert(lines, "")
  
  for _, finding in ipairs(analysis.findings) do
    table.insert(lines, string.format("%s: %d matches", finding.pattern, finding.count))
    table.insert(lines, "  Template: " .. finding.replacement_template)
    table.insert(lines, "")
  end
  
  if #analysis.findings == 0 then
    table.insert(lines, "No vim.notify patterns found in this file.")
  end
  
  -- Create popup window
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].filetype = 'text'
  vim.bo[bufnr].readonly = true
  
  local width = 80
  local height = math.min(25, #lines + 2)
  
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' Migration Analysis ',
    title_pos = 'center'
  }
  
  local winid = vim.api.nvim_open_win(bufnr, true, win_opts)
  
  -- Set up keymaps for the popup
  local opts = { buffer = bufnr, silent = true }
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(winid, true)
  end, opts)
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(winid, true)
  end, opts)
end

-- Scan all Lua files for notification usage
function M.scan_all_files()
  local scan_dirs = {
    vim.fn.stdpath('config') .. '/lua/neotex/plugins',
    vim.fn.stdpath('config') .. '/lua/neotex/util',
    vim.fn.stdpath('config') .. '/lua/neotex/config'
  }
  
  local results = {}
  local total_files = 0
  local total_notifications = 0
  
  for _, dir in ipairs(scan_dirs) do
    local files = vim.fn.globpath(dir, '**/*.lua', false, true)
    for _, filepath in ipairs(files) do
      total_files = total_files + 1
      local analysis = M.analyze_file(filepath)
      if not analysis.error and analysis.total_notifications > 0 then
        table.insert(results, analysis)
        total_notifications = total_notifications + analysis.total_notifications
      end
    end
  end
  
  return {
    total_files = total_files,
    files_with_notifications = #results,
    total_notifications = total_notifications,
    results = results
  }
end

-- Show comprehensive scan results
function M.show_scan_results()
  local scan = M.scan_all_files()
  
  local lines = {}
  table.insert(lines, "=== Configuration-wide Notification Scan ===")
  table.insert(lines, "")
  table.insert(lines, string.format("Total files scanned: %d", scan.total_files))
  table.insert(lines, string.format("Files with notifications: %d", scan.files_with_notifications))
  table.insert(lines, string.format("Total notification patterns: %d", scan.total_notifications))
  table.insert(lines, "")
  
  if #scan.results > 0 then
    table.insert(lines, "Files requiring migration:")
    table.insert(lines, "")
    for _, result in ipairs(scan.results) do
      local relative_path = result.filepath:gsub(vim.fn.stdpath('config'), '~/.config/nvim')
      table.insert(lines, string.format("%s (%d patterns)", relative_path, result.total_notifications))
    end
  else
    table.insert(lines, "All files have been migrated to the unified notification system!")
  end
  
  -- Create popup window
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].filetype = 'text'
  vim.bo[bufnr].readonly = true
  
  local width = 80
  local height = math.min(30, #lines + 2)
  
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' Notification Scan Results ',
    title_pos = 'center'
  }
  
  local winid = vim.api.nvim_open_win(bufnr, true, win_opts)
  
  -- Set up keymaps for the popup
  local opts = { buffer = bufnr, silent = true }
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(winid, true)
  end, opts)
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(winid, true)
  end, opts)
end

-- Create user commands for migration utilities
function M.setup_commands()
  vim.api.nvim_create_user_command('NotificationMigrationAnalyze', function(opts)
    local filepath = opts.args
    if filepath == '' then
      filepath = vim.fn.expand('%:p')
    end
    M.show_analysis(filepath)
  end, {
    nargs = '?',
    complete = 'file',
    desc = 'Analyze file for notification migration opportunities'
  })
  
  vim.api.nvim_create_user_command('NotificationMigrationScan', function()
    M.show_scan_results()
  end, {
    desc = 'Scan entire configuration for notification migration status'
  })
end

-- Initialize migration utilities
function M.init()
  M.setup_commands()
end

return M