# Multiple Account Views - Testing Guide

## Overview

The Multiple Account Views feature allows you to manage multiple email accounts simultaneously through different view modes. This guide will help you test and understand this feature.

## Prerequisites

1. **Multiple Email Accounts**: You need at least 2 configured email accounts in your Himalaya configuration
2. **Himalaya Plugin**: The plugin should be loaded and initialized
3. **Email Data**: Some emails in your accounts to see the views properly

## View Modes

### 1. Focused View (Default)
- **Description**: Single account view - the traditional Himalaya experience
- **Command**: `:HimalayaFocusedView`
- **Use Case**: When you want to focus on one account at a time

### 2. Unified Inbox
- **Description**: Combines emails from all accounts into a single sorted list
- **Command**: `:HimalayaUnifiedInbox`
- **Features**:
  - Emails sorted by date (newest first)
  - Account indicators `[ACC]` prefix for each email
  - Color-coded account indicators
  - Single sidebar showing total email count

### 3. Split View
- **Description**: Shows accounts side by side in vertical splits
- **Command**: `:HimalayaSplitView`
- **Features**:
  - Each account gets its own window
  - Windows are evenly sized
  - Can navigate between windows with standard Vim commands

### 4. Tabbed View
- **Description**: Each account in a separate tab
- **Command**: `:HimalayaTabbedView`
- **Features**:
  - Tab names show account names
  - Navigate with `:tabnext` / `:tabprevious`
  - Or use shortcuts mapped to the commands

## Commands Reference

### View Mode Commands
| Command | Description |
|---------|-------------|
| `:HimalayaUnifiedInbox` | Switch to unified inbox view |
| `:HimalayaSplitView` | Show accounts in split windows |
| `:HimalayaTabbedView` | Show accounts in tabs |
| `:HimalayaFocusedView` | Return to single account view |
| `:HimalayaToggleView` | Cycle through all view modes |

### Navigation Commands
| Command | Description |
|---------|-------------|
| `:HimalayaNextAccount` | Switch to next account (in focused/tabbed mode) |
| `:HimalayaPreviousAccount` | Switch to previous account (in focused/tabbed mode) |
| `:HimalayaRefreshAccounts` | Refresh all account views |
| `:HimalayaAccountStatus` | Show account configuration status |

## Testing Steps

### Step 1: Check Account Configuration
```vim
:HimalayaAccountStatus
```
This will show:
- All configured accounts
- Current view mode
- Number of active accounts

### Step 2: Test Unified Inbox
```vim
:HimalayaUnifiedInbox
```
What to verify:
- [ ] All accounts' emails appear in one list
- [ ] Emails are sorted by date (newest first)
- [ ] Account prefixes are visible (e.g., `[GMA]` for Gmail)
- [ ] Account prefixes have different colors
- [ ] Can select and read emails from any account

### Step 3: Test Split View
```vim
:HimalayaSplitView
```
What to verify:
- [ ] Each account gets its own window
- [ ] Windows are evenly sized
- [ ] Can navigate between windows with `<C-w>h` and `<C-w>l`
- [ ] Each window shows correct account emails
- [ ] Window titles show account names

### Step 4: Test Tabbed View
```vim
:HimalayaTabbedView
```
What to verify:
- [ ] Each account gets its own tab
- [ ] Tab labels show account names
- [ ] Can navigate with `:tabnext` and `:tabprevious`
- [ ] `:HimalayaNextAccount` switches tabs
- [ ] Each tab maintains its own cursor position

### Step 5: Test View Toggle
```vim
:HimalayaToggleView
```
What to verify:
- [ ] Cycles through: Focused → Unified → Split → Tabbed → Focused
- [ ] Each transition preserves email selection where possible
- [ ] No errors during transitions

