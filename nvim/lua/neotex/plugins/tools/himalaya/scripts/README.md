# Scripts Directory

Utility scripts, OAuth token management, and testing tools for the Himalaya email plugin.

## Purpose

This directory contains:
- **OAuth2 token management** for Gmail and other providers
- **Testing and validation tools** for plugin functionality
- **Utility scripts** for maintenance and debugging
- **Integration bridges** between Neovim plugin and external tools

## Current Scripts (Post-Phase 8 Implementation)

The scripts directory contains two main categories of tools:

**Testing & Validation:**
- `test_commands.lua` - Tests all core Himalaya commands and Phase 6 features  
- `test_phase8.lua` - Interactive testing for Phase 8 features (accounts, attachments, etc.)
- `demo_phase8.lua` - Feature demonstration and usage examples

**OAuth Token Management:**
- `refresh-gmail-oauth2` - Standard Gmail OAuth token refresh
- `refresh-himalaya-oauth2` - Multi-account OAuth wrapper
- `refresh-himalaya-oauth2-direct` - Direct OAuth implementation
- `check-himalaya-tokens.sh` - Token validation and debugging

## Scripts

### test_commands.lua
**Comprehensive Command Test Suite**
- Tests all Himalaya commands and Phase 6 implementations (Event System, Error Handling, State Management)
- Validates backward compatibility with existing functionality
- Verifies integration between new and existing systems
- **Runs silently** and displays results in a single floating window
- **Usage**: `:HimalayaTestCommands` or `:lua require('neotex.plugins.tools.himalaya.scripts.test_commands').run_all_tests()`
- **Auto-prompted** after successful health check completion

### test_phase8.lua
**Interactive Phase 8 Feature Test Suite**
- Interactive Telescope-based menu for testing all Phase 8 features
- Tests multiple accounts, attachments, trash, headers, images, and contacts
- Individual feature tests or run all tests with real-time feedback
- Shows available Phase 8 commands with descriptions
- Provides immediate pass/fail notifications during testing
- **Usage**: `:HimalayaTestPhase8`

Test options:
1. 📧 Test Multiple Account Support - Account switching and unified inbox
2. 📎 Test Attachment Features - View, download, and save attachments  
3. 🗑️ Test Trash System - Move to trash, recover, and empty
4. 📋 Test Custom Headers - Header validation and viewing
5. 🖼️ Test Image Display - Terminal image rendering capabilities
6. 👥 Test Contact Management - Add, search, and scan contacts
7. 🚀 Run All Tests - Execute all tests sequentially with summary
8. 📖 Show Available Commands - Display all Phase 8 commands

Features:
- Real-time notifications for each test result (works with debug mode off)
- Summary reporting with pass/fail counts
- Error details for failed tests
- Fallback to vim.ui.select if Telescope not available

### demo_phase8.lua
**Phase 8 Feature Demo and Documentation**
- Comprehensive demo showing how to use all Phase 8 features
- Example commands with explanations
- Tips and best practices
- Module verification utility
- **Usage**: `:HimalayaDemoPhase8`

Demonstrates:
- Multiple account management with unified views
- Attachment handling workflow
- Trash system operations
- Email header inspection
- Terminal image display setup
- Contact management and autocomplete

### refresh-gmail-oauth2
Standard OAuth refresh script for Gmail accounts:
- Refreshes access tokens using stored refresh tokens
- Uses `gmail-smtp-oauth2-*` token naming pattern for storage
- Required for Gmail SMTP authentication in email sending
- Handles OAuth2 flow with Google's authentication servers

Usage: `refresh-gmail-oauth2`

Dependencies: System keychain or token file storage

<!-- TODO: Add token expiration checking before refresh -->
<!-- TODO: Implement retry logic for network failures -->

### refresh-himalaya-oauth2
Wrapper script for refreshing OAuth tokens for any Himalaya account:
- Supports multiple account configurations (Gmail, IMAP, etc.)
- Account-specific token management with custom naming
- Fallback handling when account-specific refresh fails
- Integration with Himalaya account configuration

Usage: `refresh-himalaya-oauth2 [account-name]`

