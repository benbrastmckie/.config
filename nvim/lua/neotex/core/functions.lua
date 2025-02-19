-- Fine all instances of a word in a project with telescope
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
      table.insert(normal_buffers, buf)
    else
      table.insert(fixed_buffers, buf)
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

-- -- Buffer deletion with proper cleanup for Lean files
-- function BufDelete()
--   -- Save any changes
--   vim.cmd('update!')
--
--   -- Get current buffer number
--   local bufnr = vim.api.nvim_get_current_buf()
--
--   -- Force stop any LSP clients for this buffer
--   for _, client in pairs(vim.lsp.get_clients({ bufnr = bufnr })) do
--     pcall(client.stop)
--   end
--
--   -- Use vim.schedule to ensure we're in the main thread
--   vim.schedule(function()
--     -- Delete the buffer using Snacks.bufdelete
--     vim.cmd('lua Snacks.bufdelete()')
--   end)
-- end

-- -- Buffer deletion with proper cleanup for Lean files
-- function BufDelete()
--   -- Save any changes
--   vim.cmd('update!')
--
--   -- Delete the buffer using Snacks.bufdelete
--   -- The cleanup will be handled by the BufDelete autocmd
--   vim.cmd('lua Snacks.bufdelete()')
-- end

-- -- Buffer deletion with proper cleanup for Lean files
-- function BufDelete()
--   -- Save any changes
--   vim.cmd('update!')
--
--   -- Cleanup infoview if it's a Lean file
--   if vim.bo.filetype == 'lean' then
--     local status, infoview = pcall(require('lean.infoview').get_current_infoview)
--     if status and infoview then
--       -- Stop updating and clean up the infoview
--       infoview:stop_auto_updating()
--       infoview:hide()
--       infoview:cleanup()
--     end
--   end
--
--   -- Delete the buffer
--   vim.cmd('lua Snacks.bufdelete()')
-- end
