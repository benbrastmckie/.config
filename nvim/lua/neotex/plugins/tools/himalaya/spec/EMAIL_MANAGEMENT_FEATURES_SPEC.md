# Himalaya Email Management Features Specification

This specification details the implementation plan for email management features identified in the technical debt analysis and features specification, focusing on core email functionality enhancements.

## Overview

The email management features enhance the core functionality of the Himalaya email client, adding essential features like attachment support, image display, address autocomplete, and advanced email operations.

## Feature Implementation Details

### 1. Attachment Support

**Priority**: High  
**Estimated Effort**: 1 week

#### 1.1 Core Attachment Module

Create `core/attachments.lua`:

```lua
local M = {}
local notify = require('neotex.util.notifications')
local utils = require('neotex.plugins.tools.himalaya.utils')

-- Attachment metadata structure
local attachment_schema = {
  id = "",              -- Unique identifier
  filename = "",        -- Original filename
  content_type = "",    -- MIME type
  size = 0,            -- Size in bytes
  content_id = "",     -- For inline attachments
  disposition = "",    -- inline or attachment
  cached_path = nil    -- Local cache path
}

function M.list_attachments(email_id)
  -- Parse email to extract attachment metadata
  local cmd = string.format("himalaya message read %s --format json", email_id)
  local result = utils.execute_command(cmd)
  
  if not result.success then
    return nil, result.error
  end
  
  local email = vim.json.decode(result.output)
  local attachments = {}
  
  -- Parse multipart message for attachments
  if email.parts then
    for _, part in ipairs(email.parts) do
      if part.disposition and part.disposition:match("attachment") then
        table.insert(attachments, {
          id = part.id,
          filename = part.filename or "unnamed",
          content_type = part.content_type,
          size = part.size,
          content_id = part.content_id,
          disposition = part.disposition
        })
      end
    end
  end
  
  return attachments
end

function M.download_attachment(email_id, attachment_id, save_path)
  -- Download specific attachment
  local cache_dir = vim.fn.stdpath('cache') .. '/himalaya/attachments/'
  vim.fn.mkdir(cache_dir, 'p')
  
  save_path = save_path or cache_dir .. attachment_id
  
  local cmd = string.format(
    "himalaya message attachment download %s %s -o %s",
    email_id, attachment_id, save_path
  )
  
  local result = utils.execute_command(cmd)
  
  if result.success then
    notify.himalaya(
      "Attachment downloaded",
      notify.categories.USER_ACTION,
      { filename = vim.fn.fnamemodify(save_path, ':t') }
    )
    return save_path
  else
    notify.himalaya(
      "Failed to download attachment",
      notify.categories.ERROR,
      { error = result.error }
    )
    return nil, result.error
  end
end

function M.open_attachment(attachment_path, content_type)
  -- Open attachment with appropriate handler
  local handlers = {
    ["application/pdf"] = "open",
    ["image/png"] = "open",
    ["image/jpeg"] = "open",
    ["text/plain"] = "edit",
    ["application/json"] = "edit",
    ["text/html"] = "open"
  }
  
  local handler = handlers[content_type] or "open"
  
  if handler == "edit" then
    -- Open in Neovim
    vim.cmd("edit " .. attachment_path)
  else
    -- Open with system handler
    local open_cmd = vim.fn.has('mac') == 1 and 'open' or 'xdg-open'
    vim.fn.jobstart({open_cmd, attachment_path}, {detach = true})
  end
end

function M.add_attachment(draft_buffer, file_path)
  -- Add attachment to draft email
  if not vim.fn.filereadable(file_path) then
    notify.himalaya(
      "File not found: " .. file_path,
      notify.categories.ERROR
    )
    return false
  end
  
  -- Add attachment header to draft
  local lines = vim.api.nvim_buf_get_lines(draft_buffer, 0, -1, false)
  local header_end = 0
  
  for i, line in ipairs(lines) do
    if line == "" then
      header_end = i - 1
      break
    end
  end
  
  -- Insert attachment header
  table.insert(lines, header_end + 1, "X-Attachment: " .. file_path)
  vim.api.nvim_buf_set_lines(draft_buffer, 0, -1, false, lines)
  
  notify.himalaya(
    "Attachment added",
    notify.categories.USER_ACTION,
    { filename = vim.fn.fnamemodify(file_path, ':t') }
  )
  
  return true
end

return M
```

#### 1.2 UI Integration

Update `ui/email_viewer.lua`:

```lua
-- Add attachment section to email viewer
function M.render_attachments(buf, attachments)
  local lines = {"", "── Attachments ──"}
  
  if #attachments == 0 then
    table.insert(lines, "No attachments")
  else
    for i, att in ipairs(attachments) do
      local size_str = M.format_size(att.size)
      local line = string.format(
        "%d. %s (%s) [%s]",
        i, att.filename, att.content_type, size_str
      )
      table.insert(lines, line)
    end
  end
  
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
  
  -- Add keymaps for attachment actions
  for i, att in ipairs(attachments) do
    vim.keymap.set('n', tostring(i), function()
      M.handle_attachment_action(att)
    end, { buffer = buf })
  end
end

function M.handle_attachment_action(attachment)
  -- Show action menu
  local actions = {
    "Download",
    "Open", 
    "Save As...",
    "Cancel"
  }
  
  vim.ui.select(actions, {
    prompt = "Attachment: " .. attachment.filename
  }, function(choice)
    if choice == "Download" then
      require('neotex.plugins.tools.himalaya.core.attachments')
        .download_attachment(M.current_email_id, attachment.id)
    elseif choice == "Open" then
      local path = require('neotex.plugins.tools.himalaya.core.attachments')
        .download_attachment(M.current_email_id, attachment.id)
      if path then
        require('neotex.plugins.tools.himalaya.core.attachments')
          .open_attachment(path, attachment.content_type)
      end
    elseif choice == "Save As..." then
      vim.ui.input({
        prompt = "Save as: ",
        default = vim.fn.expand("~/Downloads/") .. attachment.filename
      }, function(save_path)
        if save_path then
          require('neotex.plugins.tools.himalaya.core.attachments')
            .download_attachment(M.current_email_id, attachment.id, save_path)
        end
      end)
    end
  end)
end
```

### 2. Image Display

**Priority**: High  
**Estimated Effort**: 3-4 days

#### 2.1 Image Display Module

Create `ui/image_viewer.lua`:

