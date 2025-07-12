# Fix Draft Issues

## Issues Fixed

### 1. Empty Draft Creation
**Problem**: When closing a draft without content, an empty draft was created in the Drafts folder.

**Solution**: 
- Removed immediate save on draft creation (was saving empty drafts)
- Added content check in `cleanup_draft` - empty drafts are deleted instead of synced
- Check for meaningful content: subject, to, or body with non-whitespace characters

### 2. [No Name] Buffer Issue
**Problem**: Closing drafts left behind [No Name] buffers

**Solution**:
- Enhanced `close_compose_buffer` to detect tab-only buffers and use `tabclose`
- Added `BufWipeout` autocmd to clean up empty tabs
- Added keymaps: `<leader>q` to close draft, `<leader>s` to send and close
- Added commands: `:HimalayaClose`, `:HimalayaSend`, `:HimalayaSave`

### 3. Draft Reopening Error
**Problem**: Error "attempt to call field 'reopen_draft' (a nil value)"

**Solution**:
- Fixed function name from `reopen_draft` to `open_draft`
- Added account parameter to the call

## How It Works Now

1. **Creating Draft**: 
   - New drafts are not saved immediately
   - Autosave kicks in only after user adds content

2. **Closing Draft**:
   - Empty drafts are deleted completely
   - Non-empty drafts are saved to Drafts folder
   - Tab closes properly without leaving [No Name] buffer

3. **Opening Draft**:
   - Press Enter on draft in sidebar to open for editing
   - Draft content is properly loaded including body

## Usage Tips

- Use `<leader>q` to close a draft properly
- Use `<leader>s` to send email and close
- Use `:HimalayaClose` command as alternative
- Empty drafts won't clutter your Drafts folder