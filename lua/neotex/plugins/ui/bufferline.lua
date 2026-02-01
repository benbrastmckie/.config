-- Find a suitable window for buffer operations (one without winfixbuf)
-- Returns the window ID or nil if none found
local function find_suitable_window()
  local current_win = vim.api.nvim_get_current_win()

  -- If current window is suitable, use it
  if not vim.wo[current_win].winfixbuf then
    return current_win
  end

  -- Find another window without winfixbuf
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local buftype = vim.bo[buf].buftype
    -- Skip terminals, floating windows, and winfixbuf windows
    if buftype ~= "terminal"
       and not vim.wo[win].winfixbuf
       and vim.api.nvim_win_get_config(win).relative == "" then
      return win
    end
  end

  return nil
end

-- Smart buffer switch that handles winfixbuf windows
-- Used for clicking on bufferline tabs when in a terminal/sidebar
local function smart_buffer_switch(bufnr)
  local target_win = find_suitable_window()

  if target_win then
    -- Switch to the suitable window first
    vim.api.nvim_set_current_win(target_win)
    -- Then switch buffer
    vim.api.nvim_set_current_buf(bufnr)
  else
    -- Fallback: try direct switch (may fail if no suitable window)
    pcall(vim.api.nvim_set_current_buf, bufnr)
  end
end

-- Make it globally available for bufferline
_G.smart_buffer_switch = smart_buffer_switch

