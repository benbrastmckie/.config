# Himalaya Plugin: Future Features Documentation

This document outlines the existing feature modules that represent future enhancements to the Himalaya email plugin. These modules are currently implemented but not fully integrated into the main plugin workflow. They serve as the foundation for future development phases.

## Overview

The `features/` directory contains six specialized modules that extend the core Himalaya functionality. These features are production-ready implementations that can be integrated when needed, providing advanced email management capabilities beyond basic email operations.

## Feature Modules

### 1. Multi-Account Management (`features/accounts.lua`)

**Status**: ✅ Fully Implemented, Ready for Integration

**Purpose**: Advanced multi-account email management with unified inbox and cross-account operations.

**Current Capabilities**:
- Dynamic account addition/removal at runtime
- Unified inbox view aggregating emails from all accounts
- Account state management (sync status, unread counts, folder structures)
- Cross-account email search and filtering
- Account-specific configuration management

**Integration Benefits**:
- Seamless switching between multiple email accounts
- Single interface for managing all email accounts
- Reduced cognitive load when working with multiple emails
- Unified search across all configured accounts

**Technical Details**:
- Uses event-driven architecture with `orchestrator` integration
- Maintains separate runtime state from static configuration
- Provides consistent API for account operations
- Includes comprehensive error handling and logging

**Future Integration Path**:
1. Add account selection UI to main sidebar
2. Integrate unified inbox view into main email list
3. Add account-specific indicators to email list
4. Implement cross-account search commands

---

### 2. Email Attachments (`features/attachments.lua`)

**Status**: ✅ Fully Implemented, Ready for Integration

**Purpose**: Comprehensive attachment handling for viewing, downloading, and managing email attachments.

**Current Capabilities**:
- Smart attachment viewer detection based on MIME types
- Local attachment cache with automatic cleanup
- Attachment metadata extraction and display
- Support for adding attachments to draft emails
- File size validation and format checking

**Integration Benefits**:
- Seamless attachment workflow within Neovim
- Efficient caching reduces redundant downloads
- Automatic viewer selection for different file types
- Enhanced draft composition with attachment support

**Technical Details**:
- Integrates with existing draft system through `state` module
- Uses standardized Himalaya command execution
- Provides comprehensive file operations and error handling
- Includes cache management and cleanup functionality

**Future Integration Path**:
1. Add attachment indicators to email list view
2. Implement attachment preview in email viewer
3. Add attachment management commands to main interface
4. Integrate with draft composer for attachment adding

---

### 3. Contact Management (`features/contacts.lua`)

**Status**: ✅ Fully Implemented, Ready for Integration

**Purpose**: Address autocomplete and contact management system with automatic contact extraction.

**Current Capabilities**:
- Automatic contact extraction from sent/received emails
- Contact database with frequency tracking and metadata
- Address autocomplete for email composition
- Contact import/export (CSV, JSON formats)
- Contact search and management operations

**Integration Benefits**:
- Intelligent address completion during email composition
- Automatic contact database building from email history
- Reduced typing and improved accuracy in email addressing
- Contact relationship tracking and frequency analysis

**Technical Details**:
- JSON-based contact database with efficient searching
- Email scanning integration through `utils.execute_himalaya`
- Configurable contact extraction and validation
- Comprehensive contact metadata management

**Future Integration Path**:
1. Integrate autocomplete into email composer interface
2. Add contact management commands to main command set
3. Implement contact-based email filtering and search
4. Add contact frequency indicators in composer

---

### 4. Advanced Email Headers (`features/headers.lua`)

**Status**: ✅ Fully Implemented, Ready for Integration

**Purpose**: Advanced email header management for custom headers, priority settings, and metadata.

**Current Capabilities**:
- Custom email header creation and management
- Header validation and formatting
- Preset header configurations (urgent, bulk, etc.)
- Context-aware header suggestions
- Integration with draft system for header application

**Integration Benefits**:
- Professional email metadata management
- Enhanced email organization and filtering capabilities
- Support for advanced email workflows and automation
- Improved email tracking and categorization

**Technical Details**:
- Comprehensive header validation against RFC standards
- Integration with draft system for seamless header application
- Configurable header presets and suggestions
- Protection against forbidden system headers

**Future Integration Path**:
1. Add header management to draft composer interface
2. Implement header presets in composition workflow
3. Add header-based email filtering and search
4. Integrate priority and metadata indicators in email list

---

### 5. Image Display (`features/images.lua`)

**Status**: ✅ Fully Implemented, Ready for Integration

