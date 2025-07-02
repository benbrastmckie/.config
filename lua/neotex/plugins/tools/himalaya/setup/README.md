# Setup and Configuration

Setup, health check, and migration modules providing guided configuration, system validation, and version migration support.

## Purpose

The setup layer handles initial configuration and ongoing maintenance:
- Interactive setup wizard for new users
- Comprehensive health checking and diagnostics
- Automatic migration between plugin versions
- Recovery tools for configuration issues

## Modules

### wizard.lua
Interactive setup wizard for guided initial configuration:
- Step-by-step account creation with validation
- OAuth2 setup assistance with credential management
- Automatic mbsync configuration generation
- Maildir creation and UIDVALIDITY issue resolution
- Configuration validation and testing

Key functions:
- `run_setup_wizard()` - Main setup wizard entry point
- `setup_gmail_account()` - Gmail-specific setup flow
- `create_mbsync_config()` - Generate mbsync configuration
- `fix_uidvalidity_files()` - Resolve UIDVALIDITY sync issues
- `test_account_access()` - Validate account configuration

<!-- TODO: Add support for other email providers (Outlook, Yahoo, etc.) -->
<!-- TODO: Implement automated OAuth credential creation -->
<!-- TODO: Add maildir import from existing email clients -->

### health.lua
Comprehensive health check system for diagnosing configuration issues:
- External dependency verification (himalaya CLI, mbsync)
- Account configuration validation
- OAuth token health checking with refresh testing
- Maildir structure validation
- Network connectivity testing

Key functions:
- `check_all()` - Run complete health check suite
- `check_dependencies()` - Verify external tool availability
- `check_accounts()` - Validate all configured accounts
- `check_oauth_tokens()` - Test OAuth token validity
- `check_maildir_structure()` - Validate maildir setup

<!-- TODO: Add network connectivity diagnostics -->
<!-- TODO: Implement automated fix suggestions -->
<!-- TODO: Add performance benchmarking -->

### migration.lua
Handles configuration and state migration between plugin versions:
- Configuration format updates and schema validation
- State file structure migration
- Deprecated setting removal and replacement
- Automatic backup creation before migrations
- Rollback support for failed migrations

Key functions:
- `run_migrations()` - Execute all pending migrations
- `needs_migration()` - Check if migration is required
- `create_backup()` - Create pre-migration backup
- `rollback_migration()` - Restore from backup
- `validate_migrated_config()` - Verify migration success

<!-- TODO: Add migration progress tracking -->
<!-- TODO: Implement incremental migration system -->
<!-- TODO: Add migration dry-run mode -->

## Integration Points

The setup layer integrates with:
- **Core layer**: Uses config and state modules for validation
- **Sync layer**: Tests OAuth tokens and sync functionality  
- **UI layer**: Uses float.lua for setup dialogs
- **External tools**: Validates himalaya CLI and mbsync installations

## Error Recovery

The setup system provides recovery for these scenarios:
- Corrupted configuration files
- Invalid OAuth tokens
- Missing or broken mbsync configuration
- UIDVALIDITY sync conflicts
- Missing maildir structure

## Usage Examples

```lua
-- Complete setup wizard
local wizard = require("neotex.plugins.tools.himalaya.setup.wizard")
wizard.run_setup_wizard()

-- Setup specific account type
wizard.setup_gmail_account({
  email = "user@gmail.com",
  name = "Personal Gmail"
})

-- Fix UIDVALIDITY issues
wizard.fix_uidvalidity_files("/path/to/maildir")

-- Comprehensive health check
local health = require("neotex.plugins.tools.himalaya.setup.health")
local results = health.check_all()

-- Check specific components
local deps_ok = health.check_dependencies()
local accounts_ok = health.check_accounts()

-- Migration management
local migration = require("neotex.plugins.tools.himalaya.setup.migration")

-- Check and run migrations
if migration.needs_migration() then
  migration.create_backup()
  local success = migration.run_migrations()
  if not success then
    migration.rollback_migration()
  end
end
```

## Commands

The setup layer provides these commands:
- `:HimalayaSetup` - Run the setup wizard
- `:HimalayaHealth` - Perform health checks
- `:HimalayaFixUID` - Fix UIDVALIDITY issues
- `:checkhealth himalaya` - Neovim health check integration

## Configuration Examples

```lua
-- Manual account configuration
wizard.setup_gmail_account({
  name = "work",
  email = "user@company.com",
  maildir_path = "~/Mail/work",
  oauth = {
    client_id = "your_client_id",
    client_secret = "your_client_secret"
  }
})

-- Health check with custom validation
health.check_accounts({
  validate_connectivity = true,
  test_oauth_refresh = true,
  check_maildir_permissions = true
})
```

## Navigation
- [< Himalaya Plugin](../README.md)