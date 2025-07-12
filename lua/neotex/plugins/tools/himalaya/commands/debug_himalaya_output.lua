-- Debug command to inspect raw himalaya output
local M = {}

function M.debug_himalaya_output(email_id)
  local state = require('neotex.plugins.tools.himalaya.core.state')
  local account = state.get_current_account()
  local folder = state.get_current_folder()
  
  if not account or not folder then
    vim.notify('No account or folder selected', vim.log.levels.ERROR)
    return
  end
  
  if not email_id then
    vim.notify('Please provide an email ID', vim.log.levels.ERROR)
    return
  end
  
  -- Build himalaya command
  local cmd = {
    'himalaya',
    'message', 'read',
    '-a', account,
    '-f', folder,
    '--preview',
    tostring(email_id)
  }
  
  local stdout_buffer = {}
  
  vim.fn.jobstart(cmd, {
    on_stdout = function(_, data, _)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stdout_buffer, line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code, _)
      if exit_code == 0 and #stdout_buffer > 0 then
        local output = table.concat(stdout_buffer, '\n')
        
        -- Create a new buffer to show the raw output
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
        vim.api.nvim_buf_set_option(buf, 'filetype', 'text')
        
        -- Add debug info
        local lines = {
          "=== HIMALAYA RAW OUTPUT DEBUG ===",
          "Email ID: " .. email_id,
          "Account: " .. account,
          "Folder: " .. folder,
          "Output length: " .. #output,
          "",
          "=== HEADER ANALYSIS ===",
          "Subject: count = " .. select(2, output:gsub("Subject:", "")),
          "From: count = " .. select(2, output:gsub("From:", "")),
          "Dashes line found: " .. tostring(output:find("\n%-+\n") ~= nil),
          "",
          "=== FIRST 1000 CHARACTERS ===",
          output:sub(1, 1000),
          "",
          "=== FULL OUTPUT ===",
        }
        
        -- Add the full output
        local output_lines = vim.split(output, '\n', { plain = true })
        for i, line in ipairs(output_lines) do
          table.insert(lines, string.format("%4d: %s", i, line))
        end
        
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        
        -- Open in a new window
        vim.cmd('split')
        vim.api.nvim_set_current_buf(buf)
      else
        vim.notify('Failed to get himalaya output: exit code ' .. exit_code, vim.log.levels.ERROR)
      end
    end
  })
end

return M