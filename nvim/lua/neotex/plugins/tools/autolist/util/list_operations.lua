-- Autolist core operations module
local M = {}
local utils = require("neotex.plugins.tools.autolist.util.utils")
local auto = nil

-- Will be set during initialization
local function init_auto()
  if not auto then
    auto = require("autolist.auto")
  end
end

-- Handler for Indenting list items in insert mode via Tab
function M.tab_handler()
  -- Check if we're in a list item first
  local line = vim.fn.getline(".")
  
  if utils.is_list_item(line) then
    -- Close completion menu if open
    local cmp_exists, cmp = pcall(require, "cmp")
    if cmp_exists and cmp.visible() then
      pcall(function() cmp.close() end)
    end
    
    -- If we're in a list, use our indent function
    M.indent_list_item()
    return ""
  end
  
  -- If we're not in a list item, handle normally
  local cmp_exists, cmp = pcall(require, "cmp")
  if cmp_exists and cmp.visible() then
    return vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
  end
  
  -- If we just used Tab for indentation, don't trigger cmp
  if _G._last_tab_was_indent then
    _G._last_tab_was_indent = false
    return vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
  end
  
  -- Standard tab behavior for non-list items
  return vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
end

-- Handler for Unindenting list items in insert mode via Shift-Tab
function M.shift_tab_handler()
  -- Check if we're in a list item first
  local line = vim.fn.getline(".")
  
  if utils.is_list_item(line) then
    -- Close completion menu if open
    local cmp_exists, cmp = pcall(require, "cmp")
    if cmp_exists and cmp.visible() then
      pcall(function() cmp.close() end)
    end
    
    -- If we're in a list, use our unindent function
    M.unindent_list_item()
    return ""
  end
  
  -- If we're not in a list item, handle normally
  local cmp_exists, cmp = pcall(require, "cmp")
  if cmp_exists and cmp.visible() then
    return vim.api.nvim_replace_termcodes("<S-Tab>", true, true, true)
  end
  
  -- Standard Shift-Tab behavior
  return vim.api.nvim_replace_termcodes("<C-D>", true, true, true)
end

-- Handler for Enter key in insert mode
function M.enter_handler()
  local line = vim.fn.getline(".")
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local col = cursor_pos[2]
  
  -- For lines ending with colon, just create a normal new line
  if col == #line and line:match(":$") then
    return "\n"
  end
  
  -- If we're in a list item
  if utils.is_list_item(line) then
    -- For empty list items, delete them
    if line:match("^%s*[-+*]%s+$") or line:match("^%s*%d+%.%s+$") then
      return "<C-u><CR>"
    end
    
    -- Ensure the cursor is at the end of the line to trigger bullet creation
    if col < #line then
      return "<CR>"
    end
    
    -- Let autolist handle creating the next bullet
    return vim.api.nvim_replace_termcodes("<CR>", true, true, true)
  end
  
  -- Not a list item - use standard Enter behavior
  return "<CR>"
end

-- Implementation functions (called by the handlers or commands)

-- Indent a list item, maintaining cursor position
function M.indent_list_item()
  init_auto()
  
  -- Get current state
  local line = vim.fn.getline(".")
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor_pos[1], cursor_pos[2]
  
  -- Close any open completion menu first
  utils.close_completion_menu()
  
  -- Determine if we're on a list item
  if not utils.is_list_item(line) then
    -- Not on a list item, use default Tab behavior
    -- Reset our flags
    _G._last_tab_was_indent = false
    _G._prevent_cmp_menu = false
    
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<Tab>", true, true, true),
      'n', true
    )
    return
  end
  
  -- Set flags
  _G._last_tab_was_indent = true
  _G._prevent_cmp_menu = true
  
  -- Clear the flag after a short delay
  vim.defer_fn(function()
    _G._last_tab_was_indent = false
  end, 300)
  
  -- Schedule text modification for next event cycle
  vim.schedule(function()
    -- Get indent size
    local indent_size = vim.bo.shiftwidth
    
    -- Add indentation to the entire line
    local current_line = vim.api.nvim_get_current_line()
    local indented_line = string.rep(" ", indent_size) .. current_line
    
    -- Set the new line content
    local success = pcall(function() vim.api.nvim_set_current_line(indented_line) end)
    
    if not success then
      -- Alternative approach for failed direct modification
      vim.schedule(function()
        local keys = vim.api.nvim_replace_termcodes("<Esc>>>gi", true, true, true)
        vim.api.nvim_feedkeys(keys, 'n', true)
      end)
      return
    end
    
    -- Recalculate list
    utils.silent_exec(function()
      if auto and auto.recalculate then
        auto.recalculate()
      end
    end)
    
    -- Update cursor position
    local new_col = col + indent_size
    pcall(function() vim.api.nvim_win_set_cursor(0, {row, new_col}) end)
    
    -- Ensure we stay in insert mode
    if vim.api.nvim_get_mode().mode ~= "i" then
      vim.cmd("startinsert")
    end
    
    -- Close completion menu again with longer delay
    utils.close_completion_menu(1000)
  end)
