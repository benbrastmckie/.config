# Himalaya Clean Up and Refinement Specification

This specification details the cleanup and refinement tasks identified in the technical debt analysis, focusing on architecture improvements, code organization, and system standardization. These items are mapped to the overall implementation phases 6-10.

## Items for Phase 6: Event System & Architecture Foundation

*Note: These critical architecture and performance improvements should be implemented alongside the event system in Phase 6.*

### 1.1 Command System Refactoring [→ Phase 7] ✅ COMPLETE

*Note: While listed here for context, the command system refactoring is the primary deliverable for Phase 7.*

**Current State**: 
- ✓ Commands now split into logical modules
- ✓ Modular registration system implemented
- ✓ Easy to navigate and maintain

**Implementation Plan**:

1. **Create Command Module Structure**
   ```
   core/commands/
   ├── init.lua         # Command registration and validation
   ├── ui.lua          # UI commands (Himalaya, HimalayaToggle, etc.)
   ├── email.lua       # Email operations (Send, Draft, Discard)
   ├── sync.lua        # Sync commands (SyncInbox, SyncFull, etc.)
   └── setup.lua       # Setup and maintenance commands
   ```

2. **Module Implementation Details**:
   
   **init.lua**:
   ```lua
   local M = {}
   
   -- Command registry
   local commands = {}
   
   function M.register(name, handler, options)
     commands[name] = {
       handler = handler,
       options = options or {}
     }
   end
   
   function M.setup()
     -- Load all command modules
     require('neotex.plugins.tools.himalaya.core.commands.ui').setup(M)
     require('neotex.plugins.tools.himalaya.core.commands.email').setup(M)
     require('neotex.plugins.tools.himalaya.core.commands.sync').setup(M)
     require('neotex.plugins.tools.himalaya.core.commands.setup').setup(M)
     
     -- Register all commands with vim
     for name, cmd in pairs(commands) do
       vim.api.nvim_create_user_command(name, cmd.handler, cmd.options)
     end
   end
   
   return M
   ```

3. **Migration Steps**:
   - Extract UI-related commands to `ui.lua`
   - Extract email operations to `email.lua`
   - Extract sync operations to `sync.lua`
   - Extract setup/config commands to `setup.lua`
   - Update all internal references
   - Test each command group independently

### 1.2 State Management Improvements [→ Phase 6] ✅ COMPLETE

**Current State**:
- ✓ Migration system implemented in Phase 6
- ✓ State versioning and validation added
- ✓ Cleanup of stale entries implemented

**Implementation Plan**:

1. **Add State Versioning**:
   ```lua
   local STATE_VERSION = 3
   
   local state_schema = {
     version = STATE_VERSION,
     accounts = {},
     folders = {},
     emails = {},
     ui = {},
     sync = {}
   }
   ```

2. **Implement Migration System**:
   ```lua
   local migrations = {
     [1] = function(state)
       -- Migrate from v1 to v2
       state.sync = state.sync or {}
       return state
     end,
     [2] = function(state)
       -- Migrate from v2 to v3
       if state.emails then
         for _, email in pairs(state.emails) do
           email.cached_at = email.cached_at or os.time()
         end
       end
       return state
     end
   }
   
   function M.migrate_state(state)
     local current_version = state.version or 1
     
     while current_version < STATE_VERSION do
       if migrations[current_version] then
         state = migrations[current_version](state)
       end
       current_version = current_version + 1
     end
     
     state.version = STATE_VERSION
     return state
   end
   ```

3. **Add State Validation**:
   ```lua
   function M.validate_state(state)
     -- Check required fields
     if not state.version then
       return false, "Missing state version"
     end
     
     -- Validate structure
     for key, expected_type in pairs({
       accounts = "table",
       folders = "table",
       emails = "table"
     }) do
       if state[key] and type(state[key]) ~= expected_type then
         return false, string.format("Invalid type for %s", key)
       end
     end
     
     return true
   end
   ```

