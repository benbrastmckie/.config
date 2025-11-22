# Spec Updater Guide

## Overview

The spec updater agent manages specification artifacts within the topic-based directory structure, ensuring proper placement, cross-references, and lifecycle management for all workflow artifacts.

## Agent Location

`.claude/agents/spec-updater.md`

## Core Responsibilities

### 1. Artifact Management
- Create artifacts in appropriate topic subdirectories
- Determine artifact numbers (incremental within topic)
- Add required metadata to all artifacts
- Register artifacts in artifact registry

### 2. Cross-Reference Maintenance
- Update markdown links when moving artifacts
- Maintain bidirectional references (plan ↔ report, debug ↔ plan)
- Verify link integrity after updates
- Use relative paths (not absolute)

### 3. Topic Organization
- Manage topic-based directory structure (`specs/{NNN_topic}/`)
- Create topic directories with standard subdirectories
- Organize artifacts by category
- Handle nested plan structures (Level 0/1/2)

### 4. Lifecycle Management
- Respect gitignore policies for each artifact type
- Clean up temporary artifacts (scripts/, outputs/)
- Preserve committed artifacts (debug/)
- Enforce artifact retention policies

## Topic-Based Structure

Each topic directory follows this structure:

```
specs/{NNN_topic}/
├── {NNN_topic}.md              # Main plan
├── reports/                     # Research reports (gitignored)
│   └── NNN_*.md
├── plans/                       # Sub-plans (gitignored)
│   └── NNN_*.md
├── summaries/                   # Implementation summaries (gitignored)
│   └── NNN_*.md
├── debug/                       # Debug reports (COMMITTED)
│   └── NNN_*.md
├── scripts/                     # Investigation scripts (gitignored)
│   └── *.sh
├── outputs/                     # Test outputs (gitignored)
│   └── *.log
├── artifacts/                   # Operation artifacts (gitignored)
│   └── *.md
└── backups/                     # Backups (gitignored)
    └── *.tar.gz
```

## Artifact Categories

### Category 1: Core Planning Artifacts
- **Types**: Main plan, sub-plans, research reports, summaries
- **Lifecycle**: Created during planning/research, preserved
- **Gitignore**: YES
- **Numbering**: Three-digit incremental within topic (001, 002, 003...)

### Category 2: Debugging and Investigation
- **Types**: Debug reports, investigation scripts
- **Lifecycle**: Created during debugging, preserved (debug) or cleaned (scripts)
- **Gitignore**: NO (debug only), YES (scripts)
- **Special**: Debug reports are COMMITTED for issue tracking

### Category 3: Test and Validation Outputs
- **Types**: Test output logs, test data
- **Lifecycle**: Created during testing, cleaned after workflow
- **Gitignore**: YES
- **Cleanup**: Automatic after workflow completion

### Category 4: Operational Artifacts
- **Types**: Expansion/collapse artifacts, backup files
- **Lifecycle**: Created during operations, optional cleanup
- **Gitignore**: YES
- **Retention**: 30 days (configurable)

### Category 5: Documentation and Communication
- **Types**: Workflow logs, notes
- **Lifecycle**: Created as needed, preserved for reference
- **Gitignore**: YES
- **Purpose**: Debugging, team communication

## Usage Patterns

### Creating Debug Reports (from /orchestrate)

Debug reports are created during orchestration debugging phase:

```markdown
# Invocation from orchestrate.md
Task {
  subagent_type: "general-purpose"
  description: "Create debug report using spec-updater protocol"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/spec-updater.md

    You are acting as a Spec Updater Agent.

    Create debug report for Phase 2 test failure.

    Topic: specs/009_orchestration_enhancement
    Phase: Phase 2
    Iteration: 1

    Issue: Bundle compatibility test failing
    Root Cause: Function signature mismatch
    Fix Proposals:
    1. Update function call sites (confidence: HIGH)
    2. Add compatibility wrapper (confidence: MEDIUM)

    Create debug report:
    - In specs/009_orchestration_enhancement/debug/
    - Number: Find highest, use next (001, 002, etc.)
    - Include all required metadata
    - Link back to main plan
    - Format according to debug report template

    After creating report:
    - Verify it's in debug/ subdirectory
    - Check git status (should show as untracked, will be committed)
}
```

