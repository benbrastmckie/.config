-- Neo-tree width persistence module
-- Provides clean width management for Neo-tree using file-based persistence

local M = {}

-- Configuration
M.width_file = vim.fn.stdpath("data") .. "/neotree_width"
M.default_width = 30
M.current_width = M.default_width

-- Load width from persistence file
function M.load_width()
  if vim.fn.filereadable(M.width_file) == 1 then
    local content = vim.fn.readfile(M.width_file)
    if content and content[1] then
      local width = tonumber(content[1])
      if width and width > 10 and width < 100 then
        M.current_width = width
        return width
      end
    end
  end
  return M.default_width
end

-- Save width to persistence file
function M.save_width(width)
  if width and width > 10 and width < 100 then
    M.current_width = width
    pcall(function()
      vim.fn.writefile({ tostring(width) }, M.width_file)
    end)
  end
end

-- Find the Neo-tree window
function M.find_neotree_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "neo-tree" then
      return win
    end
  end
  return nil
end

-- Apply saved width to Neo-tree window
function M.apply_width(width)
  local win = M.find_neotree_window()
  if win then
    local target_width = width or M.current_width
    pcall(function()
      vim.api.nvim_win_set_width(win, target_width)
    end)
  end
end

-- Track and save width changes
function M.track_width_change()
  local win = M.find_neotree_window()
  if win then
    local new_width = vim.api.nvim_win_get_width(win)
    if new_width ~= M.current_width and new_width > 10 and new_width < 100 then
      M.save_width(new_width)
    end
  end
end

-- Get current width
function M.get_width()
  return M.current_width
end

return M