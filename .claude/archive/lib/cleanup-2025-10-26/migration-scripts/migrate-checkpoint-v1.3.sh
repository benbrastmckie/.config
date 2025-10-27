#!/usr/bin/env bash
# Migrate checkpoint from v1.2 to v1.3
# Usage: migrate-checkpoint-v1.3.sh <checkpoint-file> [--dry-run]
#
# Adds new v1.3 fields:
# - topic_directory: Path to topic directory
# - topic_number: Topic number extracted from directory
# - context_preservation: Context pruning and metadata tracking
# - template_source: Template name if plan generated from template
# - template_variables: Variables used in template generation
# - spec_maintenance: Spec updater and checkbox propagation tracking

set -euo pipefail

# Check arguments
CHECKPOINT_FILE="${1:-}"
DRY_RUN=false

if [ -z "$CHECKPOINT_FILE" ]; then
  echo "Usage: $0 <checkpoint-file> [--dry-run]" >&2
  echo "" >&2
  echo "Migrates checkpoint from schema v1.2 to v1.3" >&2
  echo "  --dry-run: Show migration preview without applying changes" >&2
  exit 1
fi

if [ "${2:-}" = "--dry-run" ]; then
  DRY_RUN=true
fi

# Validate checkpoint file exists
if [ ! -f "$CHECKPOINT_FILE" ]; then
  echo "ERROR: Checkpoint file not found: $CHECKPOINT_FILE" >&2
  exit 1
fi

# Validate jq available
if ! command -v jq &> /dev/null; then
  echo "ERROR: jq is required for checkpoint migration" >&2
  exit 1
fi

# Validate JSON structure
if ! jq empty "$CHECKPOINT_FILE" 2>/dev/null; then
  echo "ERROR: Invalid JSON in checkpoint file: $CHECKPOINT_FILE" >&2
  exit 1
fi

# Check current schema version
CURRENT_VERSION=$(jq -r '.schema_version // "1.0"' "$CHECKPOINT_FILE")

if [ "$CURRENT_VERSION" != "1.2" ]; then
  echo "ERROR: This script migrates from v1.2 to v1.3" >&2
  echo "       Current checkpoint version: $CURRENT_VERSION" >&2
  if [ "$CURRENT_VERSION" = "1.3" ]; then
    echo "       Checkpoint is already at v1.3" >&2
    exit 0
  elif [ "$CURRENT_VERSION" = "1.0" ] || [ "$CURRENT_VERSION" = "1.1" ]; then
    echo "       Please upgrade to v1.2 first using migrate_checkpoint_format()" >&2
  fi
  exit 1
fi

# Perform migration
echo "=== Checkpoint Migration v1.2 → v1.3 ===" >&2
echo "" >&2
echo "Checkpoint: $CHECKPOINT_FILE" >&2
echo "Mode: $([ "$DRY_RUN" = true ] && echo 'DRY RUN (no changes)' || echo 'LIVE MIGRATION')" >&2
echo "" >&2

# Build migrated checkpoint
MIGRATED_CHECKPOINT=$(jq '. + {
  schema_version: "1.3",
  topic_directory: (if .workflow_state.topic_directory then .workflow_state.topic_directory else null end),
  topic_number: (if .workflow_state.topic_number then .workflow_state.topic_number else null end),
  context_preservation: (.context_preservation // {
    pruning_log: [],
    artifact_metadata_cache: {},
    subagent_output_references: []
  }),
  template_source: (if .workflow_state.template_source then .workflow_state.template_source else null end),
  template_variables: (if .workflow_state.template_variables then .workflow_state.template_variables else null end),
  spec_maintenance: (.spec_maintenance // {
    parent_plan_path: null,
    grandparent_plan_path: null,
    spec_updater_invocations: [],
    checkbox_propagation_log: []
  })
}' "$CHECKPOINT_FILE")

if [ "$DRY_RUN" = true ]; then
  echo "=== Migration Preview ===" >&2
  echo "" >&2
  echo "$MIGRATED_CHECKPOINT" | jq '{
    schema_version,
    topic_directory,
    topic_number,
    context_preservation,
    template_source,
    template_variables,
    spec_maintenance
  }'
  echo "" >&2
  echo "To apply migration, run without --dry-run flag" >&2
  exit 0
fi

# Create backup
BACKUP_FILE="${CHECKPOINT_FILE}.backup"
echo "Creating backup: $BACKUP_FILE" >&2
cp "$CHECKPOINT_FILE" "$BACKUP_FILE"

# Write migrated checkpoint
echo "$MIGRATED_CHECKPOINT" > "$CHECKPOINT_FILE"

# Validate migrated checkpoint
if ! jq empty "$CHECKPOINT_FILE" 2>/dev/null; then
  echo "" >&2
  echo "ERROR: Migration produced invalid JSON. Restoring from backup..." >&2
  cp "$BACKUP_FILE" "$CHECKPOINT_FILE"
  exit 1
fi

# Verify new fields present
NEW_VERSION=$(jq -r '.schema_version' "$CHECKPOINT_FILE")
if [ "$NEW_VERSION" != "1.3" ]; then
  echo "" >&2
  echo "ERROR: Migration failed - schema version not updated. Restoring from backup..." >&2
  cp "$BACKUP_FILE" "$CHECKPOINT_FILE"
  exit 1
fi

echo "" >&2
echo "=== Migration Complete ===" >&2
echo "" >&2
echo "Schema version: $CURRENT_VERSION → $NEW_VERSION" >&2
echo "New fields added:" >&2
echo "  - topic_directory: $(jq -r '.topic_directory // "null"' "$CHECKPOINT_FILE")" >&2
echo "  - topic_number: $(jq -r '.topic_number // "null"' "$CHECKPOINT_FILE")" >&2
echo "  - context_preservation: $(jq -r '.context_preservation | keys | join(", ")' "$CHECKPOINT_FILE")" >&2
echo "  - template_source: $(jq -r '.template_source // "null"' "$CHECKPOINT_FILE")" >&2
echo "  - template_variables: $(jq -r '.template_variables // "null"' "$CHECKPOINT_FILE")" >&2
echo "  - spec_maintenance: $(jq -r '.spec_maintenance | keys | join(", ")' "$CHECKPOINT_FILE")" >&2
echo "" >&2
echo "Backup saved: $BACKUP_FILE" >&2
echo "To revert: cp \"$BACKUP_FILE\" \"$CHECKPOINT_FILE\"" >&2

exit 0
