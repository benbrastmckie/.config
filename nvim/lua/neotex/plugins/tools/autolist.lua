return {
  "gaoDean/autolist.nvim",
  filetype = {
    "markdown",
    "norg",
  },
  config = function()
    local autolist = require('autolist')
    
    -- Setup autolist with minimal configuration
    autolist.setup({
      lists = {
        -- Disable roman numerals and use simple numbered lists
        markdown = {
          "1.", -- Numbered lists (1., 2., 3., etc)
          "-",  -- Unordered lists with dash
          "*",  -- Unordered lists with asterisk
          "+",  -- Unordered lists with plus
        },
        norg = {
          "1.", -- Numbered lists
          "-",  -- Unordered lists
          "*",  -- Unordered lists
          "+",  -- Unordered lists
        }
      },
      enabled = true,
      cycle = {"1.", "-", "*", "+"},  -- Cycle between these list types
      
      -- VERY IMPORTANT: Disable smart indentation to prevent Tab key interference
      smart_indent = false,
      
      -- Disable automatic list continuation after colon
      colon = {
        indent = false,      -- Do NOT create a list item after lines ending with ':'
        indent_raw = false,  -- Do NOT indent raw colon lines
        preferred = "-"      -- Default bullet if needed
      },
      
      -- IMPORTANT: Disable all built-in keymaps to prevent Tab/Shift-Tab issues
      custom_keys = false
    })
    
    -- Access autolist functions after setup
    local auto = require("autolist.auto")
    
    -- Define helper function for list item detection
    local function is_list_item(line)
      local list_types = {"-", "*", "+", "%d%."}
      
      for _, pattern in ipairs(list_types) do
        if line:match("^%s*" .. pattern .. "%s") then
          return true
        end
      end
      
      return false
    end
    
    -- Create wrapper function that suppresses notifications
    local function silent_exec(func)
      -- Save previous notification function
      local old_notify = vim.notify
      -- Create temporary notification function that filters out autolist messages
      vim.notify = function(msg, level, opts)
        if not msg:match("recalculate") and not msg:match("indent") then
          old_notify(msg, level, opts)
        end
      end
      
      -- Execute the function
      local result = pcall(func)
      
      -- Restore original notification function
      vim.notify = old_notify
      
      return result
    end
    
    -- Instead of trying to delete keymaps, we'll just ensure autolist's keymaps
    -- are disabled in the setup and not create our own custom mappings
    
    -- Preserve Enter key handling which works correctly
    vim.api.nvim_create_autocmd("FileType", {
      pattern = {"markdown", "norg"},
      callback = function()
        -- Create a new mapping for <CR> with improved list handling
        vim.keymap.set("i", "<CR>", function()
          local line = vim.fn.getline(".")
          local cursor_pos = vim.api.nvim_win_get_cursor(0)
          local col = cursor_pos[2]
          
          -- For lines ending with colon, just create a normal new line
          if col == #line and line:match(":$") then
            return "\n"
          end
          
          -- If we're in a list item
          if is_list_item(line) then
            -- For empty list items (just the bullet + spaces), delete them
            if line:match("^%s*[-+*]%s+$") or line:match("^%s*%d+%.%s+$") then
              return "<C-u><CR>"
            end
            
            -- Ensure the cursor is at the end of the line to trigger bullet creation
            if col < #line then
              return "<CR>"
            end
            
            -- Let autolist handle creating the next bullet
            local keys = vim.api.nvim_replace_termcodes("<CR>", true, true, true)
            return keys
          end
          
          -- Not a list item - use standard Enter behavior
          return "<CR>"
        end, { expr = true, buffer = true, desc = "Smart list handling for Enter" })
      end
    })
    
    -- Keep o and O behavior which works correctly
    vim.api.nvim_create_autocmd("FileType", {
      pattern = {"markdown", "norg"},
      callback = function()
        for _, key in ipairs({"o", "O"}) do
          vim.keymap.set("n", key, function()
            local line = vim.fn.getline(".")
            
            -- Check if current line is a list item
            local is_current_list = is_list_item(line)
            
            -- For non-list items or lines ending with colon, use vanilla behavior
            if not is_current_list or line:match(":$") then
              -- Use Vim's native o/O behavior
              return key == "o" and "o" or "O"
            else
              -- For list items, let autolist handle it
              return key
            end
          end, { expr = true, buffer = true, desc = "Smart list-aware " .. key })
        end
      end 
    })
    
    -- Add commands for integration with which-key mappings with proper error handling
    vim.api.nvim_create_user_command('AutolistRecalculate', function()
      -- Silently recalculate list numbers
      silent_exec(function()
        auto.recalculate()
      end)
    end, {})
    
    vim.api.nvim_create_user_command('AutolistCycleNext', function()
      -- Silently cycle to next bullet type
      silent_exec(function()
        auto.cycle_next()
      end)
    end, {})
    
    vim.api.nvim_create_user_command('AutolistCyclePrev', function()
      -- Silently cycle to previous bullet type
      silent_exec(function()
        auto.cycle_prev()
      end)
    end, {})
    
    -- Fixed checkbox handling function 
    function HandleCheckbox()
      local current_line = vim.fn.line(".")
      local line = vim.fn.getline(current_line)
      
      -- Skip if not a list item
      if not is_list_item(line) then
        return
      end
      
      -- Define checkbox patterns
      local patterns = {
        empty = " [ ]",
        progress = " [.]",
        closing = " [:]",
        done = " [x]"
      }
      
      -- Get list marker (bullet symbol or number)
      local list_marker = line:match("^%s*([%d%.%-%+%*]+)%s")
      if not list_marker then
        return
      end
      
      local new_line = line
      
      -- Handle different checkbox states
      if line:match("%[%s%]") then
        -- Empty → Progress
        new_line = line:gsub("%[%s%]", "[.]", 1)
      elseif line:match("%[%.%]") then
        -- Progress → Closing
        new_line = line:gsub("%[%.%]", "[:]", 1)
      elseif line:match("%[%:%]") then
        -- Closing → Done
        new_line = line:gsub("%[%:%]", "[x]", 1)
      elseif line:match("%[x%]") then
        -- Done → No checkbox 
        local with_box = list_marker .. " [x]"
        local without_box = list_marker
        new_line = line:gsub(vim.pesc(with_box), without_box, 1)
      else
        -- No checkbox → Empty
        -- Escape special characters in marker
        local escaped_marker = vim.pesc(list_marker)
        -- Add checkbox after marker
        new_line = line:gsub(escaped_marker .. "%s+", escaped_marker .. patterns.empty .. " ", 1)
      end
      
      -- Update the line with new content
      vim.fn.setline(current_line, new_line)
    end
    
    -- CUSTOM TAB FUNCTIONS FOR MARKDOWN
    -- These functions create a more elegant way to handle Tab and Shift-Tab
    -- in markdown files with bulleted lists
    
    -- AutolistTab - Indents the whole line and keeps cursor in insert mode
    function _G.AutolistTab()
      -- Get current line info
      local line = vim.fn.getline(".")
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      local row, col = cursor_pos[1], cursor_pos[2]
      
      -- Check if this is a list item
      if not is_list_item(line) then
        -- Not a list - use default Tab behavior
        return vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
      end

      -- Remember cursor position relative to end of line
      local end_col = #line
      local from_end = end_col - col
      
      -- Use Lua API to indent instead of vim.cmd to avoid E523 errors
      local indent_size = vim.bo.shiftwidth
      local current_line = vim.api.nvim_get_current_line()
      local indented_line = string.rep(" ", indent_size) .. current_line
      vim.api.nvim_set_current_line(indented_line)
      
      -- Recalculate list after indentation
      silent_exec(function() 
        auto.recalculate() 
      end)
      
      -- Get new line length after indentation
      local new_line = vim.fn.getline(".")
      local new_end_col = #new_line
      
      -- Calculate new cursor position
      local new_col = math.max(0, new_end_col - from_end)
      
      -- Set the cursor to the new position (no need to exit/re-enter insert mode)
      vim.api.nvim_win_set_cursor(0, {row, new_col})
      
      -- Return empty string as we've handled the key press
      return ""
    end
    
    -- AutolistShiftTab - Unindents the whole line and keeps cursor in insert mode
    function _G.AutolistShiftTab()
      -- Get current line info
      local line = vim.fn.getline(".")
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      local row, col = cursor_pos[1], cursor_pos[2]
      
      -- Check if this is a list item
      if not is_list_item(line) then
        -- Not a list - use default Shift-Tab behavior
        return vim.api.nvim_replace_termcodes("<C-D>", true, true, true)
      end
      
      -- Check indentation level
      local indent = line:match("^%s*") or ""
      if #indent < 2 then
        -- Not enough indentation to remove
        return ""
      end
      
      -- Remember cursor position relative to end of line
      local end_col = #line
      local from_end = end_col - col
      
      -- Use Lua API to unindent instead of vim.cmd to avoid E523 errors
      local indent_size = vim.bo.shiftwidth
      local current_line = vim.api.nvim_get_current_line()
      
      -- Only remove indentation if there's enough to remove
      if current_line:sub(1, indent_size):match("^%s+$") then
        local unindented_line = current_line:sub(indent_size + 1)
        vim.api.nvim_set_current_line(unindented_line)
      end
      
      -- Recalculate list after unindentation
      silent_exec(function() 
        auto.recalculate() 
      end)
      
      -- Get new line length after unindentation
      local new_line = vim.fn.getline(".")
      local new_end_col = #new_line
      
      -- Calculate new cursor position
      local new_col = math.max(0, new_end_col - from_end)
      
      -- Set the cursor to the new position (no need to exit/re-enter insert mode)
      vim.api.nvim_win_set_cursor(0, {row, new_col})
      
      -- Return empty string as we've handled the key press
      return ""
    end
    
    -- Register commands for the new functions
    vim.api.nvim_create_user_command('AutolistTab', function()
      local result = _G.AutolistTab()
      if result and result ~= "" then
        vim.api.nvim_feedkeys(result, "n", true)
      end
    end, {})
    
    vim.api.nvim_create_user_command('AutolistShiftTab', function()
      local result = _G.AutolistShiftTab()
      if result and result ~= "" then
        vim.api.nvim_feedkeys(result, "n", true)
      end
    end, {})
  end,
}