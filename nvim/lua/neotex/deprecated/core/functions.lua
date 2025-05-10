-----------------------------------------------------------
-- DEPRECATED: This module is deprecated and will be removed in a future version.
-- Please use the new utility modules in neotex/utils/ instead:
-- - Buffer functions: neotex.utils.buffer
-- - Fold functions: neotex.utils.fold
-- - URL functions: neotex.utils.url
-- - Misc functions: neotex.utils.misc
-- See NEW_STRUCTURE.md for details on the new organization.
-----------------------------------------------------------

-- Display vim messages in quickfix window
function DisplayMessages()
  -- Get all messages and split them into lines
  local messages = vim.fn.execute('messages')
  local lines = vim.split(messages, '\n')

  -- Create quickfix items from messages
  local qf_items = vim.tbl_map(function(line)
    return { text = line }
  end, lines)

  -- Set the quickfix list and open it
  vim.fn.setqflist(qf_items)
  vim.cmd('copen')
end

-- Find all instances of a word in a project with telescope
function SearchWordUnderCursor()
  local word = vim.fn.expand('<cword>')
  require('telescope.builtin').live_grep({ default_text = word })
end

-- Reload neovim config
vim.api.nvim_create_user_command('ReloadConfig', function()
  for name, _ in pairs(package.loaded) do
    if name:match('^plugins') then
      package.loaded[name] = nil
    end
  end

  dofile(vim.env.MYVIMRC)
  vim.notify('Nvim configuration reloaded!', vim.log.levels.INFO)
end, {})

-- Go to next/previous most recent buffer, excluding buffers where winfixbuf = true
function GotoBuffer(count, direction)
  -- Check if a buffer is in a fixed window
  local function is_buffer_fixed(buf)
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      if vim.wo[win].winfixbuf then
        return true
      end
    end
    return false
  end

  -- Check if current window is fixed
  local current_buf = vim.api.nvim_get_current_buf()
  if is_buffer_fixed(current_buf) then
    return
  end

  local buffers = vim.fn.getbufinfo({ buflisted = 1 })

  -- Filter and sort buffers into two groups
  local normal_buffers = {}
  local fixed_buffers = {}

  for _, buf in ipairs(buffers) do
    if is_buffer_fixed(buf.bufnr) then
      table.insert(fixed_buffers, buf)
    else
      table.insert(normal_buffers, buf)
    end
  end

  -- Sort both lists by modification time
  local sort_by_mtime = function(a, b)
    return vim.fn.getftime(a.name) > vim.fn.getftime(b.name)
  end
  table.sort(normal_buffers, sort_by_mtime)
  table.sort(fixed_buffers, sort_by_mtime)

  -- Choose which buffer list to use
  local target_buffers = #normal_buffers > 0 and normal_buffers or fixed_buffers
  if #target_buffers == 0 then
    return
  end

  -- Find current buffer index
  local current = vim.fn.bufnr('%')
  local current_index = 1
  for i, buf in ipairs(target_buffers) do
    if buf.bufnr == current then
      current_index = i
      break
    end
  end

  -- Calculate target buffer index
  local target_index = current_index + (direction * count)
  if target_index < 1 then
    target_index = #target_buffers
  elseif target_index > #target_buffers then
    target_index = 1
  end

  -- Switch to target buffer
  vim.cmd('buffer ' .. target_buffers[target_index].bufnr)
end

-- Function to toggle between fully open and fully closed folds
function _G.ToggleAllFolds()
  -- Get current state by checking if any folds are closed
  local all_open = true
  local line_count = vim.fn.line('$')

  for i = 1, line_count do
    if vim.fn.foldclosed(i) ~= -1 then
      -- Found a closed fold, so not all are open
      all_open = false
      break
    end
  end

  if all_open then
    -- All folds are open, so close them all
    vim.cmd('normal! zM')
    vim.notify("All folds closed", vim.log.levels.INFO)
  else
    -- Some folds are closed, so open them all
    vim.cmd('normal! zR')
    vim.notify("All folds opened", vim.log.levels.INFO)
  end
end

-- Create a functions table for requiring from other modules
local M = {}

