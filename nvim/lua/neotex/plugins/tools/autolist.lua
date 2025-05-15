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
    
    -- Global flag to track if Tab was just used for indentation
    _G._last_tab_was_indent = false
    
    -- Global flag to track if we need to prevent the completion menu
    _G._prevent_cmp_menu = false
    
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
      
      -- Execute the function with pcall and get status and result
      local status, result = pcall(func)
      
      -- Restore original notification function
      vim.notify = old_notify
      
      return status, result
    end
    
    -- Safe indentation for lists - avoids expression mapping issues
    local function indent_list_item()
      -- Get current state
      local line = vim.fn.getline(".")
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      local row, col = cursor_pos[1], cursor_pos[2]
      
      -- Determine if we're on a list item
      if not is_list_item(line) then
        -- Not on a list item, use default Tab behavior
        -- Make sure our flags are reset
        _G._last_tab_was_indent = false
        _G._prevent_cmp_menu = false
        
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes("<Tab>", true, true, true),
          'n', true
        )
        return
      end
      
      -- Set flag to indicate we just used Tab for indentation
      _G._last_tab_was_indent = true
      _G._prevent_cmp_menu = true
      
      -- Clear the flag after a short delay
      vim.defer_fn(function()
        _G._last_tab_was_indent = false
      end, 300)
      
      -- Schedule text modification for next event cycle
      vim.schedule(function()
        -- Get indent size from buffer settings
        local indent_size = vim.bo.shiftwidth
        
        -- Add indentation to the entire line
        local current_line = vim.api.nvim_get_current_line()
        local indented_line = string.rep(" ", indent_size) .. current_line
        
        -- Set the new line content
        local success = pcall(function() vim.api.nvim_set_current_line(indented_line) end)
        
        if not success then
          -- Try an alternative approach if direct modification failed
          vim.schedule(function()
            -- Use feedkeys as last resort
            local keys = vim.api.nvim_replace_termcodes("<Esc>>>gi", true, true, true)
            vim.api.nvim_feedkeys(keys, 'n', true)
          end)
          return
        end
        
        -- Try to recalculate list (using autolist's function)
        silent_exec(function()
          -- Only try to use autolist if it's available
          if auto and auto.recalculate then
            auto.recalculate()
          end
        end)
        
        -- Calculate new cursor position
        local new_col = col + indent_size  -- Shift cursor right by indent amount
        
        -- Set cursor position
        pcall(function() vim.api.nvim_win_set_cursor(0, {row, new_col}) end)
        
        -- Ensure we stay in insert mode
        if vim.api.nvim_get_mode().mode ~= "i" then
          vim.cmd("startinsert")
        end
        
        -- Clear the prevent_cmp_menu flag after another delay
        vim.defer_fn(function()
          _G._prevent_cmp_menu = false
        end, 1000)  -- Longer delay to make sure we don't get the menu
      end)
    end
    
    -- Safe unindentation for lists - avoids expression mapping issues
    local function unindent_list_item()
      -- Get current state
      local line = vim.fn.getline(".")
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      local row, col = cursor_pos[1], cursor_pos[2]
      
      -- Determine if we're on a list item
      if not is_list_item(line) then
        -- Not on a list item, use default Shift-Tab behavior
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes("<C-D>", true, true, true),
          'n', true
        )
        return
      end
      
      -- Check if there's indentation to remove
      local indent = line:match("^%s*") or ""
      local indent_size = vim.bo.shiftwidth
      
      if #indent < indent_size then
        -- Not enough indentation to remove
        return
      end
      
      -- For robustness, immediately unindent without scheduling
      -- This helps with Shift-Tab which can be problematic in some terminals
      local current_line = vim.api.nvim_get_current_line()
      local unindented_line = current_line:sub(indent_size + 1)
      
      -- Try direct method first
      local success = pcall(function() vim.api.nvim_set_current_line(unindented_line) end)
      
      if not success then
        -- If direct modification fails, try via feedkeys
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes("<Esc><<gi", true, true, true),
          'n', true
        )
        return
      end
      
      -- Try to recalculate list immediately
      silent_exec(function()
        if auto and auto.recalculate then
          auto.recalculate()
        end
      end)
      
      -- Calculate new cursor position (shift left, but not past beginning)
      local new_col = math.max(0, col - indent_size)
      
      -- Set cursor position immediately
      pcall(function() vim.api.nvim_win_set_cursor(0, {row, new_col}) end)
      
      -- Ensure we stay in insert mode
      vim.cmd("startinsert")
    end
    
    -- Create user commands for Tab and Shift-Tab
    vim.api.nvim_create_user_command('AutolistIndent', function()
      indent_list_item()
    end, {})
    
    vim.api.nvim_create_user_command('AutolistUnindent', function()
      unindent_list_item()
    end, {})
    
    -- No additional keybindings as requested by user
    
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
        
        -- Tab/Shift-Tab mappings are set in keymaps.lua
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
    
    -- Diagnostic tool to help debug key mappings
    vim.api.nvim_create_user_command('DebugMappings', function()
      local modes = {'i', 'n', 'v'}
      local keys = {'<Tab>', '<S-Tab>', '<C-D>'}
      
      for _, mode in ipairs(modes) do
        for _, key in ipairs(keys) do
          print(string.format("Mode: %s, Key: %s", mode, key))
          vim.cmd(string.format("verbose %smap %s", mode, key))
          print("---")
        end
      end
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
  end,
}