-- Smart buffer deletion that prevents switching to sidebar buffers (Claude, terminals)
-- Pre-selects next buffer BEFORE deletion to avoid Neovim's jump list selection
local function smart_bufdelete(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Find a suitable next buffer: must be listed and a normal file
  local current_win = vim.api.nvim_get_current_win()
  local next_buf = nil

  -- Get all listed buffers
  local buffers = vim.fn.getbufinfo({ buflisted = 1 })

  -- Filter to valid targets (not current, not terminal, is loaded)
  local valid_buffers = {}
  for _, buf in ipairs(buffers) do
    if buf.bufnr ~= bufnr and vim.bo[buf.bufnr].buftype == "" then
      table.insert(valid_buffers, buf)
    end
  end

  -- Sort by lastused (most recent first)
  table.sort(valid_buffers, function(a, b)
    return (a.lastused or 0) > (b.lastused or 0)
  end)

  if #valid_buffers > 0 then
    next_buf = valid_buffers[1].bufnr
  else
    -- No other buffers - create a new empty buffer
    next_buf = vim.api.nvim_create_buf(true, false)
  end

  -- Switch to next buffer FIRST (prevents Neovim from selecting Claude)
  vim.api.nvim_win_set_buf(current_win, next_buf)

  -- Now delete the original buffer
  vim.api.nvim_buf_delete(bufnr, { force = true })
end

-- Make it globally available for bufferline
_G.smart_bufdelete = smart_bufdelete

return {
  "akinsho/bufferline.nvim",
  lazy = true,
  event = "BufAdd", -- Only load when multiple buffers exist
  dependencies = { "nvim-tree/nvim-web-devicons" },
  version = "*",
  init = function()
    -- Hide the tabline completely at startup
    vim.opt.showtabline = 0
    
    -- Create an autocmd that will only show tabline when we have more than 1 buffer
    vim.api.nvim_create_autocmd("BufAdd", {
      callback = function()
        local buffers = vim.fn.getbufinfo({buflisted = 1})
        if #buffers > 1 then
          vim.opt.showtabline = 2
        end
      end,
      desc = "Show bufferline when multiple buffers exist"
    })
  end,
  config = function()
    -- Simple initial setup with minimal features
    local bufferline = require('bufferline')
    bufferline.setup({
      options = {
        mode = "buffers",
        always_show_bufferline = false, -- Only show when more than one buffer
        diagnostics = false, -- Disable diagnostics integration initially
        diagnostics_update_in_insert = false,
        show_tab_indicators = false,
        show_close_icon = false,
        -- Handle clicks from winfixbuf windows (e.g., Claude terminal sidebar)
        left_mouse_command = function(bufnr)
          smart_buffer_switch(bufnr)
        end,
        -- Simple filter to exclude quickfix windows and claude-code terminals
        custom_filter = function(buf_number, buf_numbers)
          local buf_ft = vim.bo[buf_number].filetype
          local buf_name = vim.api.nvim_buf_get_name(buf_number)
          -- Exclude quickfix windows
          if buf_ft == "qf" then
            return false
          end
          -- Exclude claude-code terminal buffers
          if string.match(buf_name, "claude%-code") then
            return false
          end
          return true
        end
      }
    })
    
    -- Set up autocmd for quickfix windows immediately
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "qf",
      callback = function()
        vim.opt_local.buflisted = false
        vim.opt_local.bufhidden = "wipe"
      end,
    })
    
    -- Enhanced tabline visibility management
    -- Define function and register autocmds BEFORE defer_fn to catch session restore
    -- This eliminates timing race condition during session loading
    local function ensure_tabline_visible()
      local buffers = vim.fn.getbufinfo({buflisted = 1})
      if #buffers > 1 then
        vim.opt.showtabline = 2
      elseif #buffers <= 1 then
        vim.opt.showtabline = 0
      end
    end

    -- Register critical autocmds IMMEDIATELY (before defer_fn)
    -- This ensures visibility management is active during session restoration
    vim.api.nvim_create_autocmd({"BufEnter", "WinEnter", "SessionLoadPost"}, {
      callback = function()
        local filetype = vim.bo.filetype

        -- Don't show tabline on alpha dashboard
        if filetype == "alpha" then
          vim.opt.showtabline = 0
          return
        end

        -- Update tabline visibility based on buffer count
        ensure_tabline_visible()
      end,
      desc = "Preserve bufferline visibility across window switches and session restore"
    })

    -- Restore tabline visibility when leaving terminal
    vim.api.nvim_create_autocmd("TermLeave", {
      pattern = "*",
      callback = function()
        vim.defer_fn(ensure_tabline_visible, 10)
      end,
      desc = "Restore bufferline when leaving terminal"
    })

    -- Update tabline visibility when buffers are deleted
    vim.api.nvim_create_autocmd("BufDelete", {
      callback = function()
        vim.defer_fn(ensure_tabline_visible, 10)
      end,
      desc = "Update bufferline visibility on buffer deletion"
    })

    -- Defer loading the full bufferline configuration (keeps startup smooth)
    vim.defer_fn(function()
      bufferline.setup({
        options = {
          mode = "buffers",
          custom_filter = function(buf_number, buf_numbers)
            -- filter out quickfix buffers and claude-code terminals
            local buf_ft = vim.bo[buf_number].filetype
            local buf_name = vim.api.nvim_buf_get_name(buf_number)
            if buf_ft == "qf" then -- qf is the filetype for quickfix windows
              return false
            end
            -- Exclude claude-code terminal buffers
            if string.match(buf_name, "claude%-code") then
              return false
            end
            return true
          end,
          separator_style = "slant",
          left_mouse_command = function(bufnr)
            smart_buffer_switch(bufnr)
          end,
          close_command = function(bufnr)
            smart_bufdelete(bufnr)
          end,
          right_mouse_command = function(bufnr)
            smart_bufdelete(bufnr)
          end,
          diagnostics = false,
          diagnostics_update_in_insert = false,
          show_tab_indicators = false,
          show_close_icon = false,
          sort_by = function(buffer_a, buffer_b)
            -- add custom logic
            local modified_a = vim.fn.getftime(buffer_a.path)
            local modified_b = vim.fn.getftime(buffer_b.path)
            return modified_a > modified_b
          end,
          offsets = {
            {
              filetype = "neo-tree",
              text = function()
                return vim.fn.getcwd()
              end,
              highlight = "BufferLineFill",
              text_align = "left",
              separator = "",
            }
          },
          hover = {
            enabled = true,
            delay = 30,
            reveal = { 'close' }
          },
        },
      })

      -- Set up alpha integration after full config is loaded
      vim.api.nvim_create_autocmd("User", {
        pattern = "AlphaReady",
        desc = "disable tabline for alpha",
        callback = function()
          vim.opt.showtabline = 0
        end,
      })

      vim.api.nvim_create_autocmd("BufUnload", {
        buffer = 0,
        desc = "enable tabline after alpha",
        callback = function()
          vim.opt.showtabline = 2
        end,
      })
    end, 200)
  end,
}
