# OAuth and Utility Scripts

OAuth token management and utility scripts providing authentication support until native Himalaya CLI OAuth handling is available.

## Purpose

These scripts provide OAuth2 token management for Gmail and other providers:
- Automatic token refresh for expired credentials
- Cross-platform token storage and retrieval
- Debugging and validation utilities
- Integration bridge between Neovim plugin and external OAuth flows

## Scripts

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
- [← Himalaya Plugin](../README.md)
