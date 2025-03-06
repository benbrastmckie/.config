return {
  'tzachar/local-highlight.nvim',
  config = function()
    require('local-highlight').setup({
      disable_file_types = { 'NvimTree', 'TelescopePrompt' },
      hlgroup = 'Pmenu',
      cw_hlgroup = nil,
      insert_mode = false,
      min_match_len = 1,
      max_match_len = 100,
      max_line_len = 400,
      -- Add these options to make it more stable
      max_matches = 100,
      modes = { 'n' }, -- only activate in normal mode
      priority = -1,   -- lower priority than other highlights
    })

    -- Add autocmd to prevent highlighting in certain buffer types
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter' }, {
      callback = function()
        local buftype = vim.bo.buftype
        if buftype ~= '' and buftype ~= 'acwrite' then
          vim.b.local_highlight_enabled = false
        end
      end,
    })
  end,
  event = 'BufRead',
}
