return {
  "gaoDean/autolist.nvim",
  filetype = {
    "markdown",
    "norg",
  },
  config = function()
    local autolist = require('autolist')
    
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
      cycle_kinds = {"1.", "-", "*", "+"},  -- Cycle between these list types
      smart_indent = true,      -- Enable smart indentation
    })
    
    -- Safe way to access autolist.auto after setup
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
    
    -- Helper function to unindent list item with proper error handling
    local function unindent_list_item()
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      local line_num = cursor_pos[1]
      local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
      
      if is_list_item(line) then
        -- Remove one level of indentation (2 spaces or 1 tab)
        local new_line = line
        local new_col = cursor_pos[2]
        
        if line:match("^%s%s") then
          -- Remove 2 spaces
          new_line = line:gsub("^  ", "")
          new_col = math.max(0, cursor_pos[2] - 2)
        elseif line:match("^\t") then
          -- Remove 1 tab
          new_line = line:gsub("^\t", "")
          new_col = math.max(0, cursor_pos[2] - 1)
        else
          -- No indentation to remove
          return false
        end
        
        -- Update the line
        vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, {new_line})
        
        -- Adjust cursor position
        vim.api.nvim_win_set_cursor(0, {line_num, new_col})
        
        -- Recalculate list with proper error handling
        pcall(function() 
          auto.recalculate()
        end)
        
        return true
      end
      
      return false
    end
    
    -- Handle colon lines separately with a dedicated autocmd
    vim.api.nvim_create_autocmd("InsertEnter", {
      pattern = {"*.md", "*.markdown", "*.norg"},
      callback = function()
        -- Store original CR mapping
        local orig_cr_map = vim.fn.maparg("<CR>", "i", false, true)
        
        -- Create a new mapping for <CR> that checks for colon
        vim.keymap.set("i", "<CR>", function()
          local line = vim.fn.getline(".")
          local cursor_pos = vim.api.nvim_win_get_cursor(0)
          local col = cursor_pos[2]
          
          -- Check if the cursor is at the end of the line and it ends with a colon
          if col == #line and line:match(":$") then
            -- Insert a simple new line without auto-indentation
            return "\n"
          else
            -- Use original <CR> behavior
            if not vim.tbl_isempty(orig_cr_map) and orig_cr_map.expr == 1 then
              -- If original mapping was expression-based
              return vim.fn.eval(orig_cr_map.rhs)
            else
              -- Default behavior, let autolist handle it
              return "<CR>"
            end
          end
        end, { expr = true, buffer = true })
      end
    })
    
    -- Configure autolist to ignore lines ending with colon when creating new lines
    -- We're going to take a more direct approach by modifying the plugin's core behavior
    local autolist_config = require("autolist.config")
    
    -- Override the 'colon' configuration to set indent to false
    -- This ensures autolist does not create indented lists after lines ending with ':'
    if autolist_config.colon then
      autolist_config.colon.indent = false
      autolist_config.colon.indent_raw = false
    end
    
    -- Manually handle 'o' and 'O' for colon lines
    vim.api.nvim_create_autocmd("FileType", {
      pattern = {"markdown", "norg"},
      callback = function(ev)
        -- Create custom o/O mappings that check for colon at the end of line
        for _, key in ipairs({"o", "O"}) do
          vim.keymap.set("n", key, function()
            local line = vim.fn.getline(".")
            
            -- If the line ends with a colon, disable autolist temporarily
            if line:match(":$") then
              -- Store current state
              local prev_enabled = vim.b[ev.buf].autolist_enabled
              
              -- Disable autolist
              vim.b[ev.buf].autolist_enabled = false
              
              -- Create a function to restore state after operation
              vim.defer_fn(function()
                vim.b[ev.buf].autolist_enabled = prev_enabled
              end, 100)
              
              -- Execute the appropriate key based on o or O
              if key == "o" then
                vim.cmd("normal! o")
              else
                vim.cmd("normal! O")
              end
              
              return ""
            else
              -- Let normal behavior take over for non-colon lines
              return key
            end
          end, { expr = true, buffer = true, desc = "Smart o/O for list items" })
        end
      end
    })
    
    -- Improved <S-Tab> functionality for list items
    vim.api.nvim_create_autocmd("FileType", {
      pattern = {"markdown", "norg"},
      callback = function()
        vim.keymap.set("i", "<S-Tab>", function()
          -- Get current cursor position and line
          local cursor_pos = vim.api.nvim_win_get_cursor(0)
          local line_num = cursor_pos[1]
          local col = cursor_pos[2]
          local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
          
          -- For list items, manually handle unindentation
          if is_list_item(line) then
            -- Determine indentation type and amount
            local indentation = line:match("^%s+") or ""
            local new_line
            local new_col = col
            
            if #indentation >= 2 then
              -- Remove 2 spaces or 1 tab from the beginning
              if indentation:sub(1, 2) == "  " then
                new_line = line:sub(3) -- Remove 2 spaces
                new_col = math.max(0, col - 2)
              elseif indentation:sub(1, 1) == "\t" then
                new_line = line:sub(2) -- Remove 1 tab
                new_col = math.max(0, col - 1)
              else
                -- For mixed indentation, try to handle gracefully
                new_line = line:sub(2) -- Remove 1 character
                new_col = math.max(0, col - 1)
              end
              
              -- Update the line
              vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, {new_line})
              
              -- Adjust cursor position
              vim.api.nvim_win_set_cursor(0, {line_num, new_col})
              
              -- Silently recalculate lists if needed
              pcall(function() auto.recalculate() end)
              
              return
            end
          end
          
          -- Use standard CTRL-D behavior for non-list items or no more indentation
          local keys = vim.api.nvim_replace_termcodes("<C-d>", true, false, true)
          vim.api.nvim_feedkeys(keys, "n", false)
        end, { buffer = true, desc = "Unindent list item in insert mode" })
      end
    })
    
    -- Add commands for integration with which-key mappings with proper error handling
    vim.api.nvim_create_user_command('AutolistRecalculate', function()
      local success, err = pcall(function()
        auto.recalculate()
      end)
      
      if success then
        vim.notify("List numbers recalculated", vim.log.levels.INFO)
      else
        vim.notify("Failed to recalculate list: " .. tostring(err), vim.log.levels.ERROR)
      end
    end, {})
    
    vim.api.nvim_create_user_command('AutolistCycleNext', function()
      local success, err = pcall(function()
        auto.cycle_next()
      end)
      
      if success then
        vim.notify("Cycled to next bullet type", vim.log.levels.INFO)
      else
        vim.notify("Failed to cycle bullet: " .. tostring(err), vim.log.levels.ERROR)
      end
    end, {})
    
    vim.api.nvim_create_user_command('AutolistCyclePrev', function()
      local success, err = pcall(function()
        auto.cycle_prev()
      end)
      
      if success then
        vim.notify("Cycled to previous bullet type", vim.log.levels.INFO)
      else
        vim.notify("Failed to cycle bullet: " .. tostring(err), vim.log.levels.ERROR)
      end
    end, {})
    
    -- Create checkbox functionality
    function HandleCheckbox()
      local config = require("autolist.config")
      local emptybox_pattern = " [ ]"
      local progbox_pattern = " [.]"
      local closebox_pattern = " [:]"
      local donebox_pattern = " [x]"
      local filetype_list = config.lists[vim.bo.filetype]
      local line = vim.fn.getline(".")
      
      for i, list_pattern in ipairs(filetype_list) do
        local list_item = line:match("^%s*" .. list_pattern .. "%s*")
        
        if list_item == nil then goto continue_for_loop end
        list_item = list_item:gsub("%s+", "")
        
        local is_list_item = list_item ~= nil
        local is_checkbox_item = line:match("^%s*" .. list_pattern .. "%s*" .. "%[.%]" .. "%s*") ~= nil
        local is_emptybox_item = line:match("^%s*" .. list_pattern .. "%s*" .. "%[%s%]" .. "%s*") ~= nil
        local is_progbox_item = line:match("^%s*" .. list_pattern .. "%s*" .. "%[%.%]" .. "%s*") ~= nil
        local is_closebox_item = line:match("^%s*" .. list_pattern .. "%s*" .. "%[%:%]" .. "%s*") ~= nil
        local is_donebox_item = line:match("^%s*" .. list_pattern .. "%s*" .. "%[x%]" .. "%s*") ~= nil
        
        if is_list_item == true and is_checkbox_item == false then
          list_item = list_item:gsub('%)', '%%)')
          vim.fn.setline(".", (line:gsub(list_item, list_item .. emptybox_pattern, 1)))
          
          local cursor_pos = vim.api.nvim_win_get_cursor(0)
          if cursor_pos[2] > 0 then
            vim.api.nvim_win_set_cursor(0, { cursor_pos[1], cursor_pos[2] + emptybox_pattern:len() })
          end
          goto continue
        elseif is_list_item == true and is_emptybox_item == true then
          list_item = list_item:gsub('%)', '%%)')
          vim.fn.setline(".", (line:gsub(" %[%s%]", progbox_pattern, 1)))
          goto continue
        elseif is_list_item == true and is_progbox_item == true then
          list_item = list_item:gsub('%)', '%%)')
          vim.fn.setline(".", (line:gsub(" %[%.%]", closebox_pattern, 1)))
          goto continue
        elseif is_list_item == true and is_closebox_item == true then
          list_item = list_item:gsub('%)', '%%)')
          vim.fn.setline(".", (line:gsub(" %[%:%]", donebox_pattern, 1)))
          goto continue
        elseif is_list_item == true and is_donebox_item == true then
          list_item = list_item:gsub('%)', '%%)')
          vim.fn.setline(".", (line:gsub(" %[x%]", "", 1)))
          
          local cursor_pos = vim.api.nvim_win_get_cursor(0)
          if cursor_pos[2] > donebox_pattern:len() then
            vim.api.nvim_win_set_cursor(0, { cursor_pos[1], cursor_pos[2] - donebox_pattern:len() })
          end
          goto continue
        else
          -- Simple toggle for vanilla checkboxes
          pcall(function()
            auto.toggle_checkbox()
          end)
          goto continue
        end
        ::continue_for_loop::
      end
      ::continue::
    end
  end,
}