```lua
local M = {}
local notify = require('neotex.util.notifications')

-- Check for image display capabilities
function M.check_capabilities()
  local capabilities = {
    kitty = vim.fn.executable('kitty') == 1,
    iterm2 = vim.env.TERM_PROGRAM == 'iTerm.app',
    sixel = vim.env.TERM:match('sixel') ~= nil,
    ueberzug = vim.fn.executable('ueberzug') == 1
  }
  
  -- Determine best method
  if capabilities.kitty and vim.env.KITTY_WINDOW_ID then
    return 'kitty'
  elseif capabilities.iterm2 then
    return 'iterm2'
  elseif capabilities.sixel then
    return 'sixel'
  elseif capabilities.ueberzug then
    return 'ueberzug'
  else
    return nil
  end
end

function M.display_image(image_path, options)
  options = options or {}
  local method = M.check_capabilities()
  
  if not method then
    notify.himalaya(
      "No image display capability found",
      notify.categories.WARNING
    )
    return false
  end
  
  local success = false
  
  if method == 'kitty' then
    success = M.display_kitty(image_path, options)
  elseif method == 'iterm2' then
    success = M.display_iterm2(image_path, options)
  elseif method == 'ueberzug' then
    success = M.display_ueberzug(image_path, options)
  end
  
  return success
end

function M.display_kitty(image_path, options)
  -- Use kitty icat protocol
  local cmd = {
    'kitty', '+kitten', 'icat',
    '--place', string.format('%dx%d@%dx%d', 
      options.width or 40,
      options.height or 20,
      options.col or 0,
      options.row or 0
    ),
    image_path
  }
  
  vim.fn.jobstart(cmd, {
    on_exit = function(_, code)
      if code ~= 0 then
        notify.himalaya(
          "Failed to display image",
          notify.categories.ERROR
        )
      end
    end
  })
  
  return true
end

function M.display_inline_images(email_content, buffer)
  -- Extract and display inline images
  local inline_images = {}
  
  -- Parse email for inline images
  for cid, _ in email_content:gmatch('src="cid:([^"]+)"') do
    table.insert(inline_images, cid)
  end
  
  if #inline_images > 0 then
    notify.himalaya(
      string.format("Found %d inline images", #inline_images),
      notify.categories.STATUS
    )
    
    -- Download and cache inline images
    for _, cid in ipairs(inline_images) do
      M.download_inline_image(cid, buffer)
    end
  end
end

function M.create_image_preview_window()
  -- Create floating window for image preview
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded'
  })
  
  -- Set up keymaps
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf })
  
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf })
  
  return win, buf
end

return M
```

### 3. Address Autocomplete

**Priority**: High  
**Estimated Effort**: 3-4 days

#### 3.1 Address Book Module

Create `core/contacts.lua`:

```lua
local M = {}
local state = require('neotex.plugins.tools.himalaya.core.state')

-- Contact structure
local contact_schema = {
  email = "",
  name = "",
  nickname = "",
  last_used = 0,
  frequency = 0
}

function M.get_contacts()
  return state.get('contacts') or {}
end

function M.add_contact(email, name)
  local contacts = M.get_contacts()
  
  contacts[email] = {
    email = email,
    name = name or "",
    last_used = os.time(),
    frequency = (contacts[email] and contacts[email].frequency or 0) + 1
  }
  
  state.set('contacts', contacts)
end

function M.extract_contacts_from_emails()
  -- Extract contacts from sent/received emails
  local emails = state.get('emails') or {}
  local contacts = M.get_contacts()
  
  for _, email in pairs(emails) do
    -- Extract from To field
    if email.to then
      for _, recipient in ipairs(email.to) do
        if recipient.email and not contacts[recipient.email] then
          M.add_contact(recipient.email, recipient.name)
        end
      end
    end
    
    -- Extract from From field
    if email.from and email.from.email then
      if not contacts[email.from.email] then
        M.add_contact(email.from.email, email.from.name)
      end
    end
  end
end

function M.search_contacts(query)
  local contacts = M.get_contacts()
  local results = {}
  
  query = query:lower()
  
  for email, contact in pairs(contacts) do
    local email_match = email:lower():find(query, 1, true)
    local name_match = contact.name and contact.name:lower():find(query, 1, true)
    
    if email_match or name_match then
      table.insert(results, {
        email = email,
        name = contact.name,
        display = M.format_address(contact.name, email),
        score = contact.frequency + (os.time() - contact.last_used) / 86400
      })
    end
  end
  
  -- Sort by score (frequency and recency)
  table.sort(results, function(a, b)
    return a.score > b.score
  end)
  
  return results
end

function M.format_address(name, email)
  if name and name ~= "" then
    return string.format('"%s" <%s>', name, email)
  else
    return email
  end
end

return M
```

#### 3.2 Autocomplete Integration

Create `ui/address_complete.lua`:

```lua
local M = {}
local contacts = require('neotex.plugins.tools.himalaya.core.contacts')

function M.setup_autocomplete(buffer)
  -- Set up completion for To, Cc, Bcc fields
  vim.api.nvim_buf_set_option(buffer, 'omnifunc', 'v:lua.himalaya_complete_address')
  
  -- Define global completion function
  _G.himalaya_complete_address = function(findstart, base)
    if findstart == 1 then
      -- Find start of address
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      
      -- Check if we're in a header field
      local field_match = line:match("^(%w+):%s*")
      if not field_match or not vim.tbl_contains({'To', 'Cc', 'Bcc'}, field_match) then
        return -1
      end
      
      -- Find start of current address
      local start = col
      while start > 0 and line:sub(start, start):match("[^,;]") do
        start = start - 1
      end
      
      return start
    else
      -- Return completions
      local results = contacts.search_contacts(base)
      local completions = {}
      
      for _, result in ipairs(results) do
        table.insert(completions, {
          word = result.display,
          menu = string.format("(%d uses)", result.score),
          info = result.email
        })
      end
      
      return completions
    end
  end
  
  -- Set up keymaps
  vim.keymap.set('i', '<C-Space>', '<C-x><C-o>', { buffer = buffer })
  vim.keymap.set('i', '<Tab>', function()
    if vim.fn.pumvisible() == 1 then
      return '<C-n>'
    else
      return '<Tab>'
    end
  end, { buffer = buffer, expr = true })
end

function M.parse_addresses(header_value)
  -- Parse comma-separated addresses
  local addresses = {}
  
  -- Split by comma, handling quoted names
  local current = ""
  local in_quotes = false
  
  for char in header_value:gmatch(".") do
    if char == '"' then
      in_quotes = not in_quotes
    elseif char == ',' and not in_quotes then
      table.insert(addresses, vim.trim(current))
      current = ""
    else
      current = current .. char
    end
  end
  
  if current ~= "" then
    table.insert(addresses, vim.trim(current))
  end
  
  return addresses
end

function M.validate_addresses(addresses)
  -- Validate email addresses
  local valid = {}
  local invalid = {}
  
  for _, addr in ipairs(addresses) do
    local email = addr:match("<([^>]+)>") or addr
    if email:match("^[%w._%+-]+@[%w.-]+%.[%w]+$") then
      table.insert(valid, addr)
    else
      table.insert(invalid, addr)
    end
  end
  
  return valid, invalid
end

return M
```

