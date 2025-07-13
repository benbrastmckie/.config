-- Run draft migration
local migration = require('neotex.plugins.tools.himalaya.core.draft_migration')

if migration.needs_migration() then
  print("Starting draft migration...")
  local count = migration.migrate_eml_to_json()
  print(string.format("Migration complete: %d drafts migrated", count))
else
  print("No migration needed - all drafts already in JSON format")
end