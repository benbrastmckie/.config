# Configuration Unit Tests

Unit tests for the modular configuration system.

## Test Files

### test_accounts.lua
Tests for account management functionality including:
- Account initialization and switching
- Email address retrieval and formatting
- Display name handling
- mbsync configuration
- Account updates

### test_folders.lua
Tests for folder mapping and maildir path management:
- IMAP to local folder name mapping
- Maildir path construction
- Special folder identification
- Folder existence checks
- Dynamic folder mapping updates

### test_oauth.lua
Tests for OAuth configuration and credential management:
- OAuth detection and initialization
- Environment variable credential retrieval
- Refresh command configuration
- Credential validation
- Auto-refresh settings

### test_ui.lua
Tests for UI preferences and keybindings:
- Settings initialization and merging
- Nested setting access
- Confirmation requirements
- Dynamic setting updates
- Keybinding retrieval

### test_validation.lua
Tests for configuration validation and migration:
- Account validation rules
- Draft configuration validation
- Sync settings validation
- UI settings validation
- Configuration migration
- Migration detection

## Test Coverage

These tests ensure:
- Module isolation and independence
- Correct default value handling
- Proper configuration merging
- Error detection and reporting
- Backward compatibility through migration
- API stability for dependent modules

## Navigation
- [← Unit Tests](../README.md)
- [← Test Suite](../../README.md)