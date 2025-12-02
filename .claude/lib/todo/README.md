# TODO Library

## Purpose

Library functions for the `/todo` command that enable project discovery, plan status classification, artifact collection, and TODO.md file generation.

## Module Documentation

### todo-functions.sh

Core library providing all TODO command functionality.

**Functions**:

| Function | Purpose | Arguments |
|----------|---------|-----------|
| `scan_project_directories` | Discover all topic directories in specs/ | None |
| `find_plans_in_topic` | Find all plan files within a topic | topic_name |
| `find_related_artifacts` | Find reports and summaries for a topic | topic_name |
| `extract_plan_metadata` | Extract title, description, status from plan | plan_path |
| `categorize_plan` | Map status to TODO.md section name | status |
| `classify_status_from_metadata` | Apply classification algorithm | status_field, phases_complete, phases_total |
| `get_checkbox_for_section` | Return checkbox marker for section | section_name |
| `get_relative_path` | Convert absolute to relative path | abs_path |
| `get_topic_path` | Get topic directory path | topic_name |
| `extract_backlog_section` | Extract existing Backlog content for preservation | todo_path |
| `format_plan_entry` | Format a plan entry for TODO.md | section, title, description, path, ... |
| `generate_completed_date_header` | Generate date header for Completed section | None |
| `update_todo_file` | Update TODO.md with classified plans | todo_path, plans_json, dry_run |
| `validate_todo_structure` | Validate TODO.md file structure | todo_path |
| `plan_exists_in_todo` | Check if plan appears in TODO.md | plan_path |
| `get_plan_current_section` | Find which section contains a plan | plan_path |

**Dependencies**:
- `unified-location-detection.sh` - For specs root detection
- `error-handling.sh` - For error logging (optional)

**Version**: 1.0.0

## Usage Examples

### Scanning Projects

```bash
source .claude/lib/todo/todo-functions.sh

# Scan all topic directories
TOPICS=$(scan_project_directories)
while IFS= read -r topic; do
  echo "Processing topic: $topic"

  # Find plans in this topic
  PLANS=$(find_plans_in_topic "$topic")
  while IFS= read -r plan; do
    echo "  Plan: $plan"
  done <<< "$PLANS"
done <<< "$TOPICS"
```

### Extracting Plan Status

```bash
source .claude/lib/todo/todo-functions.sh

PLAN_PATH="/home/user/.claude/specs/959_todo/plans/001-plan.md"

# Extract metadata
METADATA=$(extract_plan_metadata "$PLAN_PATH")
TITLE=$(echo "$METADATA" | jq -r '.title')
STATUS=$(echo "$METADATA" | jq -r '.status')
PHASES_COMPLETE=$(echo "$METADATA" | jq -r '.phases_complete')
PHASES_TOTAL=$(echo "$METADATA" | jq -r '.phases_total')

# Classify status
NORMALIZED=$(classify_status_from_metadata "$STATUS" "$PHASES_COMPLETE" "$PHASES_TOTAL")

# Get section name
SECTION=$(categorize_plan "$NORMALIZED")

echo "Plan: $TITLE"
echo "Status: $NORMALIZED -> Section: $SECTION"
```

### Finding Related Artifacts

```bash
source .claude/lib/todo/todo-functions.sh

ARTIFACTS=$(find_related_artifacts "959_todo_command")
REPORTS=$(echo "$ARTIFACTS" | jq -r '.reports[]')
SUMMARIES=$(echo "$ARTIFACTS" | jq -r '.summaries[]')

echo "Reports:"
echo "$REPORTS"

echo "Summaries:"
echo "$SUMMARIES"
```

### Checkbox Formatting

```bash
source .claude/lib/todo/todo-functions.sh

# Get checkbox for each section type
echo "Not Started: $(get_checkbox_for_section "Not Started")"    # [ ]
echo "In Progress: $(get_checkbox_for_section "In Progress")"    # [x]
echo "Completed: $(get_checkbox_for_section "Completed")"        # [x]
echo "Superseded: $(get_checkbox_for_section "Superseded")"      # [~]
echo "Abandoned: $(get_checkbox_for_section "Abandoned")"        # [x]
```

### Query Functions

```bash
source .claude/lib/todo/todo-functions.sh

# Check if plan exists in TODO.md
if plan_exists_in_todo "$PLAN_PATH"; then
  echo "Plan is tracked in TODO.md"
fi

# Get current section for a plan
SECTION=$(get_plan_current_section "$PLAN_PATH")
if [ -n "$SECTION" ]; then
  echo "Plan is in section: $SECTION"
fi
```

### Manual TODO.md Update Workflow

Commands do not automatically update TODO.md. Instead, users are prompted to manually run `/todo` after command completion. This manual workflow is required due to architectural constraints in Claude Code where bash blocks cannot invoke slash commands.

**When to Run /todo**:
- After creating a new plan (`/plan`, `/repair`, `/debug`)
- After modifying a plan (`/revise`)
- After completing implementation (`/build`, `/implement`)
- After generating research reports (`/research`)
- After running tests (`/test`)
- After analyzing errors (`/errors`)

**User Experience**:
All commands display a completion reminder:
```
📋 Next Step: Run /todo to update TODO.md with this [artifact]
```

**Why No Automatic Updates**:
Slash commands are markdown files processed by Claude Code's runtime, not executable bash scripts. Bash blocks in commands cannot invoke other slash commands using `bash -c '/todo'` - this architectural constraint makes automatic updates impossible without runtime changes to Claude Code itself.

**Troubleshooting Stale TODO.md**:
If TODO.md doesn't reflect recent changes:
1. Run `/todo` to regenerate from current project state
2. Check command completion output for reminder message
3. Verify plan files have correct metadata status fields

## Test Isolation

Tests using this library MUST set environment variables to prevent production directory pollution:

```bash
export CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"
export CLAUDE_PROJECT_DIR="/tmp/test_project_$$"
mkdir -p "$CLAUDE_SPECS_ROOT"

# Cleanup trap
trap 'rm -rf /tmp/test_specs_$$ /tmp/test_project_$$' EXIT
```

## Navigation

- [← Parent](../README.md)
- [Related: unified-location-detection.sh](../core/unified-location-detection.sh)
- [Related: /todo command](../../commands/todo.md)
- [Standards: TODO Organization](../../docs/reference/standards/todo-organization-standards.md)