### 4. Local Trash System

**Priority**: Medium  
**Estimated Effort**: 2-3 days

#### 4.1 Trash Management Module

Create `core/trash.lua`:

```lua
local M = {}
local state = require('neotex.plugins.tools.himalaya.core.state')
local notify = require('neotex.util.notifications')

-- Trash configuration
M.config = {
  retention_days = 30,
  max_size_mb = 100,
  auto_cleanup = true
}

function M.move_to_trash(email_id, folder)
  -- Save email metadata before deletion
  local trash = state.get('trash') or {}
  
  -- Get email details
  local email = require('neotex.plugins.tools.himalaya.core.commands.email')
    .get_email(email_id)
  
  if email then
    trash[email_id] = {
      email = email,
      deleted_at = os.time(),
      original_folder = folder,
      size = email.size or 0
    }
    
    state.set('trash', trash)
    
    -- Delete from server
    local utils = require('neotex.plugins.tools.himalaya.utils')
    local cmd = string.format("himalaya message delete %s", email_id)
    local result = utils.execute_command(cmd)
    
    if result.success then
      notify.himalaya(
        "Email moved to trash",
        notify.categories.USER_ACTION,
        { subject = email.subject }
      )
      return true
    else
      -- Rollback trash entry
      trash[email_id] = nil
      state.set('trash', trash)
      return false, result.error
    end
  end
  
  return false, "Email not found"
end

function M.restore_from_trash(email_id)
  local trash = state.get('trash') or {}
  local item = trash[email_id]
  
  if not item then
    notify.himalaya(
      "Email not found in trash",
      notify.categories.ERROR
    )
    return false
  end
  
  -- Restore email to original folder
  -- Note: This requires re-uploading the email to the server
  -- which is not directly supported by himalaya CLI
  
  notify.himalaya(
    "Email restore not yet implemented",
    notify.categories.WARNING,
    { 
      reason = "Requires server-side restore capability",
      workaround = "Forward the email to yourself instead"
    }
  )
  
  return false
end

function M.empty_trash()
  local trash = state.get('trash') or {}
  local count = vim.tbl_count(trash)
  
  if count == 0 then
    notify.himalaya(
      "Trash is already empty",
      notify.categories.STATUS
    )
    return
  end
  
  vim.ui.select({'Yes', 'No'}, {
    prompt = string.format("Permanently delete %d emails?", count)
  }, function(choice)
    if choice == 'Yes' then
      state.set('trash', {})
      notify.himalaya(
        string.format("Permanently deleted %d emails", count),
        notify.categories.USER_ACTION
      )
    end
  end)
end

function M.cleanup_old_trash()
  if not M.config.auto_cleanup then
    return
  end
  
  local trash = state.get('trash') or {}
  local now = os.time()
  local cutoff = now - (M.config.retention_days * 24 * 60 * 60)
  local cleaned = 0
  
  for id, item in pairs(trash) do
    if item.deleted_at < cutoff then
      trash[id] = nil
      cleaned = cleaned + 1
    end
  end
  
  if cleaned > 0 then
    state.set('trash', trash)
    notify.himalaya(
      string.format("Auto-cleaned %d old trash emails", cleaned),
      notify.categories.BACKGROUND
    )
  end
end

function M.get_trash_stats()
  local trash = state.get('trash') or {}
  local stats = {
    count = 0,
    size = 0,
    oldest = nil,
    newest = nil
  }
  
  for _, item in pairs(trash) do
    stats.count = stats.count + 1
    stats.size = stats.size + (item.size or 0)
    
    if not stats.oldest or item.deleted_at < stats.oldest then
      stats.oldest = item.deleted_at
    end
    
    if not stats.newest or item.deleted_at > stats.newest then
      stats.newest = item.deleted_at
    end
  end
  
  stats.size_mb = stats.size / (1024 * 1024)
  
  return stats
end

return M
```

#### 4.2 Trash UI

Create `ui/trash_viewer.lua`:

```lua
local M = {}
local trash = require('neotex.plugins.tools.himalaya.core.trash')
local state = require('neotex.plugins.tools.himalaya.core.state')

function M.open()
  -- Create trash viewer buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "Himalaya Trash")
  
  -- Create window
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded'
  })
  
  M.render_trash(buf)
  M.setup_keymaps(buf)
end

function M.render_trash(buf)
  local trash_items = state.get('trash') or {}
  local lines = {"Himalaya Trash", ""}
  
  -- Add stats
  local stats = trash.get_trash_stats()
  table.insert(lines, string.format(
    "%d emails | %.2f MB | Retention: %d days",
    stats.count, stats.size_mb, trash.config.retention_days
  ))
  table.insert(lines, string.rep("─", 60))
  table.insert(lines, "")
  
  -- Sort by deletion date
  local sorted = {}
  for id, item in pairs(trash_items) do
    table.insert(sorted, vim.tbl_extend('force', item, {id = id}))
  end
  
  table.sort(sorted, function(a, b)
    return a.deleted_at > b.deleted_at
  end)
  
  -- Render emails
  for i, item in ipairs(sorted) do
    local date = os.date("%Y-%m-%d %H:%M", item.deleted_at)
    local from = item.email.from or "Unknown"
    local subject = item.email.subject or "No subject"
    
    local line = string.format(
      "%3d. [%s] %s - %s",
      i, date, from, subject
    )
    table.insert(lines, line)
  end
  
  if #sorted == 0 then
    table.insert(lines, "Trash is empty")
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

function M.setup_keymaps(buf)
  local opts = { buffer = buf, silent = true }
  
  -- Close
  vim.keymap.set('n', 'q', ':close<CR>', opts)
  vim.keymap.set('n', '<Esc>', ':close<CR>', opts)
  
  -- Empty trash
  vim.keymap.set('n', 'E', function()
    trash.empty_trash()
    M.render_trash(buf)
  end, opts)
  
  -- Restore email (not implemented)
  vim.keymap.set('n', 'r', function()
    vim.notify("Restore not yet implemented", vim.log.levels.WARN)
  end, opts)
  
  -- Refresh
  vim.keymap.set('n', 'R', function()
    M.render_trash(buf)
  end, opts)
end

return M
```

### 5. Custom Headers

**Priority**: Low  
**Estimated Effort**: 2 days

#### 5.1 Custom Headers Module

Create `core/headers.lua`:

```lua
local M = {}

-- Standard headers that should not be modified
local protected_headers = {
  'from', 'to', 'cc', 'bcc', 'subject', 'date',
  'message-id', 'in-reply-to', 'references'
}

-- Common custom headers
M.common_headers = {
  'X-Priority',
  'X-Mailer',
  'Reply-To',
  'Organization',
  'User-Agent',
  'X-Custom-Tag'
}

function M.parse_headers(email_text)
  local headers = {}
  local in_headers = true
  
  for line in email_text:gmatch("[^\r\n]+") do
    if in_headers then
      if line == "" then
        in_headers = false
      else
        local name, value = line:match("^([%w%-]+):%s*(.*)$")
        if name then
          headers[name:lower()] = value
        end
      end
    end
  end
  
  return headers
end

function M.add_custom_header(draft_buffer, header_name, header_value)
  -- Validate header name
  if not header_name:match("^[%w%-]+$") then
    return false, "Invalid header name"
  end
  
  -- Check if protected
  if vim.tbl_contains(protected_headers, header_name:lower()) then
    return false, "Cannot modify protected header"
  end
  
  -- Add to draft
  local lines = vim.api.nvim_buf_get_lines(draft_buffer, 0, -1, false)
  local header_end = 0
  
  for i, line in ipairs(lines) do
    if line == "" then
      header_end = i - 1
      break
    end
  end
  
  -- Insert custom header
  table.insert(lines, header_end + 1, 
    string.format("%s: %s", header_name, header_value))
  
  vim.api.nvim_buf_set_lines(draft_buffer, 0, -1, false, lines)
  
  return true
end

function M.setup_header_completion(buffer)
  -- Provide completion for common headers
  vim.api.nvim_buf_set_option(buffer, 'completefunc', 
    'v:lua.himalaya_complete_header')
  
  _G.himalaya_complete_header = function(findstart, base)
    if findstart == 1 then
      local line = vim.api.nvim_get_current_line()
      if line:match("^%s*$") then
        return 0
      end
      return -1
    else
      local completions = {}
      for _, header in ipairs(M.common_headers) do
        if header:lower():find(base:lower(), 1, true) then
          table.insert(completions, header .. ": ")
        end
      end
      return completions
    end
  end
end

return M
```

### 6. Multiple Email Accounts Integration

**Priority**: High  
**Estimated Effort**: 4-5 days

#### 6.1 Multi-Provider Support

Create provider configuration templates and account management:

##### Provider Templates Module

Create `core/providers.lua`:

```lua
local M = {}

-- Provider configuration templates
M.provider_templates = {
  gmail = {
    imap = {
      host = "imap.gmail.com",
      port = 993,
      security = "tls"
    },
    smtp = {
      host = "smtp.gmail.com",
      port = 587,
      security = "starttls"
    },
    oauth = {
      enabled = true,
      provider = "google"
    }
  },
  outlook = {
    imap = {
      host = "outlook.office365.com",
      port = 993,
      security = "tls"
    },
    smtp = {
      host = "smtp.office365.com",
      port = 587,
      security = "starttls"
    },
    oauth = {
      enabled = true,
      provider = "microsoft"
    }
  },
  yahoo = {
    imap = {
      host = "imap.mail.yahoo.com",
      port = 993,
      security = "tls"
    },
    smtp = {
      host = "smtp.mail.yahoo.com",
      port = 587,
      security = "starttls"
    },
    oauth = {
      enabled = false
    }
  },
  icloud = {
    imap = {
      host = "imap.mail.me.com",
      port = 993,
      security = "tls"
    },
    smtp = {
      host = "smtp.mail.me.com",
      port = 587,
      security = "starttls"
    },
    oauth = {
      enabled = false
    }
  },
  custom = {
    imap = {
      host = "",
      port = 993,
      security = "tls"
    },
    smtp = {
      host = "",
      port = 587,
      security = "starttls"
    },
    oauth = {
      enabled = false
    }
  }
}

-- Detect provider from email address
function M.detect_provider(email)
  local domain = email:match("@(.+)$")
  if not domain then
    return nil
  end
  
  local provider_map = {
    ["gmail.com"] = "gmail",
    ["googlemail.com"] = "gmail",
    ["outlook.com"] = "outlook",
    ["hotmail.com"] = "outlook",
    ["live.com"] = "outlook",
    ["msn.com"] = "outlook",
    ["yahoo.com"] = "yahoo",
    ["yahoo.co.uk"] = "yahoo",
    ["yahoo.fr"] = "yahoo",
    ["icloud.com"] = "icloud",
    ["me.com"] = "icloud",
    ["mac.com"] = "icloud"
  }
  
  -- Check exact domain match
  local provider = provider_map[domain:lower()]
  if provider then
    return provider, M.provider_templates[provider]
  end
  
  -- Check partial matches for subdomains
  for pattern, prov in pairs(provider_map) do
    if domain:lower():match("%." .. pattern .. "$") then
      return prov, M.provider_templates[prov]
    end
  end
  
  return "custom", M.provider_templates.custom
end

-- Get provider configuration
function M.get_provider_config(email)
  local provider, template = M.detect_provider(email)
  return provider, vim.deepcopy(template)
end

-- Validate provider configuration
function M.validate_config(config)
  local required = {
    "imap.host", "imap.port", "imap.security",
    "smtp.host", "smtp.port", "smtp.security"
  }
  
  for _, path in ipairs(required) do
    local value = config
    for part in path:gmatch("[^.]+") do
      value = value and value[part]
    end
    if not value or value == "" then
      return false, "Missing required field: " .. path
    end
  end
  
  return true
end

return M
```

#### 6.2 Account Management

Create `core/accounts.lua`:

```lua
local M = {}
local providers = require('neotex.plugins.tools.himalaya.core.providers')
local state = require('neotex.plugins.tools.himalaya.core.state')
local notify = require('neotex.util.notifications')

-- Account structure
local account_schema = {
  id = "",              -- Unique identifier
  email = "",           -- Email address
  name = "",            -- Display name
  provider = "",        -- Provider type (gmail, outlook, etc.)
  imap = {},           -- IMAP configuration
  smtp = {},           -- SMTP configuration
  oauth = {},          -- OAuth configuration
  active = true,       -- Whether account is active
  default = false,     -- Whether this is the default account
  folders = {},        -- Cached folder list
  last_sync = 0        -- Last sync timestamp
}

-- Get all accounts
function M.get_accounts()
  return state.get('accounts') or {}
end

-- Get active accounts
function M.get_active_accounts()
  local accounts = M.get_accounts()
  local active = {}
  
  for id, account in pairs(accounts) do
    if account.active then
      active[id] = account
    end
  end
  
  return active
end

-- Get default account
function M.get_default_account()
  local accounts = M.get_accounts()
  
  for id, account in pairs(accounts) do
    if account.default then
      return account
    end
  end
  
  -- Return first active account if no default
  for id, account in pairs(accounts) do
    if account.active then
      return account
    end
  end
  
  return nil
end

-- Add new account
function M.add_account(email, password, custom_config)
  local accounts = M.get_accounts()
  
  -- Check if account already exists
  for id, account in pairs(accounts) do
    if account.email == email then
      notify.himalaya(
        "Account already exists: " .. email,
        notify.categories.WARNING
      )
      return false
    end
  end
  
  -- Detect provider and get template
  local provider, config = providers.get_provider_config(email)
  
  -- Merge with custom config if provided
  if custom_config then
    config = vim.tbl_deep_extend('force', config, custom_config)
  end
  
  -- Validate configuration
  local valid, err = providers.validate_config(config)
  if not valid then
    notify.himalaya(
      "Invalid configuration: " .. err,
      notify.categories.ERROR
    )
    return false
  end
  
  -- Create account
  local account_id = email:gsub("[@.]", "_")
  local account = {
    id = account_id,
    email = email,
    name = email:match("^([^@]+)") or email,
    provider = provider,
    imap = config.imap,
    smtp = config.smtp,
    oauth = config.oauth,
    active = true,
    default = vim.tbl_count(accounts) == 0, -- First account is default
    folders = {},
    last_sync = 0
  }
  
  -- Store password securely (this is a simplified version)
  -- In production, use proper credential storage
  account.password = password
  
  -- Save account
  accounts[account_id] = account
  state.set('accounts', accounts)
  
  notify.himalaya(
    "Account added: " .. email,
    notify.categories.USER_ACTION,
    { provider = provider }
  )
  
  return true, account
end

-- Remove account
function M.remove_account(account_id)
  local accounts = M.get_accounts()
  local account = accounts[account_id]
  
  if not account then
    notify.himalaya(
      "Account not found: " .. account_id,
      notify.categories.ERROR
    )
    return false
  end
  
  -- Check if it's the last account
  if vim.tbl_count(accounts) == 1 then
    notify.himalaya(
      "Cannot remove the last account",
      notify.categories.ERROR
    )
    return false
  end
  
  -- If default account, assign default to another
  if account.default then
    accounts[account_id] = nil
    for id, acc in pairs(accounts) do
      if acc.active then
        acc.default = true
        break
      end
    end
  else
    accounts[account_id] = nil
  end
  
  state.set('accounts', accounts)
  
  notify.himalaya(
    "Account removed: " .. account.email,
    notify.categories.USER_ACTION
  )
  
  return true
end

-- Switch default account
function M.set_default_account(account_id)
  local accounts = M.get_accounts()
  local target = accounts[account_id]
  
  if not target then
    notify.himalaya(
      "Account not found: " .. account_id,
      notify.categories.ERROR
    )
    return false
  end
  
  -- Clear current default
  for id, account in pairs(accounts) do
    account.default = false
  end
  
  -- Set new default
  target.default = true
  state.set('accounts', accounts)
  
  notify.himalaya(
    "Default account changed to: " .. target.email,
    notify.categories.USER_ACTION
  )
  
  return true
end

-- Get account by email
function M.get_account_by_email(email)
  local accounts = M.get_accounts()
  
  for id, account in pairs(accounts) do
    if account.email == email then
      return account
    end
  end
  
  return nil
end

-- Update account configuration
function M.update_account(account_id, updates)
  local accounts = M.get_accounts()
  local account = accounts[account_id]
  
  if not account then
    return false, "Account not found"
  end
  
  -- Merge updates
  account = vim.tbl_deep_extend('force', account, updates)
  
  -- Validate if provider config changed
  if updates.imap or updates.smtp then
    local valid, err = providers.validate_config(account)
    if not valid then
      return false, err
    end
  end
  
  accounts[account_id] = account
  state.set('accounts', accounts)
  
  return true
end

return M
```

#### 6.3 Multi-Account UI Integration

Update UI components to support multiple accounts:

```lua
-- ui/account_switcher.lua
local M = {}
local accounts = require('neotex.plugins.tools.himalaya.core.accounts')

function M.show_account_menu()
  local account_list = accounts.get_active_accounts()
  local default = accounts.get_default_account()
  
  -- Build menu items
  local items = {}
  local account_map = {}
  
  for id, account in pairs(account_list) do
    local marker = account.id == default.id and " [default]" or ""
    local label = string.format("%s%s", account.email, marker)
    table.insert(items, label)
    account_map[label] = account
  end
  
  -- Add management options
  table.insert(items, "──────────────")
  table.insert(items, "Add Account...")
  table.insert(items, "Remove Account...")
  table.insert(items, "Manage Accounts...")
  
  -- Show menu
  vim.ui.select(items, {
    prompt = "Select Account:",
    format_item = function(item)
      return item
    end
  }, function(choice)
    if not choice then
      return
    end
    
    if choice == "Add Account..." then
      M.add_account_wizard()
    elseif choice == "Remove Account..." then
      M.remove_account_menu()
    elseif choice == "Manage Accounts..." then
      M.open_account_manager()
    elseif account_map[choice] then
      accounts.set_default_account(account_map[choice].id)
      -- Refresh UI with new account
      require('neotex.plugins.tools.himalaya.ui').refresh()
    end
  end)
end

function M.add_account_wizard()
  -- Step 1: Get email address
  vim.ui.input({
    prompt = "Email address: "
  }, function(email)
    if not email or email == "" then
      return
    end
    
    -- Detect provider
    local provider, config = require('neotex.plugins.tools.himalaya.core.providers')
      .get_provider_config(email)
    
    -- Step 2: Get password
    vim.ui.input({
      prompt = "Password: ",
      -- Note: In real implementation, use proper password input
    }, function(password)
      if not password or password == "" then
        return
      end
      
      -- Step 3: Confirm settings
      local settings = string.format(
        "Provider: %s\nIMAP: %s:%d\nSMTP: %s:%d",
        provider,
        config.imap.host, config.imap.port,
        config.smtp.host, config.smtp.port
      )
      
      vim.ui.select({'Yes', 'Customize', 'Cancel'}, {
        prompt = "Use these settings?\n\n" .. settings .. "\n"
      }, function(choice)
        if choice == 'Yes' then
          accounts.add_account(email, password)
        elseif choice == 'Customize' then
          M.customize_account_settings(email, password, config)
        end
      end)
    end)
  end)
end

-- Add keybinding for quick account switching
function M.setup_keybindings()
  vim.keymap.set('n', '<leader>ma', M.show_account_menu, {
    desc = "Switch/manage email accounts"
  })
end

return M
```

#### 6.4 Sync Management for Multiple Accounts

Create `sync/multi_account.lua`:

```lua
local M = {}
local accounts = require('neotex.plugins.tools.himalaya.core.accounts')
local sync_manager = require('neotex.plugins.tools.himalaya.sync.manager')
local notify = require('neotex.util.notifications')

-- Sync all active accounts
function M.sync_all_accounts(options)
  options = options or {}
  local account_list = accounts.get_active_accounts()
  local sync_count = vim.tbl_count(account_list)
  
  if sync_count == 0 then
    notify.himalaya(
      "No active accounts to sync",
      notify.categories.WARNING
    )
    return
  end
  
  notify.himalaya(
    string.format("Syncing %d accounts...", sync_count),
    notify.categories.STATUS
  )
  
  -- Sync accounts in parallel
  local completed = 0
  local errors = {}
  
  for id, account in pairs(account_list) do
    vim.schedule(function()
      local success, err = sync_manager.sync_account(account)
      
      if not success then
        errors[account.email] = err
      end
      
      completed = completed + 1
      
      if completed == sync_count then
        M.on_sync_complete(sync_count, errors)
      end
    end)
  end
end

-- Handle sync completion
function M.on_sync_complete(total, errors)
  local error_count = vim.tbl_count(errors)
  
  if error_count == 0 then
    notify.himalaya(
      string.format("All %d accounts synced successfully", total),
      notify.categories.USER_ACTION
    )
  else
    local msg = string.format(
      "%d/%d accounts synced. %d failed.",
      total - error_count, total, error_count
    )
    
    notify.himalaya(msg, notify.categories.WARNING, {
      errors = errors
    })
  end
end

-- Auto-sync setup for multiple accounts
function M.setup_auto_sync(interval_minutes)
  interval_minutes = interval_minutes or 15
  
  -- Cancel existing timer if any
  if M.auto_sync_timer then
    M.auto_sync_timer:stop()
  end
  
  -- Create new timer
  M.auto_sync_timer = vim.loop.new_timer()
  
  -- Start timer
  M.auto_sync_timer:start(
    2000, -- 2 second delay
    interval_minutes * 60 * 1000, -- Convert to milliseconds
    vim.schedule_wrap(function()
      M.sync_all_accounts({ background = true })
    end)
  )
  
  notify.himalaya(
    string.format("Auto-sync enabled for all accounts (every %d minutes)", interval_minutes),
    notify.categories.STATUS
  )
end

return M
```

### 7. OAuth & Security Improvements

**Priority**: High  
**Estimated Effort**: 1 week

#### 7.1 Enhanced OAuth Support

**Current State**:
- Limited to Gmail OAuth
- Token stored in plain text
- No automatic cleanup
- Single provider implementation

**Implementation Plan**:

##### OAuth Provider Management

Create `sync/oauth_providers.lua`:

```lua
local M = {}
local notify = require('neotex.util.notifications')

-- OAuth provider configurations
M.oauth_providers = {
  gmail = {
    name = "Google Gmail",
    auth_url = "https://accounts.google.com/o/oauth2/auth",
    token_url = "https://oauth2.googleapis.com/token",
    scope = "https://mail.google.com/",
    redirect_uri = "http://localhost:8080",
    client_id_env = "HIMALAYA_GMAIL_CLIENT_ID",
    client_secret_env = "HIMALAYA_GMAIL_CLIENT_SECRET"
  },
  outlook = {
    name = "Microsoft Outlook",
    auth_url = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
    token_url = "https://login.microsoftonline.com/common/oauth2/v2.0/token",
    scope = "https://outlook.office.com/IMAP.AccessAsUser.All https://outlook.office.com/SMTP.Send",
    redirect_uri = "http://localhost:8080",
    client_id_env = "HIMALAYA_OUTLOOK_CLIENT_ID",
    client_secret_env = "HIMALAYA_OUTLOOK_CLIENT_SECRET"
  },
  yahoo = {
    name = "Yahoo Mail",
    auth_url = "https://api.login.yahoo.com/oauth2/request_auth",
    token_url = "https://api.login.yahoo.com/oauth2/get_token",
    scope = "mail-r mail-w",
    redirect_uri = "http://localhost:8080",
    client_id_env = "HIMALAYA_YAHOO_CLIENT_ID",
    client_secret_env = "HIMALAYA_YAHOO_CLIENT_SECRET"
  }
}

-- Get provider configuration
function M.get_provider(provider_name)
  return M.oauth_providers[provider_name]
end

-- Check if provider supports OAuth
function M.supports_oauth(email)
  local domain = email:match("@(.+)$")
  if not domain then
    return false
  end
  
  local oauth_domains = {
    ["gmail.com"] = "gmail",
    ["googlemail.com"] = "gmail",
    ["outlook.com"] = "outlook",
    ["hotmail.com"] = "outlook",
    ["live.com"] = "outlook",
    ["yahoo.com"] = "yahoo"
  }
  
  return oauth_domains[domain:lower()] ~= nil
end

-- Initialize OAuth flow
function M.start_oauth_flow(provider_name, account_email)
  local provider = M.get_provider(provider_name)
  if not provider then
    notify.himalaya(
      "Unknown OAuth provider: " .. provider_name,
      notify.categories.ERROR
    )
    return false
  end
  
  -- Check for client credentials
  local client_id = vim.env[provider.client_id_env]
  local client_secret = vim.env[provider.client_secret_env]
  
  if not client_id or not client_secret then
    notify.himalaya(
      string.format("Missing OAuth credentials. Set %s and %s environment variables",
        provider.client_id_env, provider.client_secret_env),
      notify.categories.ERROR
    )
    return false
  end
  
  -- Build authorization URL
  local auth_params = {
    client_id = client_id,
    redirect_uri = provider.redirect_uri,
    response_type = "code",
    scope = provider.scope,
    access_type = "offline",
    prompt = "consent"
  }
  
  local auth_url = provider.auth_url .. "?" .. M.build_query_string(auth_params)
  
  -- Open browser for authorization
  local open_cmd = vim.fn.has('mac') == 1 and 'open' or 'xdg-open'
  vim.fn.jobstart({open_cmd, auth_url}, {detach = true})
  
  notify.himalaya(
    "Opening browser for OAuth authorization",
    notify.categories.USER_ACTION,
    { provider = provider.name }
  )
  
  -- Start local server to receive callback
  M.start_oauth_callback_server(provider, client_id, client_secret, account_email)
  
  return true
end

return M
```

#### 7.2 Token Security

Create `sync/oauth_security.lua`:

```lua
local M = {}
local notify = require('neotex.util.notifications')

-- Encryption key derivation
function M.get_encryption_key()
  -- Derive key from machine ID and user info
  local machine_id = vim.fn.system("hostname"):gsub("%s+", "")
  local user_id = vim.env.USER or vim.env.USERNAME or "default"
  local nvim_version = vim.version().major .. vim.version().minor
  
  -- Create a deterministic but unique key
  local key_source = string.format("%s:%s:himalaya:%s", machine_id, user_id, nvim_version)
  
  -- Simple hash function for key derivation
  local hash = 0
  for i = 1, #key_source do
    hash = (hash * 31 + key_source:byte(i)) % 2147483647
  end
  
  return tostring(hash)
end

-- Token encryption using XOR cipher with key stretching
function M.encrypt_token(token, key)
  -- Key stretching: repeat key to match token length
  local stretched_key = ""
  while #stretched_key < #token do
    stretched_key = stretched_key .. key
  end
  stretched_key = stretched_key:sub(1, #token)
  
  -- XOR encryption
  local encrypted = {}
  for i = 1, #token do
    local token_byte = token:byte(i)
    local key_byte = stretched_key:byte(i)
    table.insert(encrypted, string.char(bit.bxor(token_byte, key_byte)))
  end
  
  -- Base64 encode for safe storage
  return vim.base64.encode(table.concat(encrypted))
end

-- Token decryption
function M.decrypt_token(encrypted_token, key)
  -- Base64 decode
  local encrypted = vim.base64.decode(encrypted_token)
  
  -- Key stretching
  local stretched_key = ""
  while #stretched_key < #encrypted do
    stretched_key = stretched_key .. key
  end
  stretched_key = stretched_key:sub(1, #encrypted)
  
  -- XOR decryption
  local decrypted = {}
  for i = 1, #encrypted do
    local encrypted_byte = encrypted:byte(i)
    local key_byte = stretched_key:byte(i)
    table.insert(decrypted, string.char(bit.bxor(encrypted_byte, key_byte)))
  end
  
  return table.concat(decrypted)
end

-- Secure token storage
function M.store_token(provider, email, token_data)
  local key = M.get_encryption_key()
  
  -- Encrypt sensitive data
  local encrypted_data = {
    access_token = M.encrypt_token(token_data.access_token, key),
    refresh_token = token_data.refresh_token and M.encrypt_token(token_data.refresh_token, key),
    expires_at = token_data.expires_at,
    token_type = token_data.token_type,
    scope = token_data.scope,
    provider = provider,
    email = email,
    encrypted = true,
    version = 1
  }
  
  -- Create secure storage directory
  local oauth_dir = vim.fn.stdpath('data') .. '/himalaya/oauth/'
  vim.fn.mkdir(oauth_dir, 'p')
  
  -- Set restrictive directory permissions
  vim.fn.system({'chmod', '700', oauth_dir})
  
  -- Save encrypted token
  local filename = string.format("%s_%s.token", provider, email:gsub("[@.]", "_"))
  local token_file = oauth_dir .. filename
  
  local json_data = vim.json.encode(encrypted_data)
  vim.fn.writefile(vim.split(json_data, '\n'), token_file)
  
  -- Set restrictive file permissions
  vim.fn.system({'chmod', '600', token_file})
  
  notify.himalaya(
    "OAuth token stored securely",
    notify.categories.STATUS,
    { provider = provider, email = email }
  )
  
  return true
end

-- Retrieve and decrypt token
function M.get_token(provider, email)
  local oauth_dir = vim.fn.stdpath('data') .. '/himalaya/oauth/'
  local filename = string.format("%s_%s.token", provider, email:gsub("[@.]", "_"))
  local token_file = oauth_dir .. filename
  
  if vim.fn.filereadable(token_file) == 0 then
    return nil
  end
  
  -- Read encrypted data
  local lines = vim.fn.readfile(token_file)
  local json_data = table.concat(lines, '\n')
  local encrypted_data = vim.json.decode(json_data)
  
  -- Check version compatibility
  if encrypted_data.version ~= 1 then
    notify.himalaya(
      "Incompatible token version, please re-authenticate",
      notify.categories.ERROR
    )
    return nil
  end
  
  -- Decrypt token
  local key = M.get_encryption_key()
  local token_data = {
    access_token = M.decrypt_token(encrypted_data.access_token, key),
    refresh_token = encrypted_data.refresh_token and M.decrypt_token(encrypted_data.refresh_token, key),
    expires_at = encrypted_data.expires_at,
    token_type = encrypted_data.token_type,
    scope = encrypted_data.scope
  }
  
  -- Check expiration
  if token_data.expires_at and os.time() > token_data.expires_at then
    if token_data.refresh_token then
      -- Attempt to refresh
      return M.refresh_token(provider, email, token_data.refresh_token)
    else
      notify.himalaya(
        "OAuth token expired, please re-authenticate",
        notify.categories.WARNING
      )
      return nil
    end
  end
  
  return token_data
end

-- Automatic token cleanup
function M.cleanup_expired_tokens()
  local oauth_dir = vim.fn.stdpath('data') .. '/himalaya/oauth/'
  local files = vim.fn.glob(oauth_dir .. '*.token', false, true)
  
  local cleaned = 0
  
  for _, file in ipairs(files) do
    local mtime = vim.fn.getftime(file)
    local age_days = (os.time() - mtime) / (24 * 60 * 60)
    
    -- Clean tokens older than 90 days
    if age_days > 90 then
      -- Try to read and check if refresh is possible
      local can_refresh = false
      local ok, lines = pcall(vim.fn.readfile, file)
      
      if ok then
        local json_data = table.concat(lines, '\n')
        local data = vim.json.decode(json_data)
        can_refresh = data.refresh_token ~= nil
      end
      
      if not can_refresh then
        vim.fn.delete(file)
        cleaned = cleaned + 1
        
        notify.himalaya(
          "Cleaned up expired OAuth token",
          notify.categories.BACKGROUND,
          { file = vim.fn.fnamemodify(file, ':t') }
        )
      end
    end
  end
  
  if cleaned > 0 then
    notify.himalaya(
      string.format("Cleaned up %d expired OAuth tokens", cleaned),
      notify.categories.BACKGROUND
    )
  end
end

-- Token refresh
function M.refresh_token(provider, email, refresh_token)
  local oauth_providers = require('neotex.plugins.tools.himalaya.sync.oauth_providers')
  local provider_config = oauth_providers.get_provider(provider)
  
  if not provider_config then
    return nil
  end
  
  -- Implement token refresh logic here
  -- This would make an HTTP request to the provider's token endpoint
  -- For now, return nil to indicate refresh is needed
  
  notify.himalaya(
    "Token refresh not yet implemented",
    notify.categories.WARNING
  )
  
  return nil
end

-- Revoke token
function M.revoke_token(provider, email)
  local oauth_dir = vim.fn.stdpath('data') .. '/himalaya/oauth/'
  local filename = string.format("%s_%s.token", provider, email:gsub("[@.]", "_"))
  local token_file = oauth_dir .. filename
  
  if vim.fn.filereadable(token_file) == 1 then
    vim.fn.delete(token_file)
    notify.himalaya(
      "OAuth token revoked",
      notify.categories.USER_ACTION,
      { provider = provider, email = email }
    )
    return true
  end
  
  return false
end

-- Setup automatic cleanup
function M.setup_auto_cleanup()
  -- Run cleanup on startup
  vim.defer_fn(function()
    M.cleanup_expired_tokens()
  end, 5000) -- 5 seconds after startup
  
  -- Schedule daily cleanup
  local timer = vim.loop.new_timer()
  timer:start(
    24 * 60 * 60 * 1000, -- 24 hours
    24 * 60 * 60 * 1000, -- Repeat every 24 hours
    vim.schedule_wrap(function()
      M.cleanup_expired_tokens()
    end)
  )
end

return M
```

