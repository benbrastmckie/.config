# Directory Protocols - Examples

Shell utilities, usage patterns, troubleshooting, and best practices.

## Navigation

This document is part of a multi-part guide:
- [Overview](directory-protocols-overview.md) - Introduction, directory structure, and topic organization
- [Structure](directory-protocols-structure.md) - Artifact taxonomy, gitignore compliance, and lifecycle
- **Examples** (this file) - Shell utilities, usage patterns, troubleshooting, and best practices

---

## Shell Utilities

### metadata-extraction.sh Functions

**Source Utilities**:
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/workflow/metadata-extraction.sh"
```

#### create_topic_artifact()

Create artifact in topic subdirectory with automatic numbering.

```bash
create_topic_artifact <topic-dir> <type> <name> <content>
```

**Parameters**:
- `topic-dir`: Path to topic directory (e.g., `specs/009_topic`)
- `type`: Artifact type (`debug`, `scripts`, `outputs`, `artifacts`, `backups`)
- `name`: Artifact name (without number, e.g., `test_failure`)
- `content`: File content

**Example**:
```bash
create_topic_artifact \
  "specs/009_orchestration" \
  "debug" \
  "test_hang_issue" \
  "$(cat <<'EOF'
# Debug Report: Test Hang Issue

## Issue Description
Tests hang during complexity evaluation...
EOF
)"

# Creates: specs/009_orchestration/debug/001_test_hang_issue.md
```

#### cleanup_topic_artifacts()

Clean specific artifact type from topic.

```bash
cleanup_topic_artifacts <topic-dir> <type> [age-days]
```

#### cleanup_all_temp_artifacts()

Clean all temporary artifacts from topic.

```bash
cleanup_all_temp_artifacts <topic-dir>
```

**Removes**:
- `scripts/` (all)
- `outputs/` (all)

**Preserves**:
- `debug/` (project history)
- `artifacts/` (optional cleanup)
- `backups/` (optional cleanup)
- `reports/`, `plans/`, `summaries/` (core artifacts)

#### extract_report_metadata()

Extract metadata from research reports for metadata-only passing.

```bash
extract_report_metadata <report-path>
```

**Returns** (JSON):
```json
{
  "path": "specs/042_auth/reports/001_jwt_patterns.md",
  "summary": "50-word summary of report...",
  "key_findings": ["finding1", "finding2", "finding3"],
  "file_paths": ["file1.js", "file2.js"],
  "recommendations": ["rec1", "rec2"]
}
```

#### extract_plan_metadata()

Extract metadata from implementation plans.

```bash
extract_plan_metadata <plan-path>
```

**Returns** (JSON):
```json
{
  "path": "specs/042_auth/042_auth.md",
  "complexity_score": 8.5,
  "phases": [{"name": "Phase 1", "tasks": 5}, ...],
  "time_estimate": "3-5 hours",
  "dependencies": []
}
```

#### load_metadata_on_demand()

Generic metadata loader with caching.

```bash
load_metadata_on_demand <artifact-path>
```

**Features**:
- Caches metadata to avoid repeated extractions
- Auto-detects artifact type (report vs plan)
- Returns cached metadata if available

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

---

## Usage Patterns

### Pattern 1: Orchestration Workflow

**Research Phase**:
```bash
# Research agents create reports
# Location: specs/{topic}/reports/NNN_report.md
# Gitignore: YES
```

**Planning Phase**:
```bash
# Plan architect creates plan
# Location: specs/{topic}/{topic}.md
# Gitignore: YES
```

**Debugging Phase**:
```bash
# Debug specialist creates debug report
create_topic_artifact \
  "$TOPIC_DIR" \
  "debug" \
  "test_failure_phase2" \
  "$DEBUG_REPORT_CONTENT"

# Location: specs/{topic}/debug/001_test_failure_phase2.md
# Gitignore: NO (committed)
```

**Cleanup Phase**:
```bash
# After workflow complete, clean temporary artifacts
cleanup_all_temp_artifacts "$TOPIC_DIR"

# Removes:
# - scripts/* (temporary investigation scripts)
# - outputs/* (temporary test outputs)
```

### Pattern 2: Manual Investigation

**Create Investigation Script**:
```bash
# Create temp script for testing
cat > specs/009_topic/scripts/investigate.sh <<'EOF'
#!/bin/bash
# Test complexity scoring on sample phases
.claude/lib/plan/complexity-utils.sh calculate_phase_complexity ...
EOF

chmod +x specs/009_topic/scripts/investigate.sh
```

**Run Investigation**:
```bash
# Execute script, capture output
specs/009_topic/scripts/investigate.sh > specs/009_topic/outputs/results.txt

# Review results
cat specs/009_topic/outputs/results.txt
```

**Document Findings**:
```bash
# Create debug report with findings
create_topic_artifact \
  "specs/009_topic" \
  "debug" \
  "complexity_scoring_issue" \
  "... findings from investigation ..."