end

-- Unindent a list item, maintaining cursor position
function M.unindent_list_item()
  init_auto()
  
  -- Get current state
  local line = vim.fn.getline(".")
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor_pos[1], cursor_pos[2]
  
  -- Close any open completion menu first
  utils.close_completion_menu()
  
  -- Determine if we're on a list item
  if not utils.is_list_item(line) then
    -- Not on a list item, use default Shift-Tab behavior
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<C-D>", true, true, true),
      'n', true
    )
    return
  end
  
  -- Set flag to prevent cmp menu from opening
  _G._prevent_cmp_menu = true
  
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
  utils.silent_exec(function()
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
  
  -- Close any open completion menu again to be sure
  utils.close_completion_menu(1000)
end

-- Increment checkbox state in a list item
function M.toggle_checkbox()
  local current_line = vim.fn.line(".")
  local line = vim.fn.getline(current_line)
  
  -- Skip if not a list item
  if not utils.is_list_item(line) then
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
  
  -- Forward cycle: None -> Empty -> Progress -> Closing -> Done -> None
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

-- Decrement checkbox state in a list item
function M.toggle_checkbox_reverse()
  local current_line = vim.fn.line(".")
  local line = vim.fn.getline(current_line)
  
  -- Skip if not a list item
  if not utils.is_list_item(line) then
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
  
  -- Reverse cycle: None -> Done -> Closing -> Progress -> Empty -> None
  if line:match("%[x%]") then
    -- Done → Closing
    new_line = line:gsub("%[x%]", "[:]", 1)
  elseif line:match("%[%:%]") then
    -- Closing → Progress
    new_line = line:gsub("%[%:%]", "[.]", 1)
  elseif line:match("%[%.%]") then
    -- Progress → Empty
    new_line = line:gsub("%[%.%]", "[ ]", 1)
  elseif line:match("%[%s%]") then
    -- Empty → No checkbox
    local with_box = list_marker .. " [ ]"
    local without_box = list_marker
    new_line = line:gsub(vim.pesc(with_box), without_box, 1)
  else
    -- No checkbox → Done
    -- Escape special characters in marker
    local escaped_marker = vim.pesc(list_marker)
    -- Add checkbox after marker
    new_line = line:gsub(escaped_marker .. "%s+", escaped_marker .. patterns.done .. " ", 1)
  end
  
  -- Update the line with new content
  vim.fn.setline(current_line, new_line)
end

-- Recalculate list numbering
function M.recalculate_list()
  init_auto()
  utils.silent_exec(function()
    if auto and auto.recalculate then
      auto.recalculate()
    end
  end)
end

-- Cycle to next bullet type
function M.cycle_next()
  init_auto()
  utils.silent_exec(function()
    if auto and auto.cycle_next then
      auto.cycle_next()
    end
  end)
end

-- Cycle to previous bullet type
function M.cycle_prev()
  init_auto()
  utils.silent_exec(function()
    if auto and auto.cycle_prev then
      auto.cycle_prev()
    end
  end)
end

return M