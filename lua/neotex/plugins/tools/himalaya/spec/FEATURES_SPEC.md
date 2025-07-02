# Himalaya Future Features Specification

This document outlines planned features and enhancements for the Himalaya email plugin. These features are organized by priority and complexity.

## High Priority Features

### 1. Enhanced UI/UX Features
- **Hover Preview**: Preview emails in a second sidebar when hovering
- **Buffer-based Composition**: Compose/reply/forward emails in regular buffers
  - Auto-save to drafts folder
  - Delete drafts when discarding
- **Improved Confirmations**: Use return/escape for confirmation dialogs
- **Accurate Email Count**: Fix "Page 1 | 200 emails" to reflect actual count
- **Remove Noisy Messages**: Remove "Himalaya closed" notification

### 2. Email Management Features
- **Attachment Support**: View and manage email attachments
- **Image Display**: Inline image viewing in emails
- **Custom Headers**: Add custom header fields to emails
- **Address Autocomplete**: Complete addresses in format "Name <user@domain>"
- **Local Trash System**: 
  - Move deleted emails to local trash
  - Mappings for viewing and recovering trash
  - Automatic trash cleanup
- **Himalaya FAQ Features**: Implement remaining features from [Himalaya FAQ](https://github.com/pimalaya/himalaya?tab=readme-ov-file#faq)

### 3. Sync Improvements
- **Remove Fast Sync**: Simplify to single sync mechanism ✅ COMPLETE
- **Smart Sync Status**: Enhanced sidebar status for sync operations
- **Auto-sync on Start**: Automatic sync when nvim opens
- **Sync Error Recovery**: Automatic recovery from UIDVALIDITY issues

## Medium Priority Features

### 4. Code Quality Improvements
- **Enhanced Error Handling Module** (`core/errors.lua`):
  - Centralized error types and codes
  - Consistent error wrapping with context
  - Error recovery strategies
  - Integration with logging and notifications

- **API Consistency Layer**:
  - Standardize function return values (success, result, error)
  - Implement consistent parameter validation
  - Add type annotations for better IDE support
  - Create module facades to hide implementation details

- **Performance Optimizations**:
  - Add lazy loading for heavy modules
  - Implement caching for repeated operations
  - Optimize state persistence (currently saves entire UI state)
  - Profile and optimize slow operations

### 5. Developer Experience
- **Testing Infrastructure**:
  - Create `test/` directory with unit tests
  - Add integration test suite for critical paths
  - Implement mock modules for external dependencies
  - Add performance benchmarks

- **Observability**:
  - Enhanced logging with configurable log levels
  - Add performance timing for slow operations
  - Create debug mode with detailed operation traces
  - Add health metrics collection

- **Further Modularization**:
  - Split `commands.lua` (1293 lines) by functionality
  - Further modularize `ui/main.lua` (1025 lines)
  - Create focused modules for specific features

## Low Priority Features

### 6. Advanced Features
- **Multiple Account Views**: View emails from multiple accounts simultaneously
- **Advanced Search**: Full-text search with filters and operators
- **Email Templates**: Save and use email templates
- **Scheduling**: Schedule emails to send later
- **Encryption**: PGP/GPG email encryption support
- **Rules and Filters**: Client-side email filtering rules

### 7. Integration Features
- **Calendar Integration**: View and respond to calendar invites
- **Contact Management**: Integrated address book
- **Task Integration**: Convert emails to tasks
- **Note Taking**: Attach notes to emails
- **External Tool Integration**: Integration with external email tools

## Implementation Notes

### From TODO.md
The following features were originally planned and should be considered:
- Improved confirmations using return/escape keys
- Remove unnecessary notifications (e.g., "Himalaya closed")
- Fix email count display accuracy
- Implement attachment support
- Add image viewing capabilities
- Create local trash system with recovery options
- Address autocomplete in "Name <email>" format

### Technical Debt
- Fix TODO in `ui/email_list.lua` line 81 (maildir check implementation)
- Resolve backup directory execution issue (found during refactoring)
- Standardize all error handling patterns
- Complete migration to unified notification system

## Priority Guidelines

When implementing these features:
1. Maintain compatibility with existing functionality
2. Follow established architectural patterns
3. Use the unified notification system consistently
4. Add appropriate debug notifications for troubleshooting
5. Write comprehensive documentation for new features
6. Consider performance impact of new features
7. Maintain clean separation between layers (Core � Service � UI)