**Debug Report Template**:
```markdown
# Debug Report: [Issue Description]

## Metadata
- **Date**: YYYY-MM-DD
- **Phase**: Phase N
- **Iteration**: 1|2|3
- **Plan**: ../../009_topic.md

## Issue Description
[What went wrong]

## Root Cause Analysis
[Why it happened]

## Fix Proposals
[Specific fixes with confidence levels]

## Resolution
[What was done, if resolved]
```

### Creating Investigation Scripts

Investigation scripts are temporary artifacts for debugging:

```bash
# From spec-updater agent or commands
SCRIPT_FILE="specs/009_topic/scripts/test_bundle_compatibility.sh"

# Create script
cat > "$SCRIPT_FILE" <<'EOF'
#!/usr/bin/env bash
# Test script for bundle compatibility debugging
source .claude/lib/plan/plan-core-bundle.sh
# ... test logic ...
EOF

# Make executable
chmod +x "$SCRIPT_FILE"
```

**Cleanup after workflow**:
```bash
# Manual cleanup
cleanup_topic_artifacts "specs/009_topic" "scripts" 0

# Or automatic (integrated into /orchestrate)
cleanup_all_temp_artifacts "specs/009_topic"
```

### Creating Implementation Summaries

Summaries are created after completing workflow phases:

```markdown
# Invocation from /document command
Task {
  subagent_type: "general-purpose"
  description: "Create implementation summary using spec-updater protocol"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/spec-updater.md

    You are acting as a Spec Updater Agent.

    Create implementation summary for completed feature.

    Topic: specs/009_orchestration_enhancement
    Main Plan: specs/009_orchestration_enhancement/009_orchestration_enhancement.md
    Research Reports:
    - specs/009_orchestration_enhancement/reports/001_library_analysis.md
    - specs/009_orchestration_enhancement/reports/002_orchestrate_audit.md

    Create summary:
    1. Determine next number in summaries/ (find highest, add 1)
    2. Create summary file: specs/009_orchestration_enhancement/summaries/001_phase_0_summary.md
    3. Include metadata:
       - Date
       - Topic
       - Link to main plan
       - List of research reports used
    4. Document:
       - What was implemented
       - Key decisions made
       - Challenges encountered
       - Test results

    After creating summary:
    - Update main plan's "Implementation Status"
    - Verify cross-references work
}
```

## Gitignore Compliance

### Testing Gitignore Rules

```bash
# Test debug file (should be tracked)
touch specs/009_topic/debug/test.md
git status specs/009_topic/debug/test.md  # Should show as untracked
rm specs/009_topic/debug/test.md

# Test scripts file (should be gitignored)
touch specs/009_topic/scripts/test.sh
git status specs/009_topic/scripts/test.sh  # Should show nothing (gitignored)
rm specs/009_topic/scripts/test.sh
```

### Gitignore Patterns

From `.gitignore`:
```gitignore
# Topic-scoped artifacts (gitignored)
specs/*/reports/
specs/*/plans/
specs/*/summaries/
specs/*/scripts/
specs/*/outputs/
specs/*/artifacts/
specs/*/backups/
specs/*/data/
specs/*/logs/
specs/*/notes/

# Debug reports are COMMITTED (exception)
!specs/*/debug/
```

## Shell Function Integration

The spec updater agent works alongside shell utilities for artifact management:

### create_topic_artifact

Create artifacts programmatically:

```bash
# Source utilities
source .claude/lib/workflow/metadata-extraction.sh

# Create debug report
DEBUG_CONTENT="$(cat <<EOF
# Debug Report: Test Failure

## Metadata
- **Date**: $(date -u +%Y-%m-%d)
- **Phase**: Phase 2
- **Plan**: ../../009_topic.md

## Issue
Test failure in bundle compatibility

## Root Cause
Function signature mismatch
EOF
)"

ARTIFACT_PATH=$(create_topic_artifact \
  "specs/009_topic" \
  "debug" \
  "bundle_compatibility" \
  "$DEBUG_CONTENT")

echo "Created: $ARTIFACT_PATH"
```

### cleanup_topic_artifacts

Clean up temporary artifacts:

```bash
# Clean scripts older than 7 days
cleanup_topic_artifacts "specs/009_topic" "scripts" 7

# Clean all outputs (age=0 means all)
cleanup_topic_artifacts "specs/009_topic" "outputs" 0

# Clean all temp artifacts
cleanup_all_temp_artifacts "specs/009_topic"
```

## Cross-Reference Patterns

