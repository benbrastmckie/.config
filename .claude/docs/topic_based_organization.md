# Topic-Based Spec Organization Guide

## Overview

The topic-based spec organization system groups all artifacts for a feature or area into a single numbered topic directory. This guide explains how to work with topic-based directories.

## Directory Structure

```
specs/
└── {NNN_topic}/
    ├── plans/          # Implementation plans (gitignored)
    ├── reports/        # Research reports (gitignored)
    ├── summaries/      # Implementation summaries (gitignored)
    ├── debug/          # Debug reports (COMMITTED to git)
    ├── scripts/        # Investigation scripts (gitignored, temporary)
    ├── outputs/        # Test outputs (gitignored, temporary)
    ├── artifacts/      # Operation artifacts (gitignored)
    └── backups/        # Backups (gitignored)
```

## Key Concepts

### Topic Directories

- **Format**: `NNN_topic_name/` (e.g., `042_authentication/`, `001_cleanup/`)
- **Numbering**: Three-digit sequential numbers (001, 002, 003...)
- **Naming**: Snake_case describing the feature or area
- **Scope**: Contains all artifacts for a single feature or related area

### Artifact Types

| Directory | Purpose | Gitignored | Cleanup |
|-----------|---------|------------|---------|
| `plans/` | Implementation plans | Yes | Never |
| `reports/` | Research reports | Yes | Never |
| `summaries/` | Implementation summaries | Yes | Never |
| `debug/` | Debug reports | **NO** (committed) | Never |
| `scripts/` | Investigation scripts | Yes | Automatic |
| `outputs/` | Test outputs | Yes | Automatic |
| `artifacts/` | Operation artifacts | Yes | Optional |
| `backups/` | Backups | Yes | Optional |

### Artifact Numbering

Within each artifact type subdirectory:
- Files use three-digit numbering: `001_name.md`, `002_name.md`
- Numbering resets per topic and artifact type
- Automatic numbering handled by `get_next_artifact_number()`

**Example**:
```
specs/042_authentication/
├── plans/
│   ├── 001_user_auth.md
│   └── 002_session.md
└── reports/
    ├── 001_auth_patterns.md
    └── 002_security_practices.md
```

## Working with Topics

### Creating a New Topic

Use the utility functions:

```bash
# Source utilities
source .claude/lib/template-integration.sh

# Extract topic from feature description
topic_name=$(extract_topic_from_question "Add OAuth2 authentication")
# Returns: "oauth2_authentication"

# Check if similar topic exists
existing=$(find_matching_topic "$topic_name")

# Create or get topic directory
topic_dir=$(get_or_create_topic_dir "$topic_name" "specs")
# Creates: specs/043_oauth2_authentication/ (with all subdirectories)
```

### Creating Artifacts

```bash
# Source utilities
source .claude/lib/artifact-operations.sh

# Create a plan
create_topic_artifact "$topic_dir" "plans" "implementation" "# Plan content..."
# Creates: specs/043_oauth2_authentication/plans/001_implementation.md

# Create a report
create_topic_artifact "$topic_dir" "reports" "security_analysis" "# Report content..."
# Creates: specs/043_oauth2_authentication/reports/001_security_analysis.md
```

### Finding Existing Topics

```bash
# Find topic by keyword
topic=$(find_matching_topic "auth")
# Returns: specs/042_authentication (if exists)

# List all topics
find specs -maxdepth 1 -type d -name "[0-9][0-9][0-9]_*"
```

## Gitignore Rules

### What's Committed (NOT Gitignored)

- `debug/` subdirectories and their contents
- Debug reports track issues and are part of project history

### What's Gitignored

- `plans/`, `reports/`, `summaries/` - local working artifacts
- `scripts/`, `outputs/` - temporary workflow files
- `artifacts/`, `backups/` - operational metadata

### Validation

Check gitignore compliance:

```bash
source .claude/lib/artifact-operations.sh

compliance=$(validate_gitignore_compliance "$topic_dir")
echo "$compliance" | jq '.'

# Output:
# {
#   "debug_committed": true,
#   "other_ignored": true,
#   "violations": []
# }
```

## Cross-Referencing

### Plan → Report Links

Plans reference research reports in metadata:

```markdown
## Metadata
- **Research Reports**:
  - [Security Analysis](../reports/001_security_analysis.md)
  - [Best Practices](../reports/002_best_practices.md)
```

