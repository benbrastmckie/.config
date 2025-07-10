# Save and Return to Drafts Feature Specification

> **Feature Request**: Enable easy return to old drafts by hitting 'return' to preview, then 'return' again to reopen the draft in a compose buffer. Should only work for drafts, not regular emails.

## Overview

This specification outlines the implementation of enhanced draft management functionality that allows users to easily reopen and continue editing previously saved drafts directly from the sidebar.

## Current State Analysis

### Draft Storage Architecture
- **Local Storage**: Drafts stored in `~/.local/share/himalaya/drafts/` as `.eml` files
- **Naming Convention**: `draft_YYYYMMDD_HHMMSS.eml` format
- **Maildir Sync**: Drafts synced to maildir using `utils.save_draft()` ’ `himalaya message save --folder Drafts`
- **Folder Detection**: `utils.find_draft_folder()` handles folder mapping and defaults to 'Drafts'

### Current Sidebar Behavior
- **Email Display**: All emails (including drafts) displayed identically in sidebar
- **Return Key**: Two-stage preview system (enable preview ’ focus preview)
- **No Draft Distinction**: Drafts appear as regular emails without special handling

### Email Composer System
- **Buffer Creation**: `email_composer.lua` creates buffers with `mail` filetype
- **Content Parsing**: `parse_email_buffer()` handles email header/body parsing
- **Buffer Management**: `composer_buffers` tracks active compose sessions

## Feature Requirements

### Functional Requirements

1. **Draft Detection**
   - Automatically detect when user is viewing drafts folder
   - Distinguish draft emails from regular emails in sidebar
   - Visual indicators for draft emails

2. **Enhanced Return Key Behavior**
   - For regular emails: Current two-stage preview behavior
   - For drafts: First return shows preview, second return opens for editing
   - Context-sensitive behavior based on email type

3. **Draft Reopening**
   - Parse existing draft content (headers, body)
   - Create new compose buffer with restored content
   - Proper cursor positioning in appropriate field
   - Maintain all composer functionality (auto-save, etc.)

4. **UI Enhancements**
   - Draft-specific footer commands
   - Visual distinction in sidebar
   - Context-sensitive help text

### Non-Functional Requirements

1. **Performance**: Draft detection should not impact sidebar load times
2. **Reliability**: Robust error handling for corrupted or missing drafts
3. **Consistency**: Maintain existing UI patterns and behaviors
4. **Compatibility**: Work with existing draft saving and composer systems

## Implementation Plan

### Phase 1: Draft Detection and Display Enhancement

#### 1.1 Enhance Email List Formatting (`ui/email_list.lua`)

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/email_list.lua`

**Changes Required**:
```lua
-- Add draft detection logic to format_email_list()
local function format_email_list(emails, config)
  -- ... existing code ...
  
  -- Check if current folder is draft folder
  local current_folder = state.get_current_folder()
  local draft_folder = utils.find_draft_folder(state.get_current_account())
  local is_draft_folder = current_folder == draft_folder
  
  for i, email in ipairs(emails) do
    -- ... existing formatting ...
    
    -- Add draft indicator
    if is_draft_folder then
      display_line = " " .. display_line
      
      -- Store draft metadata
      lines.metadata[i] = vim.tbl_extend("force", lines.metadata[i] or {}, {
        is_draft = true,
        draft_folder = draft_folder
      })
    end
    
    -- ... rest of formatting ...
  end
end
```

#### 1.2 Update Sidebar Footer (`core/config.lua`)

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/core/config.lua`

**Changes Required**:
```lua
-- Update footer display logic
local function update_sidebar_footer()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local metadata = lines.metadata and lines.metadata[current_line]
  
  if metadata and metadata.is_draft then
    -- Draft-specific footer
    footer_text = "return:edit  esc:close  gD:delete"
  else
    -- Regular email footer
    footer_text = "return:preview  esc:close  gD:delete  gA:archive  gS:spam"
  end
  
  -- Update footer display
  update_footer_display(footer_text)
end
```