### Step 6: Test Account Navigation (Focused Mode)
```vim
:HimalayaFocusedView
:HimalayaNextAccount
:HimalayaPreviousAccount
```
What to verify:
- [ ] Switches between accounts
- [ ] Shows notification with account name
- [ ] Email list updates to show new account
- [ ] Wraps around at the end of account list

## Configuration Options

Add these to your Himalaya setup:

```lua
require('neotex.plugins.tools.himalaya').setup({
  ui = {
    multi_account = {
      default_mode = 'focused',      -- Start mode: 'focused', 'unified', 'split', 'tabbed'
      unified_sort = 'date',         -- Sort order: 'date', 'account', 'subject'
      show_account_colors = true,    -- Enable account color coding
      account_abbreviation_length = 3, -- Length of account prefix (e.g., [GMA])
    },
  },
})
```

## Highlight Groups

The following highlight groups are defined for account colors:
- `HimalayaAccountRed`
- `HimalayaAccountGreen`
- `HimalayaAccountYellow`
- `HimalayaAccountBlue`
- `HimalayaAccountMagenta`
- `HimalayaAccountCyan`
- `HimalayaAccountOrange`
- `HimalayaAccountPurple`

You can customize these in your colorscheme or init.lua:
```lua
vim.api.nvim_set_hl(0, 'HimalayaAccountRed', { fg = '#ff0000' })
```

## Keybinding Suggestions

Add these to your config for easier navigation:

```lua
-- In your which-key or keymap configuration
vim.keymap.set('n', '<leader>hau', ':HimalayaUnifiedInbox<CR>', { desc = 'Unified inbox' })
vim.keymap.set('n', '<leader>has', ':HimalayaSplitView<CR>', { desc = 'Split view' })
vim.keymap.set('n', '<leader>hat', ':HimalayaTabbedView<CR>', { desc = 'Tabbed view' })
vim.keymap.set('n', '<leader>haf', ':HimalayaFocusedView<CR>', { desc = 'Focused view' })
vim.keymap.set('n', '<leader>hav', ':HimalayaToggleView<CR>', { desc = 'Toggle view mode' })
vim.keymap.set('n', '<leader>han', ':HimalayaNextAccount<CR>', { desc = 'Next account' })
vim.keymap.set('n', '<leader>hap', ':HimalayaPreviousAccount<CR>', { desc = 'Previous account' })
```

## Troubleshooting

### No Accounts Showing
1. Check `:HimalayaAccountStatus` to see configured accounts
2. Ensure accounts have email addresses configured
3. Check that accounts are properly set up in your Himalaya config

### Colors Not Showing
1. Ensure your terminal supports colors
2. Check that highlight groups are loaded: `:hi HimalayaAccountRed`
3. Try `:lua require('neotex.plugins.tools.himalaya.ui.highlights').setup()`

### Split View Issues
1. Ensure you have enough screen width
2. Try maximizing your terminal window
3. Check `:set columns` to see available width

### Performance Issues
1. Unified inbox may be slow with many emails
2. Consider limiting emails per account in config
3. Use focused view for better performance

## Known Limitations

1. **Sidebar Integration**: The sidebar update functionality is limited in multi-account views
2. **Email Operations**: Some operations (reply, forward) work on the current account context
3. **Sync**: Auto-sync still works per the coordinator system, not per-view
4. **Search**: Advanced search currently works within the active account only

## Testing Checklist

- [ ] All view modes load without errors
- [ ] Can switch between all view modes
- [ ] Unified inbox shows emails from all accounts
- [ ] Split view creates proper window layout
- [ ] Tabbed view creates tabs with proper labels
- [ ] Navigation commands work in each view mode
- [ ] Account colors are visible and distinct
- [ ] Email selection and reading works in all views
- [ ] View state persists during session
- [ ] No performance issues with your email volume

## Feedback

If you encounter issues or have suggestions:
1. Check the logs: `:HimalayaLogs`
2. Enable debug mode: `:HimalayaDebug`
3. Report specific error messages and steps to reproduce