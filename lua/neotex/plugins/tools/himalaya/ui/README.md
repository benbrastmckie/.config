# User Interface Components

Modular UI system for the Himalaya email plugin, providing email list display, composition, viewing, and interactive sidebar.

## Purpose

The UI layer provides the interactive interface for email operations:
- Modular design with focused components (list, viewer, composer)
- Sidebar-based email browsing with real-time updates
- Smart notification system with context-aware error handling
- Window and focus management for seamless navigation

## Modules

### main.lua
Central UI coordinator that orchestrates all interface components:
- Module initialization and dependency injection
- Shared utilities and buffer management
- Window creation and management (floating windows)
- Cross-module function delegation and exports
- Email operation coordination (delete, archive, spam)

Key functions:
- `init()` - Initialize all UI modules with proper dependencies
- `toggle_email_sidebar()` - Main entry point for email interface
- `open_email_window(buf, title)` - Create floating windows
- `close_himalaya()` - Clean shutdown of all UI components
- Delegation functions for email operations and navigation

<!-- TODO: Consider extracting window management into separate module -->
<!-- TODO: Add centralized UI state coordination -->

### email_list.lua
Email list display and management in sidebar format:
- Paginated email list with real-time sync status
- Email selection and batch operations
- Folder switching and account switching
- Sync progress display with elapsed time tracking
- Email metadata formatting and display

Key functions:
- `show_email_list(args)` - Display email list for folder/account
- `format_email_list(emails)` - Format emails for display
- `toggle_email_sidebar()` - Toggle sidebar visibility
- `refresh_email_list()` - Refresh current view
- Navigation: `next_page()`, `prev_page()`, `pick_folder()`

<!-- TODO: Add keyboard navigation within email list -->
<!-- TODO: Implement email preview on hover -->

### email_viewer.lua
Email reading and display functionality:
- Email content formatting and rendering
- Header display and toggling
- Attachment handling and URL extraction
- Reply and forward email preparation

Key functions:
- `read_email(email_id)` - Open email in reading view
- `read_current_email()` - Read email at cursor position
- `format_email_content(content)` - Format email for display
- `show_attachments(email_id)` - Display email attachments
- `open_link_under_cursor()` - Open URLs from email content

<!-- TODO: Add email search and filtering -->
<!-- TODO: Implement inline image display -->

### email_composer.lua
Email composition and editing functionality:
- New email composition with field navigation
- Reply and reply-all with proper formatting
- Forward emails with attachments
- Draft saving and restoration
- Field validation and completion

Key functions:
- `compose_email(to_address)` - Create new email
- `reply_email(email_id, reply_all)` - Reply to email
- `forward_email(email_id)` - Forward email
- `send_current_email()` - Send composed email
- `close_and_save_draft()` - Save as draft

<!-- TODO: Add attachment support for composition -->
<!-- TODO: Implement address book integration -->

### sidebar.lua
Neo-tree style sidebar implementation:
- Sidebar window management and configuration
- Content updates with syntax highlighting
- Email list rendering with selection indicators
- State persistence and window behavior

Key functions:
- `open()` - Create and display sidebar
- `close_and_cleanup()` - Close sidebar and clean state
- `update_content(lines)` - Update sidebar content
- `update_header_lines(lines)` - Optimized header updates
- State management: `is_open()`, `focus()`, `get_buf()`

<!-- TODO: Add sidebar resizing functionality -->
<!-- TODO: Implement sidebar themes and customization -->

### notifications.lua
Smart notification wrapper with error pattern recognition:
- Wraps the unified notification system
- Context-aware error handling and recovery suggestions
- Automatic OAuth refresh triggering
- Pattern-based error message translation

Key functions:
- `show(message, level, context)` - Smart notification with context
- `handle_oauth_error(error, context)` - OAuth-specific error handling
- Pattern recognition for common error types
- Integration with notify.himalaya() system

<!-- TODO: Add notification persistence and history -->
<!-- TODO: Implement user-configurable notification patterns -->

### window_stack.lua
Window focus and navigation management:
- Hierarchical window focus tracking
- Automatic focus restoration after operations
- Parent-child window relationships
- Clean window closure handling

Key functions:
- `push(window, parent)` - Add window to stack with parent
- `close_current()` - Close current window and restore focus
- `clear()` - Clear entire window stack
- Automatic focus restoration on window closure

<!-- TODO: Add window stack visualization for debugging -->
<!-- TODO: Implement window stack persistence across sessions -->

### float.lua
Floating window utilities for setup and dialogs:
- Floating window creation with customizable styling
- Modal dialog support for setup wizard
- Progress display windows for long operations
- Used by setup modules for configuration dialogs

Key functions:
- `create_float(opts)` - Create styled floating window
- `create_progress_window()` - Progress display window
- `close_float(win)` - Clean floating window closure

<!-- TODO: Add animation support for floating windows -->
<!-- TODO: Implement window position memory -->

### init.lua
UI module entry point and main interface export:
- Re-exports main functions for external access
- Provides backward compatibility interface
- Simple delegation to main.lua functions

## Architecture Notes

The UI layer follows these design principles:
- **Modular separation** - Each UI component is self-contained
- **Dependency injection** - Modules receive dependencies at initialization
- **Event coordination** - Main module coordinates cross-module operations
- **Focus management** - Proper window focus restoration
- **Real-time updates** - Live sync progress and status updates

## Module Dependencies

```
main.lua (coordinator)
├── email_list.lua (depends on: sidebar, state, notifications)
├── email_viewer.lua (depends on: window_stack, notifications)
├── email_composer.lua (depends on: window_stack, notifications)
├── sidebar.lua (standalone)
├── notifications.lua (depends on: core/logger)
├── window_stack.lua (standalone)
└── float.lua (standalone)
```

## Usage Examples

```lua
-- Initialize UI system
local ui = require("neotex.plugins.tools.himalaya.ui")
ui.init()

-- Main interface operations
ui.toggle_email_sidebar()  -- Open/close email interface
ui.show_email_list({'INBOX'})  -- Show specific folder

-- Direct module usage
local email_list = require("neotex.plugins.tools.himalaya.ui.email_list")
email_list.refresh_email_list()

local email_viewer = require("neotex.plugins.tools.himalaya.ui.email_viewer")
email_viewer.read_email("email-123")

local email_composer = require("neotex.plugins.tools.himalaya.ui.email_composer")
email_composer.compose_email("user@example.com")

-- Window management
local window_stack = require("neotex.plugins.tools.himalaya.ui.window_stack")
window_stack.push(new_window, parent_window)

-- Smart notifications
local notifications = require("neotex.plugins.tools.himalaya.ui.notifications")
notifications.show("Email sent successfully", "success", "compose")
```

## Navigation
- [← Himalaya Plugin](../README.md)