### Phase 2: Draft Reopening Logic

#### 2.1 Modify Return Key Handler (`core/config.lua`)

**Enhanced Logic**:
```lua
-- Enhanced return key handling
keymap('n', '<CR>', function()
  -- Handle scheduled emails first
  if handle_scheduled_email_return() then return end
  
  -- Check if current email is a draft
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local metadata = lines.metadata and lines.metadata[current_line]
  
  if metadata and metadata.is_draft then
    -- Draft-specific handling
    if not preview.is_preview_enabled() then
      -- First return: show preview
      preview.enable_preview()
    else
      -- Second return: open for editing
      M.reopen_draft()
    end
  else
    -- Regular email handling
    if not preview.is_preview_enabled() then
      preview.enable_preview()
    else
      preview.focus_preview()
    end
  end
end, opts)
```

#### 2.2 Implement Draft Reopening (`ui/email_composer.lua`)

**New Function**:
```lua
-- Reopen existing draft for editing
function M.reopen_draft()
  local main = require('neotex.plugins.tools.himalaya.ui.main')
  local email_id = main.get_current_email_id()
  
  if not email_id then
    notify.himalaya('No draft selected', notify.categories.ERROR)
    return
  end
  
  -- Fetch draft content from maildir
  local account = state.get_current_account()
  local draft_folder = utils.find_draft_folder(account)
  
  local success, draft_content = pcall(utils.get_email_content, account, draft_folder, email_id)
  if not success or not draft_content then
    notify.himalaya('Failed to load draft content', notify.categories.ERROR)
    return
  end
  
  -- Parse draft content
  local lines = vim.split(draft_content, '\n')
  local email = parse_email_buffer(lines)
  
  -- Create compose buffer with existing content
  local opts = {
    to = email.to,
    cc = email.cc,
    bcc = email.bcc,
    subject = email.subject,
    body = email.body,
    is_draft_reopen = true,
    original_draft_id = email_id
  }
  
  local buf = M.create_compose_buffer(opts)
  
  -- Position cursor appropriately
  position_cursor_for_draft(buf, email)
  
  notify.himalaya('Draft reopened for editing', notify.categories.STATUS)
  
  return buf
end
```

## Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Implement draft detection logic
- [ ] Add visual indicators to sidebar
- [ ] Update footer display system
- [ ] Basic draft metadata storage

### Phase 2: Core Functionality (Week 1)
- [ ] Modify return key handling
- [ ] Implement `reopen_draft()` function
- [ ] Add draft content parsing
- [ ] Create compose buffer integration

### Phase 3: Polish and Testing (Week 1)
- [ ] Enhanced error handling
- [ ] Configuration options
- [ ] Comprehensive testing
- [ ] Documentation updates

## Files Modified

### Primary Changes
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/email_list.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/core/config.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/email_composer.lua`

### Supporting Changes
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/utils.lua` (if needed)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/core/state.lua` (metadata handling)

## Success Criteria

1. **Functional Success**
   - Drafts visually distinguished in sidebar
   - Return key works differently for drafts vs regular emails
   - Draft content successfully parsed and restored
   - Compose buffer created with existing content
   - Proper cursor positioning based on content

2. **Quality Success**
   - No performance degradation in sidebar
   - Robust error handling for edge cases
   - Consistent with existing UI patterns
   - Comprehensive test coverage

## Related Specifications

- [EMAIL_MANAGEMENT_FEATURES_SPEC.md](EMAIL_MANAGEMENT_FEATURES_SPEC.md) - Email composition and management
- [ENHANCED_UI_UX_SPEC.md](done/ENHANCED_UI_UX_SPEC.md) - UI/UX patterns and consistency
- [ARCHITECTURE_REFACTOR_SPEC.md](ARCHITECTURE_REFACTOR_SPEC.md) - System architecture and integration

---

*This specification provides a comprehensive roadmap for implementing elegant draft management functionality that enhances the user experience while maintaining system reliability and performance.*
