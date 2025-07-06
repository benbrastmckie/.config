# Himalaya Technical Debt & Refactoring Specification

This document provides a comprehensive analysis of technical debt in the Himalaya email plugin and defines a systematic refactoring plan to improve code quality, maintainability, and performance while preserving all existing functionality.

## Executive Summary

Analysis of the Himalaya codebase reveals **84 TODO comments** across 23 files, representing significant technical debt that should be addressed through systematic refactoring. The debt falls into 5 priority categories ranging from critical architecture issues to future enhancements.

## Technical Debt Analysis

### Debt Categories by Priority

| Priority | Category | TODOs | Impact | Effort |
|----------|----------|-------|--------|---------|
| 1 | Critical Architecture & Performance | 11 | High | Medium |
| 2 | Major Feature Gaps | 18 | High | High |
| 3 | Developer Experience | 18 | Medium | Medium |
| 4 | UI Polish & Enhancement | 24 | Low | High |
| 5 | Documentation & Tooling | 13 | Low | Low |

### Debt Distribution by Module

| Module | TODOs | Primary Issues |
|--------|-------|----------------|
| `/ui/` | 34 | UI enhancements, window management, customization |
| `/core/` | 16 | Command organization, state management, logging |
| `/sync/` | 12 | Queue management, retry logic, OAuth improvements |
| `/setup/` | 9 | Multi-provider support, automation, diagnostics |
| `/scripts/` | 10 | OAuth security, multi-provider support |
| `/docs/` | 3 | Installation guides, help system |

## Refactoring Plan

*Note: The items below have been mapped to the overall project phases 6-10. Each section indicates which implementation phase it belongs to.*

### Phase 6 Items: Event System & Architecture Foundation (Priority 1)

*These critical architecture and performance items should be addressed in Phase 6 alongside the event system implementation.*

**Goal**: Establish robust foundation for future development
**Estimated Effort**: 2-3 weeks

#### 1.1 Command System Refactoring [→ Phase 7]

*Note: While critical, this refactoring is the primary focus of Phase 7 to avoid conflicts with Phase 6 work.*
- **File**: `core/commands.lua`
- **Issue**: 1,400+ line monolithic command registry
- **Solution**: 
  ```lua
  core/commands/
   ui.lua         -- UI commands (Himalaya, HimalayaToggle, etc.)
   email.lua      -- Email operations (Send, Draft, Discard)
   sync.lua       -- Sync commands (SyncInbox, SyncFull, etc.)
   setup.lua      -- Setup and maintenance commands
   init.lua       -- Command registration and validation
  ```
- **Benefits**: Better organization, easier maintenance, faster loading


#### 1.2 State Management Improvements [→ Phase 6]
- **File**: `core/state.lua`
- **Issue**: No migration system, potential corruption, no cleanup
- **Solution**:
  ```lua
  local STATE_VERSION = 3
  
  function M.migrate_state(from_version, to_version)
    -- Handle state format changes between versions
  end
  
  function M.validate_state(state_data)
    -- Validate state structure and values
  end
  
  function M.cleanup_stale_entries()
    -- Remove old/invalid state entries
  end
  ```
- **Benefits**: Robust state handling, prevents corruption, easier updates

#### 1.3 Error Handling Standardization [→ Phase 6]
- **New File**: `core/errors.lua`
- **Issue**: Inconsistent error handling across modules
- **Solution**:
  ```lua
  local ERROR_TYPES = {
    SYNC_FAILED = 'sync_failed',
    OAUTH_EXPIRED = 'oauth_expired',
    NETWORK_ERROR = 'network_error',
    -- ... more error types
  }
  
  function M.wrap_error(error_type, message, context)
    -- Standardized error wrapping with context
  end
  
  function M.handle_error(error, recovery_strategy)
    -- Centralized error handling with recovery
  end
  ```
- **Benefits**: Consistent error handling, better debugging, user-friendly messages

### Phase 8 Items: Core Email Features (Priority 2)

*These major feature gaps align with the core email features planned for Phase 8.*

**Goal**: Complete missing functionality essential for production use
**Estimated Effort**: 4-5 weeks

#### 2.1 Email Composition Enhancements
- **Files**: `ui/email_composer.lua`, new `core/attachments.lua`
- **Missing Features**: Attachments, address book, templates, spell check
- **Implementation Strategy**:
  1. Create attachment handling system
  2. Implement address book integration
  3. Add template and signature management
  4. Integrate spell checking (via external tools)

#### 2.2 Email Preview Improvements
- **File**: `ui/email_preview.lua`
- **Missing Features**: Inline images, HTML rendering, content sanitization
- **Implementation Strategy**:
  1. Add secure HTML rendering (sandboxed)
  2. Implement inline image display
  3. Add content sanitization for security
  4. Improve caching with smart invalidation

#### 2.3 Email List Management
- **File**: `ui/email_list.lua`
- **Missing Features**: Search, threading, sorting, virtual scrolling
- **Implementation Strategy**:
  1. Implement search and filtering system
  2. Add email threading/conversation view
  3. Create sortable columns (date, sender, subject, size)
  4. Add virtual scrolling for large lists

#### 2.4 Missing Command Implementations
- **File**: `core/commands.lua`
- **Missing Commands**: Account switcher, trash viewer, trash stats
- **Implementation Strategy**:
  1. Complete account switching functionality
  2. Implement trash management system
  3. Add trash statistics and cleanup

### Phase 7 & 9 Items: Developer Experience (Priority 3)