#### 7.3 OAuth UI Integration

Create `ui/oauth_setup.lua`:

```lua
local M = {}
local oauth_providers = require('neotex.plugins.tools.himalaya.sync.oauth_providers')
local oauth_security = require('neotex.plugins.tools.himalaya.sync.oauth_security')
local notify = require('neotex.util.notifications')

-- OAuth setup wizard
function M.setup_oauth(email)
  -- Check if OAuth is supported for this email
  local domain = email:match("@(.+)$")
  if not oauth_providers.supports_oauth(email) then
    notify.himalaya(
      "OAuth not supported for " .. domain,
      notify.categories.WARNING
    )
    return false
  end
  
  -- Determine provider
  local provider_map = {
    ["gmail.com"] = "gmail",
    ["googlemail.com"] = "gmail",
    ["outlook.com"] = "outlook",
    ["hotmail.com"] = "outlook",
    ["live.com"] = "outlook",
    ["yahoo.com"] = "yahoo"
  }
  
  local provider = provider_map[domain:lower()]
  if not provider then
    notify.himalaya(
      "Unknown OAuth provider for " .. domain,
      notify.categories.ERROR
    )
    return false
  end
  
  -- Check if token already exists
  local existing_token = oauth_security.get_token(provider, email)
  if existing_token then
    vim.ui.select({'Use existing', 'Re-authenticate', 'Cancel'}, {
      prompt = "OAuth token already exists for " .. email
    }, function(choice)
      if choice == 'Re-authenticate' then
        oauth_security.revoke_token(provider, email)
        oauth_providers.start_oauth_flow(provider, email)
      end
    end)
  else
    -- Start OAuth flow
    vim.ui.select({'Continue', 'Cancel'}, {
      prompt = string.format(
        "Set up OAuth for %s?\n\nThis will open your browser for authorization.",
        email
      )
    }, function(choice)
      if choice == 'Continue' then
        oauth_providers.start_oauth_flow(provider, email)
      end
    end)
  end
  
  return true
end

-- OAuth status display
function M.show_oauth_status()
  local accounts = require('neotex.plugins.tools.himalaya.core.accounts').get_accounts()
  local status_lines = {"OAuth Token Status", ""}
  
  for id, account in pairs(accounts) do
    if oauth_providers.supports_oauth(account.email) then
      local provider = account.provider
      local token = oauth_security.get_token(provider, account.email)
      
      local status = "Not configured"
      if token then
        if token.expires_at then
          local remaining = token.expires_at - os.time()
          if remaining > 0 then
            local days = math.floor(remaining / (24 * 60 * 60))
            status = string.format("Valid (%d days remaining)", days)
          else
            status = "Expired"
          end
        else
          status = "Valid (no expiration)"
        end
      end
      
      table.insert(status_lines, string.format(
        "%s: %s",
        account.email,
        status
      ))
    end
  end
  
  -- Display in floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, status_lines)
  
  local width = 50
  local height = #status_lines
  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = 'minimal',
    border = 'rounded'
  })
  
  vim.keymap.set('n', 'q', ':close<CR>', { buffer = buf })
  vim.keymap.set('n', '<Esc>', ':close<CR>', { buffer = buf })
end

-- Commands
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaOAuthSetup', function(opts)
    local email = opts.args
    if email == "" then
      vim.ui.input({
        prompt = "Email address: "
      }, function(input)
        if input then
          M.setup_oauth(input)
        end
      end)
    else
      M.setup_oauth(email)
    end
  end, {
    nargs = '?',
    desc = "Set up OAuth for an email account"
  })
  
  vim.api.nvim_create_user_command('HimalayaOAuthStatus', function()
    M.show_oauth_status()
  end, {
    desc = "Show OAuth token status for all accounts"
  })
  
  vim.api.nvim_create_user_command('HimalayaOAuthRevoke', function(opts)
    local email = opts.args
    if email == "" then
      -- Show menu of accounts
      local accounts = require('neotex.plugins.tools.himalaya.core.accounts').get_accounts()
      local items = {}
      for id, account in pairs(accounts) do
        if oauth_providers.supports_oauth(account.email) then
          table.insert(items, account.email)
        end
      end
      
      vim.ui.select(items, {
        prompt = "Revoke OAuth for account:"
      }, function(choice)
        if choice then
          local provider = accounts.get_account_by_email(choice).provider
          oauth_security.revoke_token(provider, choice)
        end
      end)
    else
      local account = require('neotex.plugins.tools.himalaya.core.accounts')
        .get_account_by_email(email)
      if account then
        oauth_security.revoke_token(account.provider, email)
      end
    end
  end, {
    nargs = '?',
    desc = "Revoke OAuth token for an account"
  })
end

return M
```

## Implementation Priorities

### Phase 1: Core Features (Week 1-2)
1. Multiple email accounts integration
2. OAuth & security improvements
3. Attachment support (download, view, add)
4. Basic image display
5. Address autocomplete

### Phase 2: Enhanced Features (Week 3)
1. Multi-account sync management
2. OAuth token management UI
3. Inline image rendering
4. Local trash system
5. Advanced attachment handling

### Phase 3: Polish (Week 4)
1. Account switching UI refinements
2. OAuth auto-refresh implementation
3. Custom headers
4. Performance optimizations
5. UI refinements

## Testing Strategy

### Unit Tests
- Test attachment parsing and handling
- Test address parsing and validation
- Test trash operations
- Test image format detection

### Integration Tests
- Test full email send with attachments
- Test address book population
- Test trash cleanup automation
- Test image display methods

### User Acceptance Tests
- Send email with multiple attachments
- Use address autocomplete in composition
- Delete and restore emails from trash
- View emails with inline images

## Success Metrics

1. **Multiple Accounts**: Support 5+ email accounts with seamless switching
2. **OAuth Security**: Encrypted token storage with automatic refresh
3. **Attachment Support**: Successfully send/receive emails with attachments
4. **Image Display**: Display images in at least 2 terminal types
5. **Address Autocomplete**: < 100ms completion response time
6. **Trash System**: Reliable deletion and optional restoration
7. **Custom Headers**: Support for arbitrary X- headers
8. **Account Sync**: Parallel sync of all accounts < 30s for 5 accounts
9. **OAuth Providers**: Support Gmail, Outlook, and Yahoo OAuth flows

## Risk Mitigation

1. **Terminal Compatibility**: Graceful fallback for image display
2. **Performance**: Cache attachments and images locally
3. **Data Loss**: Always backup to trash before deletion
4. **Security**: Validate all file paths and content types