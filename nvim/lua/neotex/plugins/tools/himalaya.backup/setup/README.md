# Setup and Configuration

Setup, health check, and migration modules for the Himalaya plugin.

## Modules

### wizard.lua
Interactive setup wizard for initial configuration:
- Account creation and configuration
- OAuth setup assistance
- mbsync configuration generation
- Validation of settings

Key functions:
- `run()` - Start the setup wizard
- `create_account(opts)` - Add new email account
- `validate_config()` - Check configuration validity

### health.lua
Health check system for diagnosing issues:
- Verifies himalaya CLI installation
- Checks mbsync availability
- Validates OAuth tokens
- Tests email account access
- Provides troubleshooting suggestions

Key functions:
- `check()` - Run all health checks
- `check_dependencies()` - Verify required tools
- `check_accounts()` - Validate account configurations

### migration.lua
Handles migration from older plugin versions:
- Configuration format updates
- State file migrations
- Deprecated setting conversions
- Backup creation before changes

Key functions:
- `run()` - Execute necessary migrations
- `needs_migration()` - Check if migration required
- `backup_config()` - Create configuration backup

## Usage Examples

```lua
-- Run setup wizard
local wizard = require("neotex.plugins.tools.himalaya.setup.wizard")
wizard.run()

-- Check plugin health
local health = require("neotex.plugins.tools.himalaya.setup.health")
health.check()

-- Run migrations
local migration = require("neotex.plugins.tools.himalaya.setup.migration")
if migration.needs_migration() then
  migration.run()
end
```

## Health Check

Run `:checkhealth himalaya` to diagnose configuration issues.

## Navigation
- [← Himalaya Plugin](../README.md)