-- Custom Markdown header-based folding function
-- This creates folds at each heading level (# Header)
function _G.MarkdownFoldLevel()
  local line = vim.fn.getline(vim.v.lnum)
  local next_line = vim.fn.getline(vim.v.lnum + 1)

  -- Check for markdown headings (### style)
  local level = line:match("^(#+)%s")
  if level then
    return ">" .. string.len(level)
  end

  -- Check for markdown headings (underline style)
  if next_line and next_line:match("^=+$") then
    return ">1"
  end
  if next_line and next_line:match("^-+$") then
    return ">2"
  end

  -- Keep current level for indented content
  return "="
end

-- Function to toggle foldenable with notification
function M.ToggleFoldEnable()
  -- Toggle the foldenable option
  vim.wo.foldenable = not vim.wo.foldenable

  -- Show notification about the new state
  if vim.wo.foldenable then
    vim.notify("Folding enabled", vim.log.levels.INFO)
  else
    vim.notify("Folding disabled", vim.log.levels.INFO)
  end
end

-- Function to toggle between manual and expr folding method
-- The state is persisted between sessions for all filetypes
function _G.ToggleFoldingMethod()
  local cache_dir = vim.fn.stdpath("cache")
  local fold_state_file = cache_dir .. "/folding_state"

  -- Ensure the cache directory exists
  vim.fn.mkdir(cache_dir, 'p')

  -- The current folding method
  local current_method = vim.wo.foldmethod
  local new_method = ""

  -- Toggle the folding method
  if current_method == "manual" then
    -- For markdown files, we use our custom expression
    if vim.bo.filetype == "markdown" or vim.bo.filetype == "lectic.markdown" then
      new_method = "expr"
      vim.wo.foldmethod = "expr"
      vim.wo.foldexpr = "v:lua.MarkdownFoldLevel()"
      vim.notify("Folding enabled (expr with markdown support)", vim.log.levels.INFO)
    else
      -- For other filetypes, use indent folding which is generally useful
      new_method = "indent"
      vim.wo.foldmethod = "indent"
      vim.notify("Folding enabled (indent)", vim.log.levels.INFO)
    end

    -- Save the state to file with error handling
    local ok, err = pcall(function()
      local file = io.open(fold_state_file, "w")
      if not file then
        error("Could not open fold state file for writing")
      end
      file:write(new_method)
      file:close()
    end)

    if not ok then
      vim.notify("Error saving fold state: " .. err, vim.log.levels.WARN)
    end
  else
    new_method = "manual"
    vim.wo.foldmethod = "manual"
    vim.notify("Folding set to manual", vim.log.levels.INFO)

    -- Save the state to file with error handling
    local ok, err = pcall(function()
      local file = io.open(fold_state_file, "w")
      if not file then
        error("Could not open fold state file for writing")
      end
      file:write("manual")
      file:close()
    end)

    if not ok then
      vim.notify("Error saving fold state: " .. err, vim.log.levels.WARN)
    end
  end

  -- Ensure folds are visible (whether open or closed)
  vim.wo.foldenable = true
end

-- Function to load the saved folding state
function M.LoadFoldingState()
  local cache_dir = vim.fn.stdpath("cache")
  local fold_state_file = cache_dir .. "/folding_state"

  -- Check if the state file exists
  if vim.fn.filereadable(fold_state_file) == 1 then
    local ok, result = pcall(function()
      local file = io.open(fold_state_file, "r")
      if not file then
        error("Could not open fold state file for reading")
      end

      local state = file:read("*all")
      file:close()
      return state
    end)

    if ok then
      local state = result

      -- Apply the saved state
      if state == "expr" and (vim.bo.filetype == "markdown" or vim.bo.filetype == "lectic.markdown") then
        vim.wo.foldmethod = "expr"
        vim.wo.foldexpr = "v:lua.MarkdownFoldLevel()"
      elseif state == "indent" then
        vim.wo.foldmethod = "indent"
      else
        vim.wo.foldmethod = "manual"
      end
    else
      vim.notify("Error loading fold state: " .. result, vim.log.levels.WARN)
      -- Fall back to manual folding
      vim.wo.foldmethod = "manual"
    end
  else
    -- No state file exists, default to manual folding
    vim.wo.foldmethod = "manual"
  end

  -- Ensure foldenable is always set to true
  vim.wo.foldenable = true
  -- Start with all folds open for better usability
  vim.wo.foldlevel = 99
end

-- URL Handling Functions
-- Function to extract URLs from a line of text (supports more URL patterns)
function M.ExtractUrlsFromLine(line)
  -- Handle nil or empty input
  if not line or line == "" then
    return {}
  end

  local urls = {}
  local url_patterns = {
    -- Markdown link format [text](url)
    "%[.-%]%((.-)%)",
    -- HTML link format <a href="url">
    "<a%s+[^>]*href=[\"']([^\"']+)[\"'][^>]*>",
    -- Plain URLs with various protocols
    "https?://[%w%.%-%+%_%:%&%=%?%/%(%)%#%$%@%!%~%*]+",
    "www%.[%w%.%-%+%_%:%&%=%?%/%(%)%#%$%@%!%~%*]+",
    "file://[%w%.%-%+%_%:%&%=%?%/%(%)%#%$%@%!%~%*]+",
    -- Email addresses
    "[%w%.%-%+_]+@[%w%.%-%+_]+%.[%w%.%-%+_]+",
    -- Local file paths (Unix style)
    "/[%w%.%-%+%_%/]+%.[%w%.%-%+_]+",
  }

  for _, pattern in ipairs(url_patterns) do
    for url_match in string.gmatch(line, pattern) do
      -- Process the URL based on the pattern
      local url = url_match

      -- Store the URL and its position
      local start_idx = string.find(line, url_match, 1, true)
      if start_idx then
        -- For markdown links, the pattern captures just the URL part
        if pattern == "%[.-%]%((.-)%)" then
          -- Safely escape the URL for pattern matching
          local escaped_url = url:gsub("([%%%-%+%_%:%&%=%?%/%(%)%#%$%@%!%~%*])", "%%%1")
          -- Find the actual text of the full markdown link for position calculation
          local full_link_start = line:find("%[.-%]%(" .. escaped_url .. "%)", 1)

          -- Only proceed if we found a valid start position
          if full_link_start then
            local full_link_end = full_link_start
            -- Find the closing parenthesis
            local depth = 0
            for i = full_link_start, #line do
              local char = line:sub(i, i)
              if char == "(" then
                depth = depth + 1
              elseif char == ")" then
                depth = depth - 1
                if depth == 0 then
                  full_link_end = i
                  break
                end
              end
            end

            -- Only proceed if we have valid positions
            local url_start = line:find("%(", full_link_start, true)
            if url_start and full_link_end and full_link_start then
              url_start = url_start + 1 -- Move past the opening parenthesis
              table.insert(urls, {
                url = url,
                start = full_link_start,
                finish = full_link_end,
                url_start = url_start,
                url_end = url_start + #url - 1
              })
            end
          end
          -- For HTML links, capture the href value
        elseif pattern == "<a%s+[^>]*href=[\"']([^\"']+)[\"'][^>]*>" then
          -- Find the full tag containing this href
          local tag_start = line:find(
            "<a%s+[^>]*href=[\"']" .. url_match:gsub("([%%%-%+%_%:%&%=%?%/%(%)%#%$%@%!%~%*])", "%%%1") .. "[\"'][^>]*>",
            1)
          if tag_start then
            -- Find the closing > of this tag
            local tag_end = line:find(">", tag_start)
            if tag_end then
              table.insert(urls, {
                url = url,
                start = tag_start,
                finish = tag_end,
                url_start = line:find(url, tag_start, true),
                url_end = line:find(url, tag_start, true) + #url - 1
              })
            end
          end
        else
          -- For regular URLs, store their positions directly
          table.insert(urls, {
            url = url,
            start = start_idx,
            finish = start_idx + #url - 1
          })
        end
      end
    end
  end

  return urls
end

-- Function to open URL at a specific position or under cursor
function M.OpenUrlAtPosition(line_num, col)
  -- Validate parameters
  if not line_num or line_num < 1 then
    vim.notify("Invalid line number", vim.log.levels.ERROR)
    return false
  end

  -- Get the content of the specified line
  local ok, line = pcall(vim.api.nvim_buf_get_lines, 0, line_num - 1, line_num, false)

  -- Handle errors or empty result
  if not ok or not line or #line == 0 then
    vim.notify("Could not read line " .. line_num, vim.log.levels.ERROR)
    return false
  end

  line = line[1]
  if not line or line == "" then return false end

  -- Extract all URLs from the line
  local urls = M.ExtractUrlsFromLine(line)
  if #urls == 0 then return false end

  -- Find the URL at or closest to the position
  local selected_url = nil
  local min_distance = math.huge

  -- Only process URLs if we have valid column position
  if col and #urls > 0 then
    for _, url_info in ipairs(urls) do
      -- Ensure we have valid position information
      if url_info.start and url_info.finish then
        if col >= url_info.start and col <= url_info.finish then
          -- Position is directly on this URL
          selected_url = url_info.url
          break
        else
          -- Calculate distance to this URL
          local distance = math.min(math.abs(col - url_info.start), math.abs(col - url_info.finish))
          if distance < min_distance then
            min_distance = distance
            selected_url = url_info.url
          end
        end
      end
    end
  end

  if selected_url then
    -- Determine URL type and ensure proper protocol prefix

    -- Handle email addresses
    if selected_url:match("^[%w%.%-%+_]+@[%w%.%-%+_]+%.[%w%.%-%+_]+$") then
      selected_url = "mailto:" .. selected_url

      -- Handle local file paths
    elseif selected_url:match("^/[%w%.%-%+%_%/]+%.[%w%.%-%+_]+$") then
      selected_url = "file://" .. selected_url

      -- Make sure web URLs have protocol prefix
    elseif not selected_url:match("^https?://") and
        not selected_url:match("^file://") and
        not selected_url:match("^mailto:") then
      -- Handle www URLs
      if selected_url:match("^www%.") then
        selected_url = "https://" .. selected_url

        -- Only add https if it looks like a domain (contains a dot)
      elseif selected_url:match("%.") then
        selected_url = "https://" .. selected_url
      end
    end

    -- Detect the platform and use appropriate browser command
    local cmd
    if vim.fn.has("mac") == 1 then
      cmd = string.format("silent !open '%s' &", selected_url:gsub("'", "\\'"))
    elseif vim.fn.has("unix") == 1 then
      cmd = string.format("silent !xdg-open '%s' &", selected_url:gsub("'", "\\'"))
    elseif vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
      cmd = string.format("silent !start \"\" \"%s\"", selected_url:gsub('"', '\\"'))
    else
      vim.notify("Platform not supported for opening URLs", vim.log.levels.ERROR)
      return false
    end

    -- Execute the command with error handling
    local ok, err = pcall(function()
      vim.cmd(cmd)
    end)

    if ok then
      vim.notify("Opening URL: " .. selected_url, vim.log.levels.INFO)
      return true
    else
      vim.notify("Error opening URL: " .. err, vim.log.levels.ERROR)
      return false
    end
  end

  return false
end

-- Function to open URL at mouse position
function _G.OpenUrlAtMouse()
  local mouse_pos = vim.fn.getmousepos()
  if not mouse_pos or not mouse_pos.line or not mouse_pos.column then
    vim.notify("Invalid mouse position", vim.log.levels.WARN)
    return false
  end

  local line_num = mouse_pos.line
  local col = mouse_pos.column - 1 -- Convert to 0-indexed

  if M.OpenUrlAtPosition(line_num, col) then
    return true
  else
    vim.notify("No URL found at mouse position", vim.log.levels.WARN)
    return false
  end
end

-- Function to open URL under cursor
function _G.OpenUrlUnderCursor()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local line_num = cursor_pos[1]
  local col = cursor_pos[2]

  if M.OpenUrlAtPosition(line_num, col) then
    return true
  else
    vim.notify("No URL found under cursor", vim.log.levels.WARN)
    return false
  end
end

-- Function to setup global URL mappings for all buffers
function M.SetupUrlMappings()
  -- Basic options for all mappings
  local opts = { noremap = true, silent = true }

  -- Track if we've already set up the mappings to avoid duplicates
  if M._url_mappings_setup then
    return
  end

  -- Add keybinding to open the URL under cursor with gx for familiar Vim behavior
  vim.keymap.set("n", "gx", ":lua OpenUrlUnderCursor()<CR>",
    vim.tbl_extend("force", opts, { desc = "Open URL under cursor" }))

  -- Enable Ctrl+Click to open URLs with error handling
  vim.keymap.set("n", "<C-LeftMouse>", function()
    -- We don't perform standard Ctrl+LeftMouse because we want to keep cursor position
    vim.schedule(function()
      local ok, err = pcall(OpenUrlAtMouse)
      if not ok then
        vim.notify("Error handling mouse click: " .. err, vim.log.levels.ERROR)
      end
    end)
  end, vim.tbl_extend("force", opts, { desc = "Open URL with Ctrl+Click" }))

  -- Handle mouse release to avoid issues
  vim.keymap.set("n", "<C-LeftRelease>", "<Nop>", opts)

  -- Mark mappings as set up
  M._url_mappings_setup = true
end

-- Function to copy diagnostics to clipboard
function _G.CopyDiagnosticsToClipboard()
  local diagnostics = vim.diagnostic.get(0)  -- Get diagnostics for current buffer
  if #diagnostics == 0 then
    vim.notify("No diagnostics found", vim.log.levels.INFO)
    return
  end
  
  local lines = {}
  for _, diagnostic in ipairs(diagnostics) do
    local severity = diagnostic.severity
    local severity_names = {"ERROR", "WARN", "INFO", "HINT"}
    local severity_name = severity_names[severity] or "UNKNOWN"
    local line = string.format("%s:%d:%d: %s: %s", 
      vim.fn.bufname(diagnostic.bufnr) or "[No Name]",
      diagnostic.lnum + 1,
      diagnostic.col + 1,
      severity_name,
      diagnostic.message)
    table.insert(lines, line)
  end
  
  local formatted = table.concat(lines, "\n")
  vim.fn.setreg('+', formatted)
  vim.notify("Copied " .. #diagnostics .. " diagnostics to clipboard", vim.log.levels.INFO)
end

-- Return the module
return M