### Plan → Report
```markdown
# In plan file (specs/009_topic/009_topic.md)
Research Reports:
- [Library Analysis](reports/001_library_analysis.md)
- [Orchestrate Audit](reports/002_orchestrate_audit.md)
```

### Report → Plan
```markdown
# In report file (specs/009_topic/reports/001_library_analysis.md)
## Metadata
- **Main Plan**: ../009_topic.md
```

### Debug Report → Plan
```markdown
# In debug report (specs/009_topic/debug/001_issue.md)
## Metadata
- **Plan**: ../../009_topic.md
- **Phase**: Phase 2
```

### Summary → Plan
```markdown
# In summary (specs/009_topic/summaries/001_summary.md)
## Metadata
- **Plan**: ../009_topic.md
- **Reports Used**:
  - [Library Analysis](../reports/001_library_analysis.md)
```

## Cross-Reference Best Practices

When creating cross-references between artifacts, use **metadata-only passing** to minimize context usage (see [Command Architecture Standards - Standard 6](../reference/architecture/overview.md#standard-6)).

### Metadata Extraction for Cross-References

Use `extract_report_metadata()` utility from `.claude/lib/workflow/metadata-extraction.sh` when creating cross-references:

```bash
# Extract metadata from research reports
for report in specs/042_auth/reports/*.md; do
  METADATA=$(extract_report_metadata "$report")
  # Returns: {path, 50-word summary, key_findings[]}
  REPORT_METADATA+=("$METADATA")
done

# Create plan with metadata references
cat > "specs/042_auth/042_auth.md" <<EOF
# Authentication Implementation Plan

## Research Reports (metadata)
$(for meta in "${REPORT_METADATA[@]}"; do
  # Extract path and summary from metadata
  PATH=$(echo "$meta" | jq -r '.path')
  SUMMARY=$(echo "$meta" | jq -r '.summary')
  echo "- [$PATH]($PATH): $SUMMARY"
done)

Use Read tool to access full report content selectively if needed.
EOF
```

**Context Reduction**: 95% (250 tokens vs 5000 tokens per report)

### Agent Invocation Pattern

When invoking spec-updater agent, use **behavioral injection pattern** (see [Command Architecture Standards](../reference/architecture/overview.md#agent-invocation-patterns)):

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create summary using spec-updater protocol"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/spec-updater.md

    You are acting as a Spec Updater Agent.

    [Task-specific instructions here]
}
```

## Bidirectional Cross-Referencing

The spec updater agent maintains **automatic bidirectional cross-references** between all artifacts in the topic directory:

### Cross-Referencing Workflow

**Standard Workflow**:
1. **Create artifact** → Spec updater determines artifact path and number
2. **Extract metadata** → Use `extract_report_metadata()` or `extract_plan_metadata()`
3. **Update parent references** → Add metadata-only reference from parent plan to new artifact
4. **Update child references** → Add parent plan link to new artifact's metadata
5. **Verify links** → Test relative paths resolve correctly

**Example Flow**:
```bash
# Step 1: Create research report
REPORT_PATH="specs/042_auth/reports/001_jwt_patterns.md"
create_topic_artifact "specs/042_auth" "reports" "jwt_patterns" "$CONTENT"

# Step 2: Extract metadata
REPORT_METADATA=$(extract_report_metadata "$REPORT_PATH")

# Step 3: Update parent plan (add reference to report)
update_parent_references "specs/042_auth/042_auth.md" "$REPORT_METADATA"

# Step 4: Add parent link to report
add_parent_link "$REPORT_PATH" "../042_auth.md"

# Step 5: Verify bidirectional links
verify_cross_references "specs/042_auth"
```

### Bidirectional Reference Utilities

**`create_bidirectional_link(parent_artifact, child_artifact)`**:
```bash
# Automatically creates forward and backward references
create_bidirectional_link \
  "specs/042_auth/042_auth.md" \
  "specs/042_auth/reports/001_jwt_patterns.md"

# Creates:
# 1. Forward: Parent → Child (metadata-only reference)
# 2. Backward: Child → Parent (full link)
```

**`update_parent_references(parent_path, child_metadata)`**:
```bash
# Add metadata-only reference to parent
CHILD_METADATA=$(extract_report_metadata "specs/042_auth/reports/001_jwt_patterns.md")
update_parent_references "specs/042_auth/042_auth.md" "$CHILD_METADATA"

# Appends to "Research Reports" section:
# - [JWT Patterns](reports/001_jwt_patterns.md): 50-word summary of JWT authentication patterns...
```

**`validate_cross_references(topic_directory)`**:
```bash
# Validate all cross-references within topic
validate_cross_references "specs/042_auth"

# Checks:
# - All relative paths resolve
# - Parent plans reference all child artifacts
# - Child artifacts reference parent plans
# - No broken links
```

### Cross-Reference Types

| Reference Type | Direction | Format | Context Usage |
|----------------|-----------|--------|---------------|
| **Plan → Report** | Forward | Metadata + link | 250 tokens (95% reduction) |
| **Report → Plan** | Backward | Full link | 50 tokens |
| **Plan → Debug** | Forward | Full link + metadata | 150 tokens |
| **Debug → Plan** | Backward | Full link | 50 tokens |
| **Plan → Summary** | Forward | Metadata + link | 250 tokens |
| **Summary → Plan** | Backward | Full link + report refs | 300 tokens |

### Automated Cross-Reference Maintenance

The spec updater agent automatically maintains cross-references during:
- **Artifact creation**: Creates bidirectional links on first artifact creation
- **Artifact moves**: Updates all references when artifacts are reorganized
- **Plan expansion**: Preserves cross-references when expanding phases/stages
- **Plan collapse**: Updates cross-references when collapsing phases/stages

## Quality Checklist

Before finalizing spec updater operations:

- [ ] Artifact created in correct subdirectory
- [ ] Metadata complete and accurate
- [ ] Cross-references updated in related files
- [ ] Gitignore compliance verified
- [ ] File permissions correct (scripts executable)
- [ ] Directory structure follows taxonomy
- [ ] Numbering consistent within topic
- [ ] Links use relative paths
- [ ] Debug reports in debug/ (if applicable)
- [ ] Scripts in scripts/ (if applicable)

## Integration with Commands

### /plan
- Creates plan in topic directory: `specs/{NNN_topic}/{NNN_topic}.md`
- Includes spec updater checklist in plan metadata
- Creates standard subdirectories automatically

### /expand
- Preserves spec updater checklist when expanding phases
- Maintains topic directory structure
- Updates cross-references in expanded files

### /implement
- Uses spec updater for phase completion tracking
- Creates debug reports via spec updater during failures
- Generates summaries via spec updater after completion

### /orchestrate
- Invokes spec updater for all artifact management
- Creates topic directory at workflow start
- Uses spec updater for debug report creation
- Generates summary via spec updater at workflow end

## Best Practices

### Artifact Creation
1. Create only the topic root directory (`specs/NNN_topic/`). Subdirectories (plans/, reports/, debug/, summaries/) are created lazily by agents when files are written. See [Directory Creation Anti-Patterns](../reference/standards/code-standards.md#directory-creation-anti-patterns) for details.
2. Use consistent numbering within each subdirectory (001, 002, 003...)
3. Include complete metadata in all artifacts
4. Verify gitignore compliance for each category

### Cross-Reference Management
1. Use relative paths (not absolute)
2. Verify links after every move
3. Maintain bidirectional references (plan ↔ report)
4. Update metadata sections when paths change

### Debug Report Handling
1. Create immediately when issues occur
2. Include all required metadata
3. Link to specific phase and iteration
4. Commit to git (exception to gitignore)

### Cleanup Policies
1. Remove scripts/ after workflow completion
2. Remove outputs/ after verification
3. Preserve debug/ (committed for issue tracking)
4. Optional cleanup of backups/ after 30 days

## Troubleshooting

### Issue: Artifact not in correct subdirectory
**Solution**: Check topic directory structure
```bash
ls specs/009_topic/  # Should show all subdirectories
```

### Issue: Gitignore not working
**Solution**: Verify gitignore patterns
```bash
git check-ignore specs/009_topic/scripts/test.sh  # Should be ignored
git check-ignore specs/009_topic/debug/test.md    # Should NOT be ignored
```

### Issue: Broken cross-references
**Solution**: Update references to use relative paths
```bash
# Search for absolute references
grep -r "specs/009_topic" specs/

# Should use relative paths instead:
# ../009_topic.md (from subdirectory)
# reports/001_report.md (from same level)
```

## References

- **Artifact Taxonomy**: `specs/009_orchestration_enhancement_adapted/design/artifact_taxonomy.md`
- **CLAUDE.md**: Project-level standards for artifact organization
- **metadata-extraction.sh**: Shell utilities for artifact management
