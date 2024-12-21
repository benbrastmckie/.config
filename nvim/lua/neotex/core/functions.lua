function SearchWordUnderCursor()
    local word = vim.fn.expand('<cword>')
    require('telescope.builtin').live_grep({ default_text = word })
end

function CloseBuffer()
  local current = vim.api.nvim_get_current_buf()
  vim.cmd('bdelete')  -- Close the current buffer

  -- Get a list of all listed buffers
  local buffers = vim.api.nvim_list_bufs()
  for _, buf in ipairs(buffers) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
      vim.api.nvim_set_current_buf(buf)
      break
    end
  end
end
