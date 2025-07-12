# Draft Save Implementation - Based on himalaya-vim Analysis

## Key Findings from himalaya-vim

The himalaya-vim plugin uses a much simpler approach that we should adopt:

1. **BufWriteCmd**: Intercepts `:w` to save the entire buffer content locally
2. **Template commands**: Uses `himalaya template save` to save complete email to server
3. **No field parsing during save**: The entire buffer is saved as-is
4. **Draft identity**: Drafts are managed by himalaya CLI, not local IDs

## Current Implementation Issues

Our implementation is over-engineered and has these problems:

1. **Premature parsing**: We parse headers/body on every save, which can lose content
2. **Complex state management**: Multiple layers of draft objects, storage, and sync
3. **Field extraction timing**: We extract fields too early, before content is complete
4. **Buffer save confusion**: `:w` saves the .eml file but doesn't update the draft properly

## Recommended Implementation (Following himalaya-vim Pattern)

### 1. Simplify Save Flow

**Replace current save_draft function with**:
```lua
function M.save_draft(buf, trigger)
  local draft = draft_manager.get_by_buffer(buf)
  if not draft then
    return false, "No draft associated with buffer"
  end
  
  -- Get the ENTIRE buffer content as-is
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, '\n')
  
  -- Save to .eml file (for :w behavior)
  vim.api.nvim_buf_call(buf, function()
    vim.cmd('silent write!')
  end)
  
  -- Save complete content to draft storage
  local storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  local ok, err = storage.save(draft.local_id, {
    content = content,  -- Save ENTIRE content, don't parse yet
    account = draft.account,
    remote_id = draft.remote_id,
    -- Parse metadata only for display purposes
    metadata = M.parse_headers_for_display(lines)
  })
  
  if not ok then
    return false, err
  end
  
  -- Mark buffer as unmodified
  vim.api.nvim_buf_set_option(buf, 'modified', false)
  
  -- Queue remote sync if we have a remote_id
  if draft.remote_id then
    vim.defer_fn(function()
      M.sync_draft_to_remote(draft, content)
    end, 100)
  end
  
  -- Update UI
  M.update_ui_after_save(draft)
  
  return true
end
```

### 2. Parse Headers Only for Display

**Add helper function**:
```lua
function M.parse_headers_for_display(lines)
  local headers = {}
  local in_headers = true
  
  for _, line in ipairs(lines) do
    if line == '' then
      break  -- End of headers
    end
    local key, value = line:match('^([^:]+):%s*(.*)$')
    if key then
      headers[key:lower()] = value
    end
  end
  
  return {
    from = headers.from or '',
    to = headers.to or '',
    subject = headers.subject or '',
    cc = headers.cc or '',
    bcc = headers.bcc or ''
  }
end
```

### 3. Use himalaya template save for Remote Sync

**Add sync function**:
```lua
function M.sync_draft_to_remote(draft, content)
  -- Create temp file with content
  local tmpfile = vim.fn.tempname()
  vim.fn.writefile(vim.split(content, '\n'), tmpfile)
  
  -- Use himalaya template save command
  local cmd = string.format(
    'himalaya template save --account %s --folder Drafts < %s',
    vim.fn.shellescape(draft.account),
    vim.fn.shellescape(tmpfile)
  )
  
  vim.fn.jobstart(cmd, {
    on_exit = function(_, exit_code)
      vim.fn.delete(tmpfile)
      if exit_code == 0 then
        -- Update remote_id if this was first sync
        if not draft.remote_id then
          -- Parse output to get new remote_id
          M.update_draft_remote_id(draft)
        end
      end
    end
  })
end
```

### 4. Load Draft Without Parsing

**Update open_draft**:
```lua
function M.open_draft(draft_id, account)
  -- Load raw content from storage or himalaya
  local content = M.load_draft_content(draft_id, account)
  if not content then
    return nil
  end
  
  -- Create buffer and set content as-is
  local buf = vim.api.nvim_create_buf(true, false)
  local lines = vim.split(content, '\n')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Set up buffer (rest remains the same)
  -- ...
end
```

### 5. Fix BufWriteCmd Behavior

**Add to buffer setup**:
```lua
-- Override default write behavior
vim.api.nvim_create_autocmd('BufWriteCmd', {
  buffer = buf,
  callback = function()
    M.save_draft(buf, 'write_cmd')
    -- Prevent default write
    return true
  end
})
```

## Benefits of This Approach

1. **Content Preservation**: No parsing means no content loss
2. **Simpler Code**: Remove complex metadata extraction during save
3. **Better :w behavior**: Works like users expect from himalaya-vim
4. **Reliable Sync**: Uses himalaya's own template system
5. **Consistent State**: Draft content is always what's in the buffer

## Migration Steps

1. Update save_draft to save complete buffer content
2. Move metadata parsing to display-only functions  
3. Update storage to handle raw content
4. Add himalaya template save integration
5. Simplify draft state management
6. Test with various email formats

## Testing Checklist

- [ ] `:w` saves entire buffer content
- [ ] Content is preserved exactly as typed
- [ ] Drafts sync to remote using himalaya template save
- [ ] Preview shows updated content after save
- [ ] Sidebar shows updated subject after save
- [ ] Reopened drafts have exact same content
- [ ] No content loss with complex formatting
- [ ] Multi-line headers are preserved
- [ ] Attachments markers are preserved