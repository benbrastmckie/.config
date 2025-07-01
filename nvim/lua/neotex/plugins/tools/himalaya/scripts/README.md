# OAuth and Utility Scripts

Helper scripts for OAuth token management and utilities.

## Scripts

### refresh-gmail-oauth2
Standard OAuth refresh script for Gmail accounts:
- Refreshes tokens for main Gmail account
- Uses `gmail-smtp-oauth2-*` token naming pattern
- Required for Gmail SMTP authentication

Usage: `refresh-gmail-oauth2`

### refresh-himalaya-oauth2
Wrapper script for refreshing OAuth tokens for any Himalaya account:
- Handles both Gmail and IMAP accounts
- Supports custom account names
- Wraps the standard refresh-gmail-oauth2 script

Usage: `refresh-himalaya-oauth2 [account-name]`

Examples:
- `refresh-himalaya-oauth2` - Refreshes main gmail account
- `refresh-himalaya-oauth2 gmail-imap` - Refreshes gmail-imap account

### refresh-himalaya-oauth2-direct
Direct OAuth refresh implementation:
- Alternative implementation for token refresh
- Used when wrapper script has issues

### check-himalaya-tokens.sh
Token validation script:
- Checks token expiration
- Validates token format
- Reports token status

## OAuth Token Flow

1. Initial authentication creates tokens
2. Tokens expire after ~1 hour
3. Scripts refresh tokens automatically
4. Plugin uses refreshed tokens for email operations

## Notes

- OAuth scripts will eventually be removed when Himalaya CLI handles token refresh natively
- NixOS users may need different paths for token storage
- Tokens are stored in system keychain when available

## Navigation
- [← Himalaya Plugin](../README.md)
