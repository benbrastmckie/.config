# Research Report: Task #76

**Task**: Fix multiple Himalaya sidebar errors
**Date**: 2026-02-13
**Focus**: Root cause analysis of reply/forward/reply_all "Email not found" errors and "unrecognized subcommand 'send'" error

## Summary

The reported issues have two distinct root causes: (1) Reply/forward functions fail because `utils.get_email_by_id()` uses the obsolete `envelope get` subcommand which does not exist in himalaya v1.1.0; (2) Email send fails because `utils.send_email()` uses the old `send` command syntax instead of the v1.1.0 `message send` command.

## Findings

### Issue 1: "Email not found (ID: X)" Error

**Root Cause**: In `lua/neotex/plugins/tools/himalaya/utils.lua` (lines 236-269), the `get_email_by_id()` function constructs the CLI command using:

```lua
-- Line 264-268
local args = { 'envelope', 'get', email_id }
return cli_utils.execute_himalaya(args, {
  account = account,
  folder = folder
})
```

However, **himalaya v1.1.0 does not have an `envelope get` subcommand**. The available envelope subcommands are:
- `envelope list` - List/search envelopes
- `envelope thread` - List envelopes in thread view

The `envelope get` command does not exist, causing the CLI to fail with an error that propagates as "Email not found".

**Evidence from CLI check**:
```
$ himalaya envelope --help
Commands:
  list    Search and sort envelopes as a list
  thread  Search and sort envelopes as a thread
  help    Print this message or the help of the given subcommand(s)
```

No `get` subcommand is present.

**Why ID 0**: When `get_current_email_id()` in `ui/main.lua` fails to find an email ID (due to the line_map being empty or cursor being on a header line), it returns `nil`, which gets converted to `0` when displayed in the error message.

**Why ID 2943**: When a valid email ID is passed to `get_email_by_id()`, the function correctly receives the ID but the CLI command fails because `envelope get` does not exist.

### Issue 2: "unrecognized subcommand 'send'" Error

**Root Cause**: In `lua/neotex/plugins/tools/himalaya/utils.lua` (lines 208-233), the `send_email()` function constructs the CLI command using:

```lua
-- Lines 222-227
local args = { 'send' }
local result = cli_utils.execute_himalaya(args, {
  account = account,
  show_loading = true,
  loading_msg = 'Sending email...'
})
```

However, **himalaya v1.1.0 requires the `message send` command** (not just `send`).

**Evidence from CLI check**:
```
$ himalaya --help
Commands:
  account     Configure, list and diagnose your accounts
  folder      Create, list and purge your folders
  envelope    List, search and sort your envelopes
  flag        Add, change and remove your envelopes flags
  message     Read, write, send, copy, move and delete your messages
  ...

$ himalaya message send --help
Send the given raw message.
Usage: himalaya message send [OPTIONS] [MESSAGE]...
```

The top-level `send` command does not exist in v1.1.0 - it is now nested under `message send`.

### CLI Version Compatibility Issue

The codebase was written for an older version of himalaya CLI (likely v0.x or v1.0.x) where commands had different structure. The current installed version is:

```
himalaya v1.1.0 +wizard +pgp-commands +oauth2 +sendmail +imap +smtp +keyring +maildir
```

### Affected Code Locations

1. **utils.lua:264** - `envelope get` (does not exist)
2. **utils.lua:222** - `send` (should be `message send`)
3. **utils.lua:199** - `message read` - appears correct
4. **utils.lua:417** - `message delete` - appears correct
5. **utils.lua:517** - `message move` - appears correct

### Correct v1.1.0 Command Syntax

| Old Syntax | New v1.1.0 Syntax |
|------------|-------------------|
| `envelope get <id>` | Does not exist - use cache or `message read` |
| `send` | `message send` |
| `message read <id>` | `message read <id>` (unchanged) |
| `message delete <id>` | `message delete <id>` (unchanged) |
| `message move <folder> <id>` | `message move <folder> <id>` (unchanged) |

### Current Workaround in get_email_by_id()

The function does check the cache first (lines 253-261):
```lua
-- Check cache first
local cache_key = account .. '|' .. folder
if email_cache[cache_key] then
  for _, email in ipairs(email_cache[cache_key]) do
    if email.id == email_id then
      return email
    end
  end
end
```

If the email is in the cache, it works. The failure occurs when:
1. The cache is empty or expired
2. The email ID is not in the cached results

### Email Object Structure

From the CLI output, emails have this structure:
```json
{
  "id": "2948",
  "flags": [],
  "subject": "...",
  "from": {"name": "...", "addr": "..."},
  "to": {"name": "...", "addr": "..."},
  "date": "2026-02-11 19:35+00:00",
  "has_attachment": false
}
```

For reply/forward, the code needs the full email body, which requires `message read <id>` to fetch.

## Recommendations

### Fix 1: Update send_email() Command (utils.lua)

Change line 222 from:
```lua
local args = { 'send' }
```
to:
```lua
local args = { 'message', 'send' }
```

### Fix 2: Update get_email_by_id() to Use message read

Since `envelope get` does not exist, the function should:
1. First check the cache (already implemented)
2. If not in cache, use `message read` to fetch the full email content
3. Parse the response to extract headers and body

Change lines 263-268 from:
```lua
-- Fetch from CLI
local args = { 'envelope', 'get', email_id }
return cli_utils.execute_himalaya(args, {
  account = account,
  folder = folder
})
```
to:
```lua
-- Fetch from CLI using message read
local args = { 'message', 'read', email_id }
local result = cli_utils.execute_himalaya(args, {
  account = account,
  folder = folder
})
if result then
  -- Parse result to extract email data for reply/forward
  return M.parse_message_read_result(result, email_id)
end
return nil
```

### Fix 3: Add parse_message_read_result() Helper

Create a helper function to parse the `message read` output and extract the fields needed for reply/forward operations:
- from, to, cc, subject, date
- message_id, references (for threading)
- body content

### Additional Consideration: Async CLI Module

The file `core/async_commands.lua` may also need updates if it constructs CLI commands directly. A grep search should be performed for any other locations using old command syntax.

## References

- Himalaya CLI v1.1.0 help output
- `lua/neotex/plugins/tools/himalaya/utils.lua` (main utilities)
- `lua/neotex/plugins/tools/himalaya/utils/cli.lua` (CLI execution)
- `lua/neotex/plugins/tools/himalaya/ui/main.lua` (reply/forward functions)
- Task #75 summary (related nil value fix)

## Next Steps

1. Update `utils.send_email()` to use `message send` command
2. Update `utils.get_email_by_id()` to use `message read` instead of non-existent `envelope get`
3. Add helper function to parse `message read` output for reply/forward operations
4. Test reply, reply_all, forward, and send operations
5. Search codebase for any other uses of old CLI syntax