*These developer experience improvements are split between Phase 7 (logging/utilities) and Phase 9 (UI components).*

**Goal**: Improve development workflow and debugging capabilities
**Estimated Effort**: 2-3 weeks

#### 3.1 Enhanced Logging System [→ Phase 7]
- **File**: `core/logger.lua`
- **Improvements**: Rotation, performance timing, filtering, buffering
- **Implementation Strategy**:
  ```lua
  local logger_config = {
    max_file_size = 10 * 1024 * 1024,  -- 10MB
    max_files = 5,
    buffer_size = 100,
    filters = { 'debug', 'sync', 'ui' },
  }
  
  function M.setup_rotation()
    -- Implement log file rotation
  end
  
  function M.time_operation(name, operation)
    -- Add performance timing helpers
  end
  ```

#### 3.2 Utility Function Enhancements [→ Phase 7]
- **File**: `utils.lua`
- **Improvements**: Better caching, parallel operations, validation
- **Implementation Strategy**:
  1. Implement TTL and LRU caching for emails
  2. Add parallel email fetching capabilities
  3. Create comprehensive validation functions
  4. Add attachment handling utilities

#### 3.3 Setup System Automation [→ Phase 7]
- **Files**: `setup/wizard.lua`, `setup/health.lua`
- **Improvements**: Multi-provider support, automated diagnostics
- **Implementation Strategy**:
  1. Add support for Outlook, Yahoo, and other providers
  2. Implement automated OAuth credential setup
  3. Add network connectivity diagnostics
  4. Create automated fix suggestions

### Phase 9 & 10 Items: UI Polish & Security (Priority 4)

*UI improvements go in Phase 9, while OAuth/security items belong in Phase 10.*

**Goal**: Improve user interface and interaction quality
**Estimated Effort**: 3-4 weeks

#### 4.1 Window Management Improvements [→ Phase 9]
- **Files**: `ui/window_stack.lua`, `ui/sidebar.lua`
- **Improvements**: Better window coordination, persistence, customization
- **Implementation Strategy**:
  1. Extract window management into separate module
  2. Add centralized UI state coordination
  3. Implement window position memory
  4. Add sidebar themes and customization

#### 4.2 Notification System Integration [→ Phase 9]
- **File**: `ui/notifications.lua`
- **Improvements**: Integrate with neotex unified notification system
- **Implementation Strategy**:
  1. Migrate from direct vim.notify to neotex.util.notifications
  2. Implement proper notification categories (USER_ACTION, STATUS, BACKGROUND)
  3. Add himalaya-specific notification configuration
  4. Use existing batching and rate limiting from unified system

#### 4.3 OAuth & Security Improvements [→ Phase 10]
- **Files**: `sync/oauth.lua`, `scripts/*`
- **Improvements**: Multi-provider support, enhanced security
- **Implementation Strategy**:
  1. Add support for multiple OAuth providers
  2. Implement token encryption for security
  3. Add automatic token cleanup
  4. Create migration path to native Himalaya OAuth

### Phase 10 Items: Documentation & Tooling (Priority 5)

*Documentation and tooling improvements are part of the final polish in Phase 10.*

**Goal**: Complete documentation and improve developer tooling
**Estimated Effort**: 1-2 weeks

#### 5.1 Documentation Completion
- **Files**: Various `README.md` files
- **Improvements**: Complete gaps, add guides, improve examples
- **Implementation Strategy**:
  1. Add command auto-completion for folders and accounts
  2. Create platform-specific setup guides
  3. Add installation verification scripts
  4. Implement comprehensive help system

## Implementation Guidelines

### Code Quality Standards

1. **No Breaking Changes**: All refactoring must preserve existing functionality
2. **Incremental Approach**: Implement changes in small, testable increments
3. **Comprehensive Testing**: Each phase requires thorough testing before proceeding
4. **Documentation Updates**: Keep documentation in sync with code changes

### Refactoring Principles

1. **Single Responsibility**: Each module should have a clear, focused purpose
2. **Dependency Injection**: Use dependency injection to improve testability
3. **Error-First Design**: All operations should handle failures gracefully
4. **Performance Awareness**: Profile and optimize performance-critical paths

### Success Metrics

- **Code Coverage**: Maintain existing functionality without regressions
- **Performance**: No significant performance degradation
- **Maintainability**: Reduced cyclomatic complexity, improved modularity
- **Developer Experience**: Faster development cycles, better debugging

## Risk Assessment

### High Risk Items
- **Sync System Changes**: Critical functionality that could break email operations
- **State Management**: Changes could cause data loss or corruption
- **OAuth Integration**: Authentication failures could lock out users

### Mitigation Strategies
- **Comprehensive Backup**: Create backup and rollback mechanisms
- **Feature Flags**: Use feature flags for risky changes
- **Gradual Rollout**: Test changes thoroughly before full deployment
- **User Communication**: Clearly communicate any breaking changes

## Conclusion

This technical debt specification provides a roadmap for systematically improving the Himalaya email plugin while maintaining its current functionality. The phased approach allows for manageable implementation while ensuring quality and stability.

The refactoring effort will result in:
- **Better Architecture**: More modular, maintainable codebase
- **Enhanced Features**: Complete missing functionality
- **Improved Performance**: Better caching, parallel operations, optimizations
- **Developer Experience**: Better tooling, debugging, and documentation
- **Future-Proof Design**: Foundation for adding new features

By following this specification, the Himalaya plugin will become a robust, maintainable, and feature-complete email solution for Neovim users.