```

**Cleanup**:
```bash
# After issue resolved, clean temp artifacts
cleanup_all_temp_artifacts "specs/009_topic"
```

### Pattern 3: Metadata-Only Artifact References

**Anti-Pattern: Full Content Passing**

Bad Example (massive context usage):
```bash
# Passes 5000 tokens per report (15,000 total)
for report in specs/042_auth/reports/*.md; do
  CONTENT=$(cat "$report")
  REPORTS_FULL+=("$CONTENT")
done

# Pass to planning agent (massive context usage)
Task {
  prompt: "...
          Research Reports:
          ${REPORTS_FULL[@]}
          ..."
}
```
**Context Usage**: 15,000 tokens (3 reports x 5000 tokens each)

**Good Example: Metadata-Only Passing**

```bash
# Passes 250 tokens per report (750 total)
for report in specs/042_auth/reports/*.md; do
  METADATA=$(extract_report_metadata "$report")
  REPORT_METADATA+=("$METADATA")
done

# Pass metadata only
Task {
  prompt: "...
          Research Reports (metadata):
          ${REPORT_METADATA[@]}

          Use Read tool to access full content selectively if needed.
          ..."
}
```
**Context Usage**: 750 tokens (95% reduction)

---

## Troubleshooting

### Issue: Debug Files Not Tracked by Git

**Symptom**: `git status` shows nothing for `specs/*/debug/*.md` files

**Cause**: Gitignore pattern too broad or missing exception

**Solution**:
```bash
# Verify gitignore rules
grep -n "specs" .gitignore

# Should see:
# specs/
# !specs/**/debug/
# !specs/**/debug/**

# If missing, add exception:
echo "!specs/**/debug/" >> .gitignore
echo "!specs/**/debug/**" >> .gitignore

# Test
touch specs/test/debug/test.md
git status specs/test/debug/test.md
# Should show as untracked
```

### Issue: Artifact Numbers Collide

**Symptom**: `create_topic_artifact()` overwrites existing file

**Cause**: Race condition in number calculation or manual file creation

**Solution**:
```bash
# Check existing numbers
ls -1 specs/009_topic/debug/

# Manually specify number if needed
# (create_topic_artifact should auto-increment, but if broken:)
touch specs/009_topic/debug/003_manual.md

# Verify next artifact gets correct number
create_topic_artifact "specs/009_topic" "debug" "test" "content"
# Should create 004_test.md
```

### Issue: Cleanup Removes Wrong Files

**Symptom**: `cleanup_all_temp_artifacts()` removes debug reports

**Cause**: Bug in cleanup function or incorrect type specification

**Solution**:
```bash
# Verify function behavior
type cleanup_all_temp_artifacts

# Should only remove scripts/ and outputs/
# If removing debug/, this is a BUG

# Restore from backup
tar -xzf .backup_specs_*.tar.gz

# Report bug and use selective cleanup:
cleanup_topic_artifacts "specs/009_topic" "scripts"
cleanup_topic_artifacts "specs/009_topic" "outputs"
```

### Issue: Topic Not Found

**Problem**: `find_matching_topic` returns empty

**Solutions**:
1. Check topic name matches existing directory
2. Use broader keyword (e.g., "auth" instead of "authentication")
3. Create new topic if none exists

### Issue: Topic Directory Not Created

**Symptom**: Artifacts fail to create, "directory not found"

**Cause**: Topic directory or subdirectory missing

**Solution**:
```bash
# Ensure topic directory exists
mkdir -p specs/009_topic

# Ensure subdirectories exist
mkdir -p specs/009_topic/{reports,plans,summaries,debug,scripts,outputs,artifacts,backups}

# Then retry artifact creation
create_topic_artifact "specs/009_topic" "debug" "test" "content"
```

---

## Best Practices

### Topic Naming

**Good**:
- `042_authentication` - clear, specific
- `001_cleanup` - describes area
- `015_user_profile` - focused feature

**Avoid**:
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

---

## Related Documentation

- [Overview](directory-protocols-overview.md) - Introduction, directory structure, and topic organization
- [Structure](directory-protocols-structure.md) - Artifact taxonomy, gitignore compliance, and lifecycle
- **CLAUDE.md**: Directory protocols section (specs structure summary)
- **spec_updater_guide.md**: Spec updater agent usage and patterns
- **command_architecture_standards.md**: Context preservation standards (Standards 6-8)
- **phase_dependencies.md**: Wave-based execution and dependency syntax
- **.claude/lib/workflow/metadata-extraction.sh**: Shell utility implementations

**Cross-Reference**: See [Command Architecture Standards](../reference/architecture/overview.md) for context preservation patterns when working with topic artifacts.