Examples:
- `refresh-himalaya-oauth2` - Refreshes default gmail account
- `refresh-himalaya-oauth2 gmail-imap` - Refreshes gmail-imap account
- `refresh-himalaya-oauth2 work` - Refreshes work account tokens

<!-- TODO: Add support for non-Gmail OAuth providers -->
<!-- TODO: Implement parallel token refresh for multiple accounts -->

### refresh-himalaya-oauth2-direct
Direct OAuth refresh implementation without wrapper dependencies:
- Standalone implementation for cases where wrapper fails
- Direct API calls to OAuth providers
- Minimal dependencies for debugging purposes
- Alternative when system keychain is unavailable

Usage: `refresh-himalaya-oauth2-direct [account-name]`

<!-- TODO: Add configuration validation before refresh -->
<!-- TODO: Implement secure token storage fallback -->

### check-himalaya-tokens.sh
Token validation and debugging utility:
- Checks token expiration and validity
- Validates token format and structure
- Reports token storage locations and permissions
- Debugging information for OAuth issues

Usage: `check-himalaya-tokens.sh [account-name]`

Features:
- Token expiration time calculation
- Storage location verification
- Keychain accessibility testing
- OAuth configuration validation

<!-- TODO: Add token refresh time recommendations -->
<!-- TODO: Implement automatic token cleanup for expired entries -->

## OAuth Token Flow

The complete OAuth authentication and refresh cycle:

1. **Initial Setup**: User authenticates via browser OAuth flow
2. **Token Storage**: Refresh tokens stored securely (keychain/file)
3. **Access Token Request**: Short-lived access tokens requested as needed
4. **Automatic Refresh**: Scripts refresh tokens before expiration (~1 hour)
5. **Plugin Integration**: Refreshed tokens used for email operations
6. **Error Handling**: Failed refreshes trigger re-authentication flow

## Storage Mechanisms

Token storage varies by platform:
- **macOS**: macOS Keychain with secure item storage
- **Linux**: Secret Service API or encrypted file storage
- **Windows**: Windows Credential Manager
- **Fallback**: Encrypted file-based storage

## Integration with Plugin

The scripts integrate with the plugin through:
- **sync/oauth.lua**: Calls refresh scripts when tokens expire
- **setup/wizard.lua**: Uses scripts during initial OAuth setup
- **Automatic calls**: Background refresh during email operations
- **Error recovery**: Re-authentication when refresh fails

## Platform Considerations

### NixOS Users
- May require different token storage paths
- Need to ensure scripts are in PATH
- May need to configure keychain alternatives

### Security Notes
- Refresh tokens are long-lived and must be protected
- Access tokens are short-lived but should not be logged
- File-based storage should use appropriate permissions (600)
- Network traffic should be over HTTPS only

## Debugging OAuth Issues

Common OAuth problems and solutions:

```bash
# Check token status
./check-himalaya-tokens.sh gmail

# Manual token refresh
./refresh-himalaya-oauth2 gmail

# Debug direct refresh
./refresh-himalaya-oauth2-direct gmail

# Check token file permissions
ls -la ~/.config/himalaya/tokens/
```

## Future Migration

These scripts are temporary solutions:
- **Target**: Native OAuth support in Himalaya CLI
- **Timeline**: When Himalaya CLI implements token refresh
- **Migration**: Automatic migration to native OAuth handling
- **Compatibility**: Maintain compatibility during transition

<!-- TODO: Create migration script for native Himalaya OAuth -->
<!-- TODO: Add compatibility detection for Himalaya CLI versions -->

## Usage Examples

```bash
# Basic token refresh
refresh-himalaya-oauth2

# Account-specific refresh
refresh-himalaya-oauth2 work-gmail

# Check all tokens
check-himalaya-tokens.sh

# Direct refresh for troubleshooting
refresh-himalaya-oauth2-direct gmail

# Set up cron job for automatic refresh
# Add to crontab: */30 * * * * /path/to/refresh-himalaya-oauth2
```

## Error Codes

Scripts return these exit codes:
- `0`: Success
- `1`: General error
- `2`: Invalid arguments
- `3`: OAuth refresh failed
- `4`: Token storage error
- `5`: Network connectivity issue

## Navigation
- [< Himalaya Plugin](../README.md)