**Purpose**: Terminal-based image display for email attachments with multiple protocol support.

**Current Capabilities**:
- Multi-protocol image display (Kitty, iTerm2, Sixel, Unicode blocks, ASCII)
- Automatic protocol detection and fallback handling
- Image resizing and format conversion
- Floating window display for text-based representations
- Comprehensive error handling for unsupported formats

**Integration Benefits**:
- Native image viewing within terminal environment
- Enhanced email experience for image-heavy communications
- Automatic optimization for different terminal capabilities
- Seamless integration with attachment workflow

**Technical Details**:
- Sophisticated protocol detection and capability assessment
- Image processing with multiple fallback options
- Temporary file management and cleanup
- Integration with attachment system for image downloads

**Future Integration Path**:
1. Integrate image preview into attachment viewer
2. Add image display commands to attachment interface
3. Implement inline image preview in email viewer
4. Add image-specific indicators in attachment lists

---

### 6. Alternative Views (`features/views.lua`)

**Status**: ⚠️ Wrapper Implementation, Needs Development

**Purpose**: Interface wrapper for alternative email view modes and multi-account displays.

**Current Capabilities**:
- Function stubs for unified inbox view
- Placeholder for split-view email management
- Interface for tabbed email browsing
- Framework for focused single-account views

**Integration Benefits**:
- Flexible email viewing modes for different workflows
- Enhanced productivity through optimized view layouts
- Support for different user preferences and use cases
- Consistent interface for view mode management

**Technical Details**:
- Currently acts as facade for `ui.multi_account` module
- Provides consistent API for future view implementations
- Designed for easy extension with new view modes
- Integration point for advanced UI layouts

**Future Development Path**:
1. Implement actual view mode switching logic
2. Develop split-view and tabbed interface layouts
3. Add view persistence and user preferences
4. Integrate with main UI for seamless view transitions

## Integration Architecture

### Common Integration Patterns

All feature modules follow consistent integration patterns:

1. **Configuration Integration**: Use `config` module for user preferences
2. **State Management**: Integrate with `state` module for runtime data
3. **Command Execution**: Standardize through `utils.execute_himalaya`
4. **Event System**: Emit events through `orchestrator` for cross-module communication
5. **Error Handling**: Use `logger` and `api` for consistent error management

### Initialization Sequence

Features are designed to integrate into the main plugin initialization:

```lua
-- In init.lua setup function
local features = {
  'accounts',
  'attachments', 
  'contacts',
  'headers',
  'images'
}

for _, feature in ipairs(features) do
  local feature_module = require('neotex.plugins.tools.himalaya.features.' .. feature)
  if feature_module.setup then
    feature_module.setup()
  end
end
```

### Command Integration

Each feature provides commands that can be registered in the main command system:

```lua
-- Example integration in commands/init.lua
local feature_commands = require('neotex.plugins.tools.himalaya.features.contacts').get_commands()
for name, command in pairs(feature_commands) do
  commands['HimalayaContact' .. name] = command
end
```

## Development Roadmap

### Phase 1: Core Feature Integration
- Integrate attachment handling into main email workflow
- Add contact autocomplete to email composer
- Implement basic multi-account switching

### Phase 2: Advanced UI Integration  
- Add image display to attachment viewer
- Implement advanced header management in composer
- Develop alternative view modes

### Phase 3: Workflow Optimization
- Cross-account search and filtering
- Advanced contact management interface
- Image and attachment workflow optimization

### Phase 4: Power User Features
- Custom header automation
- Advanced multi-account workflows
- Comprehensive contact relationship management

## Configuration

Each feature module includes its own configuration options that can be integrated into the main plugin configuration:

```lua
-- Example configuration integration
config = {
  features = {
    contacts = {
      auto_scan = true,
      auto_complete = true,
      frequency_tracking = true
    },
    attachments = {
      cache_size = "100MB",
      auto_preview = true,
      default_viewer = "auto"
    },
    images = {
      display_protocol = "auto",
      max_size = "1920x1080",
      ascii_fallback = true
    }
  }
}
```

## Testing

All feature modules include comprehensive testing capabilities:

- Unit tests for core functionality
- Integration tests with main plugin systems
- Error condition handling verification
- Performance testing for large datasets

## Conclusion

These feature modules represent a comprehensive set of advanced email management capabilities that can significantly enhance the Himalaya plugin's functionality. They are designed with clean integration patterns and can be implemented incrementally based on user needs and development priorities.

The modular architecture ensures that features can be enabled or disabled independently, allowing for flexible deployment and customization based on specific use cases and user preferences.