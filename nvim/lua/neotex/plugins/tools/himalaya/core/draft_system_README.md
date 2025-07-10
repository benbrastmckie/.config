# Himalaya Draft System

## Overview

The draft system provides robust draft email management with automatic saving, caching, and synchronization with himalaya's maildir format. It addresses several limitations in the himalaya CLI through a comprehensive workaround architecture.

## Architecture

### Core Components

1. **Draft Manager** (`draft_manager.lua`)
   - Centralized state management for all draft buffers
   - Tracks buffer ID, draft ID, local ID, and content
   - Provides lookup by buffer ID, draft ID, or local ID

2. **ID Validator** (`id_validator.lua`)
   - Validates himalaya email IDs (numeric strings only)
   - Prevents folder names from being used as IDs
   - Provides sanitization with error handling

3. **Draft Parser** (`draft_parser.lua`)
   - State-machine based email parsing
   - Handles himalaya's display headers format
   - Cleans multipart markers and vim.NIL values

4. **Draft Cache** (`draft_cache.lua`)
   - Two-tier caching: persistent metadata + volatile content
   - Persists draft subjects across sessions
   - Provides fast lookups for sidebar display

5. **Retry Handler** (`retry_handler.lua`)
   - Exponential backoff with jitter
   - Handles himalaya lock conflicts
   - Distinguishes retryable vs permanent errors

## Key Features

### Automatic Draft Saving
- Drafts auto-save every 30 seconds when modified
- Local buffer tracked with unique local ID until synced
- Himalaya ID assigned after successful save

### Draft State Management
```lua
draft_state = {
  buffer_id = number,
  draft_id = string|nil,      -- Himalaya ID (nil until synced)
  local_id = string,          -- Temporary ID for tracking
  account = string,
  folder = string,
  content = {
    from = string,
    to = string,
    subject = string,
    body = string,
    headers = table
  },
  state = 'new'|'syncing'|'synced'|'sending',
  last_saved = timestamp,
  last_synced = timestamp
}
```

### Subject Caching
- Subjects cached when draft is saved
- Cache persists to `~/.cache/nvim/himalaya_draft_metadata.json`
- Sidebar checks cache before showing "(No subject)"

### Preview System
- Loads from draft manager first (if buffer is open)
- Falls back to cache, then himalaya
- Handles multipart content correctly

### Draft Cleanup
- Drafts deleted after successful send
- Retry logic for lock conflicts
- Cache and state cleaned up

## Usage

### Opening a Draft
```lua
local composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
composer.open_draft(account, draft_id)
```

### Creating New Draft
```lua
composer.compose({
  to = "recipient@example.com",
  subject = "Draft Test"
})
```

### Manual Save
```vim
:w  " or Ctrl+S - triggers draft save
```

## Debugging

### Check Draft State
```vim
:HimalayaDraftDebug state
```

### Inspect Cache
```vim
:HimalayaDraftDebug cache
```

### Validate System
```vim
:HimalayaDraftDebug validate
```

### Enable Debug Logging
```vim
:HimalayaLogLevel debug
```

## Known Limitations

1. **Draft Content Reading**: himalaya `message read` only returns headers for drafts. We work around this by reading directly from maildir when needed.

2. **Empty Subjects in List**: himalaya `envelope list` returns empty subjects for drafts. We maintain a separate cache for draft metadata.

3. **No Update Command**: himalaya has no draft update command. We must delete and recreate drafts on each save.

4. **Lock Conflicts**: Multiple simultaneous operations can cause "cannot open id mapper database" errors. We use retry logic with exponential backoff.

## Implementation Details

### Parser States
The draft parser uses these states:
- `INITIAL`: Before any content
- `HEADERS`: Parsing email headers
- `DISPLAY_DIVIDER`: Found `---` separator
- `DISPLAY_HEADERS`: Parsing display headers
- `BODY_SEPARATOR`: Empty line before body
- `BODY`: Parsing body content
- `MULTIPART`: Inside multipart section

### Cache Structure
```json
{
  "account@example.com": {
    "Drafts": {
      "12345": {
        "subject": "Draft Subject",
        "from": "sender@example.com",
        "to": "recipient@example.com",
        "date": "2025-01-09",
        "cached_at": 1704812400
      }
    }
  }
}
```

### Retry Configuration
```lua
{
  max_retries = 3,
  base_delay = 1000,      -- 1 second
  max_delay = 30000,      -- 30 seconds
  exponential_base = 2,
  jitter = true           -- ±25% randomization
}
```

## Testing

Run the comprehensive test suite:
```vim
:HimalayaTest test_draft_refactor
```

Individual test categories:
- Draft manager state tracking
- ID validation rules
- Parser edge cases
- Cache persistence
- Retry logic

## Future Improvements

When himalaya CLI limitations are addressed:
1. Remove direct maildir reading
2. Simplify subject caching
3. Use native draft update commands
4. Remove lock retry logic

See [DRAFT_SYSTEM_WORKAROUNDS.md](../docs/DRAFT_SYSTEM_WORKAROUNDS.md) for detailed workaround documentation.