4. **Implement Cleanup**:
   ```lua
   function M.cleanup_stale_entries()
     local state = M.get()
     local now = os.time()
     local stale_threshold = 7 * 24 * 60 * 60 -- 7 days
     
     -- Clean old email cache
     if state.emails then
       for id, email in pairs(state.emails) do
         if email.cached_at and (now - email.cached_at) > stale_threshold then
           state.emails[id] = nil
         end
       end
     end
     
     M.save(state)
   end
   ```

### 1.3 Error Handling Standardization [→ Phase 6] ✅ COMPLETE

**Current State**:
- ✓ Standardized error handling implemented in Phase 6
- ✓ Comprehensive error types and recovery strategies added
- ✓ Rich context in error messages with user-friendly display

**Implementation Plan**:

1. **Create Error Types Module**:
   ```lua
   -- core/errors.lua
   local M = {}
   
   M.types = {
     -- Network errors
     NETWORK_ERROR = 'network_error',
     CONNECTION_TIMEOUT = 'connection_timeout',
     
     -- Authentication errors
     AUTH_FAILED = 'auth_failed',
     OAUTH_EXPIRED = 'oauth_expired',
     INVALID_CREDENTIALS = 'invalid_credentials',
     
     -- Sync errors
     SYNC_FAILED = 'sync_failed',
     SYNC_CONFLICT = 'sync_conflict',
     
     -- UI errors
     WINDOW_CREATION_FAILED = 'window_creation_failed',
     INVALID_BUFFER = 'invalid_buffer',
     
     -- Configuration errors
     CONFIG_INVALID = 'config_invalid',
     ACCOUNT_NOT_FOUND = 'account_not_found'
   }
   
   M.severity = {
     FATAL = 'fatal',      -- Unrecoverable, requires restart
     ERROR = 'error',      -- Recoverable with user intervention
     WARNING = 'warning',  -- Degraded functionality
     INFO = 'info'        -- Informational only
   }
   
   return M
   ```

2. **Implement Error Wrapper**:
   ```lua
   function M.wrap_error(error_type, message, context)
     return {
       type = error_type,
       message = message,
       context = context or {},
       timestamp = os.time(),
       stack = debug.traceback()
     }
   end
   ```

3. **Add Recovery Strategies**:
   ```lua
   local recovery_strategies = {
     [M.types.OAUTH_EXPIRED] = function(error)
       -- Trigger OAuth refresh
       require('neotex.plugins.tools.himalaya.sync.oauth').refresh_token()
     end,
     
     [M.types.CONNECTION_TIMEOUT] = function(error)
       -- Retry with exponential backoff
       local retry_count = error.context.retry_count or 0
       if retry_count < 3 then
         vim.defer_fn(function()
           error.context.retry_callback()
         end, math.pow(2, retry_count) * 1000)
       end
     end,
     
     [M.types.INVALID_BUFFER] = function(error)
       -- Close invalid window and recreate
       if error.context.window_id then
         pcall(vim.api.nvim_win_close, error.context.window_id, true)
       end
     end
   }
   
   function M.handle_error(error, custom_recovery)
     -- Log error
     require('neotex.plugins.tools.himalaya.core.logger').error(
       string.format("[%s] %s", error.type, error.message),
       error.context
     )
     
     -- Notify user via unified notification system
     local notify = require('neotex.util.notifications')
     local category = error.severity == M.severity.FATAL 
       and notify.categories.ERROR 
       or notify.categories.WARNING
     
     notify.himalaya(error.message, category, error.context)
     
     -- Execute recovery strategy
     local recovery = custom_recovery or recovery_strategies[error.type]
     if recovery then
       recovery(error)
     end
   end
   ```

## Items for Phase 7: Command System & API Consistency ✅ COMPLETE

*Note: These developer experience improvements align with the command system refactoring in Phase 7.*

### 3.1 Enhanced Logging System ✅ COMPLETE

**Current State**:
- ✓ Structured logging with handlers implemented
- ✓ Performance timing utilities added
- ✓ Advanced filtering and querying capabilities

**Implementation Plan**:

1. **Add Log Rotation**:
   ```lua
   local logger_config = {
     max_file_size = 10 * 1024 * 1024,  -- 10MB
     max_files = 5,
     current_file = 1,
     base_path = vim.fn.stdpath('data') .. '/himalaya/logs/'
   }
   
   function M.rotate_logs()
     local current_path = M.get_log_path()
     local size = vim.fn.getfsize(current_path)
     
     if size > logger_config.max_file_size then
       -- Rotate files
       for i = logger_config.max_files - 1, 1, -1 do
         local old = logger_config.base_path .. 'himalaya.' .. i .. '.log'
         local new = logger_config.base_path .. 'himalaya.' .. (i + 1) .. '.log'
         vim.fn.rename(old, new)
       end
       
       -- Move current to .1
       vim.fn.rename(current_path, logger_config.base_path .. 'himalaya.1.log')
       
       -- Create new log file
       M.init_log_file()
     end
   end
   ```

2. **Add Performance Timing**:
   ```lua
   function M.time_operation(name, operation)
     local start_time = vim.loop.hrtime()
     
     local success, result = pcall(operation)
     
     local duration = (vim.loop.hrtime() - start_time) / 1e6 -- Convert to ms
     
     M.debug(string.format("Operation '%s' took %.2fms", name, duration), {
       operation = name,
       duration_ms = duration,
       success = success
     })
     
     if not success then
       error(result)
     end
     
     return result
   end
   ```

3. **Implement Log Filtering**:
   ```lua
   local log_filters = {
     debug = true,
     sync = true,
     ui = true,
     email = true,
     performance = false
   }
   
   function M.set_filter(category, enabled)
     log_filters[category] = enabled
   end
   
   function M.should_log(category)
     return log_filters[category] ~= false
   end
   ```

### 3.2 Utility Function Enhancements ✅ COMPLETE

**Current State**:
- ✓ Advanced caching with TTL implemented
- ✓ Async and promise utilities added
- ✓ Comprehensive validation functions added

**Implementation Plan**:

1. **Implement TTL Cache**:
   ```lua
   local cache = {
     entries = {},
     ttl = 300 -- 5 minutes default
   }
   
   function M.cache_get(key)
     local entry = cache.entries[key]
     if entry then
       if os.time() - entry.timestamp < cache.ttl then
         return entry.value
       else
         cache.entries[key] = nil
       end
     end
     return nil
   end
   
   function M.cache_set(key, value, custom_ttl)
     cache.entries[key] = {
       value = value,
       timestamp = os.time(),
       ttl = custom_ttl or cache.ttl
     }
   end
   
   function M.cache_clear_expired()
     local now = os.time()
     for key, entry in pairs(cache.entries) do
       if now - entry.timestamp >= (entry.ttl or cache.ttl) then
         cache.entries[key] = nil
       end
     end
   end
   ```

2. **Add Parallel Operations**:
   ```lua
   function M.parallel_fetch_emails(email_ids, fetch_func)
     local results = {}
     local completed = 0
     local total = #email_ids
     
     for _, id in ipairs(email_ids) do
       vim.schedule(function()
         local success, result = pcall(fetch_func, id)
         results[id] = success and result or nil
         completed = completed + 1
         
         if completed == total then
           -- All operations complete
           vim.schedule(function()
             M.on_parallel_complete(results)
           end)
         end
       end)
     end
   end
   ```

3. **Add Comprehensive Validation**:
   ```lua
   local validators = {
     email = function(value)
       return value:match("^[%w._%+-]+@[%w.-]+%.[%w]+$") ~= nil
     end,
     
     folder = function(value)
       local valid_folders = {'INBOX', 'Sent', 'Drafts', 'Trash', 'Spam'}
       return vim.tbl_contains(valid_folders, value)
     end,
     
     account = function(value)
       local config = require('neotex.plugins.tools.himalaya.core.config')
       return config.get_account(value) ~= nil
     end
   }
   
   function M.validate(type, value)
     local validator = validators[type]
     if validator then
       return validator(value)
     end
     return false
   end
   ```

### 3.3 Setup System Automation

**Current State**:
- Limited provider support
- Manual setup process
- Basic diagnostics

**Implementation Plan**:

1. **Automated Diagnostics**:
   ```lua
   function M.run_diagnostics()
     local diagnostics = {
       himalaya_installed = M.check_himalaya_binary(),
       network_connectivity = M.check_network(),
       oauth_configured = M.check_oauth_setup(),
       accounts_valid = M.validate_accounts(),
       permissions = M.check_permissions()
     }
     
     local fixes = {}
     
     if not diagnostics.himalaya_installed then
       table.insert(fixes, {
         issue = "Himalaya binary not found",
         fix = "Install himalaya: cargo install himalaya"
       })
     end
     
     if not diagnostics.network_connectivity then
       table.insert(fixes, {
         issue = "Network connectivity issue",
         fix = "Check internet connection and firewall settings"
       })
     end
     
     return diagnostics, fixes
   end
   ```

## Items for Phase 9: Advanced Features & UI Evolution

*Note: These UI polish and enhancement items should be implemented during the UI evolution work in Phase 9.*

### 4.1 Window Management Improvements

**Current State**:
- Window management scattered across modules
- No position persistence
- Limited customization

**Implementation Plan**:

1. **Extract Window Manager Module**:
   ```lua
   -- ui/window_manager.lua
   local M = {}
   
   local windows = {}
   local layouts = {}
   
   function M.register_window(name, config)
     windows[name] = {
       config = config,
       state = {
         open = false,
         window_id = nil,
         buffer_id = nil,
         position = config.default_position
       }
     }
   end
   
   function M.open_window(name, options)
     local window = windows[name]
     if not window then
       error("Unknown window: " .. name)
     end
     
     -- Merge options with saved position
     local final_options = vim.tbl_extend('force', 
       window.config,
       window.state.position or {},
       options or {}
     )
     
     -- Create window
     local buf = vim.api.nvim_create_buf(false, true)
     local win = vim.api.nvim_open_win(buf, true, final_options)
     
     -- Update state
     window.state.open = true
     window.state.window_id = win
     window.state.buffer_id = buf
     
     -- Set up autocmd to save position on close
     vim.api.nvim_create_autocmd("WinClosed", {
       pattern = tostring(win),
       once = true,
       callback = function()
         M.save_window_position(name)
         window.state.open = false
       end
     })
     
     return win, buf
   end
   
   function M.save_window_position(name)
     local window = windows[name]
     if window and window.state.window_id then
       local win_id = window.state.window_id
       if vim.api.nvim_win_is_valid(win_id) then
         window.state.position = {
           row = vim.api.nvim_win_get_position(win_id)[1],
           col = vim.api.nvim_win_get_position(win_id)[2],
           width = vim.api.nvim_win_get_width(win_id),
           height = vim.api.nvim_win_get_height(win_id)
         }
         
         -- Persist to state
         local state = require('neotex.plugins.tools.himalaya.core.state')
         state.set('ui.window_positions.' .. name, window.state.position)
       end
     end
   end
   ```

### 4.2 Notification System Integration

**Current State**:
- Direct vim.notify usage
- No integration with unified system
- Limited configuration

**Implementation Plan**:

1. **Migrate to Unified System**:
   ```lua
   -- ui/notifications.lua
   local notify = require('neotex.util.notifications')
   
   local M = {}
   
   -- Map old notification calls to new system
   function M.info(message, context)
     notify.himalaya(message, notify.categories.STATUS, context)
   end
   
   function M.success(message, context)
     notify.himalaya(message, notify.categories.USER_ACTION, context)
   end
   
   function M.error(message, context)
     notify.himalaya(message, notify.categories.ERROR, context)
   end
   
   function M.background(message, context)
     notify.himalaya(message, notify.categories.BACKGROUND, context)
   end
   ```

2. **Add Himalaya-specific Configuration**:
   ```lua
   -- In neotex/config/notifications.lua
   modules = {
     himalaya = {
       email_operations = true,     -- Show send/delete/move
       background_sync = false,     -- Hide cache updates
       connection_status = false,   -- Hide IMAP status
       pagination = false,          -- Hide page navigation
       setup_wizard = true,         -- Show setup progress
       oauth_status = true          -- Show OAuth operations
     }
   }
   ```


## Items for Phase 10: Security, Polish & Integration