### Plan → Debug Report Links

Plans reference debug reports:

```markdown
## Debug Reports
- [Token Refresh Issue](../debug/001_token_refresh.md) - Phase 3
```

### Report → Plan Links

Reports reference plans they inform:

```markdown
## Related Plans
- [User Authentication](../plans/001_user_auth.md)
```

## Best Practices

### Topic Naming

✓ **Good**:
- `042_authentication` - clear, specific
- `001_cleanup` - describes area
- `015_user_profile` - focused feature

✗ **Avoid**:
- `042_misc` - too vague
- `001_stuff` - unclear
- `099_temp` - temporary names

### Topic Scope

**One topic per feature or area**:
- Keep related artifacts together
- Don't split tightly coupled features
- Create new topics for distinct features

**When to create a new topic**:
- Implementing a new feature
- Starting unrelated research
- Debugging requires significant investigation

**When to reuse existing topic**:
- Adding to existing feature
- Research relates to existing plan
- Bug fix for existing feature

### Artifact Organization

**Plans**:
- Main implementation plan: `001_feature.md`
- Sub-plans or phases: `002_subfeature.md`

**Reports**:
- Research before planning
- Number sequentially as research progresses

**Summaries**:
- Created after implementation complete
- One summary per plan typically

**Debug**:
- Created when issues arise
- Reference plan and phase

## Utilities Reference

### Topic Management

```bash
# Extract topic from description
extract_topic_from_question "<description>"

# Find existing topic by keyword
find_matching_topic "<keyword>"

# Get next topic number
get_next_topic_number "<specs_dir>"

# Create or get topic directory
get_or_create_topic_dir "<topic_name>" "<specs_dir>"
```

### Artifact Management

```bash
# Get next artifact number in subdirectory
get_next_artifact_number "<topic_dir>/<type>"

# Create artifact with auto-numbering
create_topic_artifact "<topic_dir>" "<type>" "<name>" "<content>"

# Cleanup temporary artifacts
cleanup_topic_artifacts "<topic_dir>" "<type>" [age_days]
cleanup_all_temp_artifacts "<topic_dir>"
```

### Validation

```bash
# Validate gitignore compliance
validate_gitignore_compliance "<topic_dir>"

# Update cross-references
update_cross_references "<topic_dir>"

# Link artifact to plan
link_artifact_to_plan "<plan_path>" "<artifact_path>" "<artifact_type>"
```

## Troubleshooting

### Topic Not Found

**Problem**: `find_matching_topic` returns empty

**Solutions**:
1. Check topic name matches existing directory
2. Use broader keyword (e.g., "auth" instead of "authentication")
3. Create new topic if none exists

### Duplicate Topics

**Problem**: Multiple topics for same feature

**Solutions**:
1. Use `find_matching_topic` before creating new topics
2. Consolidate into single topic if appropriate
3. Ensure topic names are distinctive

### Gitignore Issues

**Problem**: Debug reports being gitignored

**Solutions**:
1. Verify `.gitignore` has correct rules
2. Run `validate_gitignore_compliance` to check
3. Use `git check-ignore <file>` to diagnose

### Numbering Gaps

**Problem**: Missing numbers in artifact sequence (001, 003, 005...)

**Solutions**:
1. Gaps are acceptable (deleted/renamed artifacts)
2. `get_next_artifact_number` handles gaps correctly
3. No need to renumber existing artifacts

## Migration from Flat Structure

If you have existing flat structure (specs/plans/, specs/reports/), migration is optional:

**Option 1: Continue with New Structure**
- Existing flat files remain for reference
- New artifacts use topic-based structure
- No migration needed

**Option 2: Manual Migration**
- Create topic directories for existing plans
- Move related artifacts to topic subdirectories
- Update cross-references

**Option 3: Automated Migration**
- Use `.claude/scripts/migrate_to_topic_structure.sh`
- Run in dry-run mode first: `DRY_RUN=true ./migrate_to_topic_structure.sh`
- Validate with `.claude/scripts/validate_migration.sh`

## See Also

- [CLAUDE.md](../../CLAUDE.md) - Full project configuration
- [Spec Updater Agent](.claude/agents/spec-updater.md) - Automated artifact management
- [Artifact Operations](.claude/lib/artifact-operations.sh) - Utility functions
- [Template Integration](.claude/lib/template-integration.sh) - Topic utilities
