return {
  "gaoDean/autolist.nvim",
  filetype = {
    "markdown",
    "norg",
  },
  config = function()
    local autolist = require('autolist')
    
    -- Access autolist configuration
    local autolist_config = require("autolist.config")
    
    -- Setup autolist with configuration
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
      smart_indent = true,      -- Enable smart indentation
      
      -- Disable automatic list continuation after colon
      colon = {
        indent = false,      -- Do NOT create a list item after lines ending with ':'
        indent_raw = false,  -- Do NOT indent raw colon lines
        preferred = "-"      -- Default bullet if needed
      },
      
      -- IMPORTANT: Disable all keymaps to prevent conflicts
      custom_keys = false
    })
    
    -- Safe way to access autolist.auto after setup
    local auto = require("autolist.auto")
    
    -- Completely rewritten Tab implementation without expression mapping
    vim.api.nvim_create_autocmd("FileType", {
      pattern = {"markdown", "norg"}, 
      callback = function()
        -- Map Tab key directly, not using expression mapping
        vim.keymap.set("i", "<Tab>", function() 
          -- Get current line and cursor position
          local line = vim.fn.getline(".")
          local cursor_pos = vim.api.nvim_win_get_cursor(0)
          local row, col = cursor_pos[1], cursor_pos[2]
          
          -- Check if this is a list item
          if not is_list_item(line) then
            -- Not a list item, send a tab character
            vim.api.nvim_feedkeys(
              vim.api.nvim_replace_termcodes("<Tab>", true, false, true),
              "i", true  -- Use "i" for insert mode instead of "n"
            )
            return
          end
          
          -- Determine if we're at the beginning of content
          local prefix_length = 0
          
          -- Get bullet/indentation prefix length
          local bullet_match = line:match("^(%s*[-+*]%s+)")
          local number_match = line:match("^(%s*%d+%.%s+)")
          
          if bullet_match then
            prefix_length = #bullet_match
          elseif number_match then
            prefix_length = #number_match
          else
            prefix_length = #(line:match("^%s*") or "")
          end
          
          -- If cursor is not at beginning, insert a tab character directly
          if col > prefix_length then
            -- Get the current line
            local current_line = vim.fn.getline(".")
            
            -- Split the line at cursor position
            local before_cursor = string.sub(current_line, 1, col)
            local after_cursor = string.sub(current_line, col + 1)
            
            -- Insert a tab character at cursor position
            local new_line = before_cursor .. "\t" .. after_cursor
            
            -- Update the line
            vim.api.nvim_buf_set_lines(0, row-1, row, false, {new_line})
            
            -- Move cursor after the tab
            vim.api.nvim_win_set_cursor(0, {row, col + 1})
            
            return
          end
          
          -- We're at the beginning of a list item - indent the whole line
          local new_line = "  " .. line
          vim.api.nvim_buf_set_lines(0, row-1, row, false, {new_line})
          vim.api.nvim_win_set_cursor(0, {row, col+2})
          
          -- Recalculate list numbering
          pcall(function() auto.recalculate() end)
        end, { buffer = true, desc = "Direct Tab handling for lists" })
      end
    })
    
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
    
    -- Leaving this commented to avoid confusion with older code
    -- -- Unused helper function - removed in favor of direct <C-D> approach
    
    -- Improved Enter key handling for list creation
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
    
    -- Create a wrapper function that suppresses notifications
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
    
    -- Handle o and O keys to create bullets only for list items
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
    
    -- Rewritten Shift-Tab implementation without expression mapping
    vim.api.nvim_create_autocmd("FileType", {
      pattern = {"markdown", "norg"},
      callback = function()
        -- Map Shift-Tab key directly
        vim.keymap.set("i", "<S-Tab>", function()
          -- Get current line and cursor info
          local line = vim.fn.getline(".")
          local cursor_pos = vim.api.nvim_win_get_cursor(0)
          local row, col = cursor_pos[1], cursor_pos[2]
          
          -- If not a list item, use standard <C-D> behavior
          if not is_list_item(line) then
            vim.api.nvim_feedkeys(
              vim.api.nvim_replace_termcodes("<C-D>", true, false, true),
              "i", true  -- Use "i" for insert mode instead of "n"
            )
            return
          end
          
          -- Check if there's indentation to remove
          local indent = line:match("^%s*") or ""
          if #indent < 2 then
            -- Not enough indentation, do nothing
            return
          end
          
          -- Use standard Vim dedent and then recalculate
          vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<C-D>", true, false, true),
            "i", true  -- Use "i" for insert mode instead of "n"
          )
          
          -- Schedule recalculate to run after the <C-D> completes
          vim.defer_fn(function() 
            pcall(function() auto.recalculate() end)
          end, 20)
        end, { buffer = true, desc = "Direct Shift-Tab handling for lists" })
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
  end,
}