*Note: These documentation and tooling items should be completed as part of the final polish in Phase 10.*

### 5.1 Documentation Completion

**Implementation Plan**:

1. **Add Command Auto-completion**:
   ```lua
   -- In command registration
   vim.api.nvim_create_user_command('Himalaya', function(opts)
     require('neotex.plugins.tools.himalaya').open(opts.args)
   end, {
     nargs = '?',
     complete = function(arg_lead, cmd_line, cursor_pos)
       -- Complete folder names
       local folders = {'INBOX', 'Sent', 'Drafts', 'Trash', 'Spam'}
       return vim.tbl_filter(function(folder)
         return folder:lower():match('^' .. arg_lead:lower())
       end, folders)
     end
   })
   
   vim.api.nvim_create_user_command('HimalayaSend', function(opts)
     require('neotex.plugins.tools.himalaya').send(opts.args)
   end, {
     nargs = '?',
     complete = function(arg_lead, cmd_line, cursor_pos)
       -- Complete account names
       local config = require('neotex.plugins.tools.himalaya.core.config')
       local accounts = vim.tbl_keys(config.get().accounts or {})
       return vim.tbl_filter(function(account)
         return account:lower():match('^' .. arg_lead:lower())
       end, accounts)
     end
   })
   ```

2. **Platform-Specific Setup Guides**:
   ```lua
   -- setup/platform_guides.lua
   local guides = {
     darwin = {
       title = "macOS Setup Guide",
       steps = {
         "Install Himalaya: brew install himalaya",
         "Install OAuth helper: brew install python3",
         "Set up keychain access for secure storage",
         "Configure firewall exceptions if needed"
       }
     },
     linux = {
       title = "Linux Setup Guide",
       steps = {
         "Install Himalaya: cargo install himalaya",
         "Install dependencies: apt install python3 python3-pip",
         "Set up gnome-keyring or similar for secure storage",
         "Configure SELinux/AppArmor if applicable"
       }
     },
     windows = {
       title = "Windows Setup Guide",
       steps = {
         "Install Himalaya via cargo or download binary",
         "Install Python from python.org",
         "Configure Windows Defender exceptions",
         "Set up Windows Credential Manager"
       }
     }
   }
   
   function M.show_platform_guide()
     local platform = vim.loop.os_uname().sysname:lower()
     local guide = guides[platform] or guides.linux
     
     -- Display guide in floating window
     local buf = vim.api.nvim_create_buf(false, true)
     local lines = {guide.title, ""}
     for i, step in ipairs(guide.steps) do
       table.insert(lines, string.format("%d. %s", i, step))
     end
     
     vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
     
     local width = 60
     local height = #lines + 2
     vim.api.nvim_open_win(buf, true, {
       relative = 'editor',
       width = width,
       height = height,
       col = (vim.o.columns - width) / 2,
       row = (vim.o.lines - height) / 2,
       style = 'minimal',
       border = 'rounded'
     })
   end
   ```

## Implementation Guidelines

### Testing Strategy

1. **Unit Tests**: Test each refactored module independently
2. **Integration Tests**: Test command execution end-to-end
3. **Performance Tests**: Measure impact of changes
4. **User Acceptance**: Test with real email workflows

### Rollout Plan

1. **Phase 1 (Week 1-2)**: Critical architecture improvements
2. **Phase 3 (Week 3-4)**: Developer experience enhancements
3. **Phase 4 (Week 5-6)**: UI polish and integration
4. **Phase 5 (Week 7)**: Documentation and final testing

### Success Metrics

- **Code Quality**: 30% reduction in cyclomatic complexity
- **Performance**: No degradation in operation speed
- **Reliability**: 50% reduction in error reports
- **Maintainability**: Clear module boundaries and dependencies
- **Developer Experience**: Comprehensive logging and debugging tools

### Risk Mitigation

1. **Feature Flags**: Use configuration to enable/disable new features
2. **Gradual Migration**: Refactor one module at a time
3. **Backward Compatibility**: Maintain old command names as aliases
4. **Comprehensive Testing**: Test each change thoroughly
5. **User Communication**: Document all changes clearly
