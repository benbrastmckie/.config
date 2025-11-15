# Directory Removal Safety Criteria

## Research Metadata

**Research Topic**: Directory Removal Safety Criteria
**Focus Areas**: Dependency analysis, git history preservation, cross-reference impact, workflow integration
**Date**: 2025-11-14
**Complexity**: Medium (2/5)

## Executive Summary

The `.claude/specs/` directory has grown to 224 topic directories (35MB total, 1,190+ markdown files) with significant bloat from:
1. **Non-standard directories**: 12 loose `.md` files, 5 non-topic directories (plans/, reports/, artifacts/, todo/, summaries/, standards/, validation/)
2. **Empty directories**: 19 completely empty topic directories
3. **Orphaned artifacts**: Topics with no reports or plans (implementation debris)
4. **Duplicate structures**: Top-level plans/reports directories alongside topic-based organization

Safe removal requires understanding dependencies, cross-references, git history preservation, and workflow integration patterns.

## Current State Analysis

### Directory Structure Statistics

```
Total Size: 35MB
Total Topic Directories: 224
  - Standard numbered (NNN_*): 209
  - Non-standard: 15
Total Markdown Files: 1,190+
Empty Directories: 19
```

### Non-Standard Items Requiring Analysis

**Loose Markdown Files** (12 files in specs root):
- `coordinate_command.md` - Execution example/debugging artifact
- `coordinate_output.md` - Execution output (787 commits reference this)
- `coordinate_research.md` - Research output
- `coordinate_revise.md` - Workflow output
- `coordinate_ultrathink.md` - Debugging artifact
- `coordinage_implement.md` - Typo/debugging artifact
- `coordinage_plan.md` - Typo/debugging artifact
- `optimize_output.md` - Execution output
- `research_output.md` - Research output
- `setup_choice.md` - Interactive choice artifact
- `supervise_output.md` - Execution output
- `workflow_scope_detection_analysis.md` - Analysis artifact

**Non-Standard Directories**:
- `.claude/specs/plans/` - Top-level plans (159 files, pre-migration structure)
- `.claude/specs/reports/` - Top-level reports (65 files, pre-migration structure)
- `.claude/specs/artifacts/` - Legacy artifact storage
- `.claude/specs/summaries/` - Top-level summaries (31 files)
- `.claude/specs/standards/` - Project standards
- `.claude/specs/todo/` - Task tracking
- `.claude/specs/validation/` - Validation outputs
- `.claude/specs/setup_cleanup_agent_enhancement/` - Non-numbered topic
- `.claude/specs/coordinate_command_error/` - Non-numbered topic

### Gitignore Configuration

```gitignore
# Topic-based specs organization
specs/*/*          # Gitignore all specs subdirectories
!specs/*/debug/    # Un-ignore debug subdirectories
!specs/*/debug/**  # Un-ignore debug contents
```

**Key Finding**: Top-level `.claude/specs/plans/` and `.claude/specs/reports/` ARE gitignored (covered by `specs/*/*` pattern), but loose `.md` files in specs root are NOT gitignored.

## Dependency Analysis

### 1. Cross-Reference Dependencies

**Library Dependencies** (8 core libraries reference topic directories):
- `.claude/lib/topic-utils.sh` - Topic creation/management
- `.claude/lib/unified-location-detection.sh` - Path resolution (85% token reduction, 25x speedup)
- `.claude/lib/template-integration.sh` - Plan template integration
- `.claude/lib/overview-synthesis.sh` - Research synthesis
- `.claude/lib/context-pruning.sh` - Context management
- `.claude/lib/monitor-model-usage.sh` - Usage tracking
- `.claude/lib/workflow-initialization.sh` - Workflow setup

**Pattern**: Libraries use dynamic path discovery via `find .claude/specs -name "NNN_*"`, so removing individual topics does not break library code.

### 2. Git History Preservation

**Recent Activity** (since 2024-11-01):
- 787 commits to `.claude/specs/`
- Highest activity: `coordinate_output.md` (referenced in 20+ commits)
- Active debugging artifacts: `coordinate_*.md`, `optimize_output.md`

**Git History Safe Removal**:
- Files removed from working tree remain in git history
- Use `git rm` for tracked files (preserves history)
- Gitignored files can be deleted directly (never tracked)

### 3. Cross-Reference Impact

**Command Integration** (20+ references found):
```
.claude/specs/640_637_coordinate_outputmd_which_has_errors_and/reports/001_plan_naming_implementation.md
.claude/specs/652_coordinate_error_fixes/plans/001_coordinate_error_fixes.md
.claude/specs/675_infrastructure_and_the_claude_docs_standards/plans/001_fix_coordinate_library_sourcing.md
.claude/specs/685_684_claude_specs_coordinate_outputmd_and_the/reports/001_new_error_analysis.md
```

**Analysis**: Cross-references primarily point to:
1. **Active debugging workflows** - Recent coordinate/optimize command development
2. **Topic-specific artifacts** - Reports/plans within numbered topics
3. **Loose files as examples** - coordinate_output.md referenced as execution example

**Impact Assessment**:
- Removing loose files breaks ~20 cross-references (primarily in topic 640-685 range)
- Removing empty topics has zero cross-reference impact
- Removing top-level plans/reports requires migration to topic-based structure

### 4. Workflow Integration

**Active Workflows Depending on Specs**:
1. `/coordinate` - State-based orchestration (references topic structure)
2. `/orchestrate` - Multi-agent workflows (creates topic artifacts)
3. `/research` - Hierarchical research (creates reports subdirectories)
4. `/plan` - Implementation planning (creates plans subdirectories)
5. `/implement` - Execution (reads plans, creates summaries)

**Safe Removal Requirements**:
- Empty directories: Safe (no workflow depends on empty topics)
- Loose files: Requires migration or cross-reference updates
- Top-level artifact dirs: Requires complete migration to topic-based structure

## Safe Removal Criteria

### Tier 1: Zero-Risk Removal (Immediate Safe)

**Empty Topic Directories** (19 directories):
```bash
.claude/specs/632_test_workflow_description
.claude/specs/663_661_and_the_standards_in_claude_docs_to_avoid
.claude/specs/673_claude_specs_coordinate_outputmd_debug_errors
# ... 16 more
```

**Criteria**:
- ✓ No files in any subdirectory
- ✓ No cross-references from other files
- ✓ No git commits referencing directory content
- ✓ Zero workflow integration impact

**Safety Score**: 10/10
**Recommended Action**: Delete immediately using `rmdir` (fails if non-empty)
**Recovery**: No recovery needed (directories were never used)

**Automation**:
```bash
.claude/scripts/detect-empty-topics.sh --cleanup
```

### Tier 2: Low-Risk Removal (Safe with Verification)

**Non-Standard Directory Names** (2 directories):
```
.claude/specs/setup_cleanup_agent_enhancement/  # Should be NNN_setup_cleanup_agent_enhancement
.claude/specs/coordinate_command_error/          # Should be NNN_coordinate_command_error
```

**Criteria**:
- ✓ Contains artifacts (plans/reports)
- ✗ Violates naming convention (no NNN_ prefix)
- ? Cross-references may exist (check first)
- ? Git history may exist (preserve via migration)

**Safety Score**: 7/10
**Recommended Action**: Migrate to proper naming (renumber, preserve git history)
**Recovery**: Git history shows original location

**Migration Process**:
1. Find next available topic number
2. Rename directory with proper NNN_ prefix
3. Update cross-references in dependent files
4. Verify workflows still function
5. Commit migration with descriptive message

### Tier 3: Medium-Risk Removal (Requires Migration)

**Loose Markdown Files in Specs Root** (12 files):

**Active/Referenced Files** (preserve or migrate):
- `coordinate_output.md` - 787 commits, 20+ cross-references
- `optimize_output.md` - Active development artifact
- `setup_choice.md` - Interactive workflow artifact

**Criteria**:
- ✓ Referenced in multiple cross-references
- ✓ Git history exists (787 commits for coordinate_output.md)
- ✗ Violates directory protocols (loose files not allowed)
- ? Workflow integration (execution examples)

**Safety Score**: 4/10
**Recommended Action**: Migrate to appropriate topic directories
**Recovery**: Git history preserved, cross-references updated

**Migration Strategy**:
1. **Identify purpose**: Execution example, debugging artifact, or documentation?
2. **Choose destination**:
   - Execution examples → Create topic `NNN_command_execution_examples/`
   - Debugging artifacts → Move to relevant debug/ subdirectory
   - Documentation → Move to `.claude/docs/examples/`
3. **Update cross-references**: Search and replace all references
4. **Verify workflows**: Test commands referencing these files
5. **Commit with detailed message**: Explain migration rationale

**Inactive/Orphaned Files** (delete or archive):
- `coordinage_*.md` - Typos (should be "coordinate")
- `coordinate_ultrathink.md` - One-off debugging
- `workflow_scope_detection_analysis.md` - Analysis complete

**Criteria**:
- ✓ No cross-references (or only historical references)
- ✓ Workflow complete (analysis/debugging finished)
- ✗ May have git history (check first)

**Safety Score**: 6/10
**Recommended Action**: Delete after verification
**Recovery**: Git history shows full content

### Tier 4: High-Risk Removal (Structural Migration Required)

**Top-Level Artifact Directories**:
- `.claude/specs/plans/` - 159 files (pre-migration structure)
- `.claude/specs/reports/` - 65 files (legacy structure)
- `.claude/specs/summaries/` - 31 files (mixed usage)

**Criteria**:
- ✓ Contains substantial content (255+ files total)
- ✗ Violates current directory protocols (should be topic-scoped)
- ✓ May have cross-references (widespread usage)
- ✓ Git history exists (pre-migration commits)

**Safety Score**: 2/10
**Recommended Action**: Complete migration to topic-based structure
**Recovery**: Complex (requires reverse migration)

**Migration Requirements**:
1. **Categorize files**: Group by feature/topic area
2. **Create topic directories**: One per logical feature grouping
3. **Move files**: Preserve git history via `git mv`
4. **Update cross-references**: Extensive search/replace required
5. **Update CLAUDE.md**: Remove references to top-level structure
6. **Test all workflows**: `/plan`, `/research`, `/implement`, `/orchestrate`
7. **Phased rollout**: Migrate incrementally, validate at each step

**Estimated Effort**: 8-12 hours (255 files, extensive cross-references)

## Safe Removal Decision Matrix

| Criteria | Empty Topics | Non-Standard Names | Loose Files | Top-Level Dirs |
|----------|--------------|-------------------|-------------|----------------|
| **Safety Score** | 10/10 | 7/10 | 4-6/10 | 2/10 |
| **Cross-References** | None | Few | Moderate | Extensive |
| **Git History** | None | Minimal | Significant | Substantial |
| **Workflow Impact** | Zero | Low | Medium | High |
| **Recovery Difficulty** | N/A | Easy | Medium | Complex |
| **Recommended Action** | Delete | Migrate | Migrate/Delete | Structural Migration |
| **Automation Available** | Yes | Partial | Manual | Manual |

## Dependency Preservation Strategies

### 1. Git History Preservation

**For All Removals**:
```bash
# Check git history before removal
git log --all --oneline -- path/to/file

# For tracked files, use git rm (preserves history)
git rm path/to/file

# For gitignored files, direct delete is safe
rm path/to/file
```

**Archive Strategy** (optional, for high-value artifacts):
```bash
# Create timestamped archive before removal
tar -czf .claude/archive/specs_cleanup_$(date +%Y%m%d).tar.gz \
  .claude/specs/coordinate_output.md \
  .claude/specs/plans/ \
  .claude/specs/reports/

# Document archive location
echo "Archived to .claude/archive/specs_cleanup_YYYYMMDD.tar.gz" > .claude/specs/ARCHIVE_NOTICE.md
```

### 2. Cross-Reference Update Protocol

**Before Removal**:
```bash
# Find all cross-references
grep -r "coordinate_output.md" .claude/

# Generate cross-reference report
grep -r "coordinate_output.md" .claude/ > /tmp/cross_refs.txt

# Review and plan updates
cat /tmp/cross_refs.txt
```

**After Migration**:
```bash
# Update cross-references (example: coordinate_output.md → topic 714)
find .claude/ -type f -name "*.md" -exec sed -i \
  's|\.claude/specs/coordinate_output\.md|.claude/specs/714_command_execution_examples/reports/001_coordinate_output.md|g' {} +

# Verify no broken references remain
grep -r "coordinate_output.md" .claude/
```

### 3. Workflow Integration Verification

**Test Suite** (run after any removal):
```bash
# Test core workflows
/research "test topic"          # Verify topic creation
/plan "test feature"            # Verify plan creation
/implement <test-plan>          # Verify artifact resolution
/coordinate "test workflow"     # Verify state management

# Verify library functions
.claude/tests/test_topic_utils.sh
.claude/tests/test_unified_location_detection.sh

# Check for unbound variables or broken paths
bash -n .claude/commands/*.md  # Syntax check
bash -u .claude/lib/*.sh       # Unbound variable check
```

## Recommended Removal Sequence

### Phase 1: Zero-Risk Cleanup (Week 1)

**Actions**:
1. Remove 19 empty topic directories
2. Verify no unexpected breakage
3. Commit cleanup

**Commands**:
```bash
.claude/scripts/detect-empty-topics.sh --cleanup
git add -A
git commit -m "chore: remove 19 empty topic directories (zero-risk cleanup)"
```

**Validation**:
- ✓ All workflow commands still function
- ✓ No new errors in library functions
- ✓ Test suite passes

### Phase 2: Low-Risk Migration (Week 2)

**Actions**:
1. Renumber 2 non-standard topic directories
2. Update cross-references
3. Test workflows
4. Commit migration

**Commands**:
```bash
# Get next topic number
NEXT_NUM=$(cd .claude/specs && ls -1d [0-9][0-9][0-9]_* | sed 's/^\([0-9]*\)_.*/\1/' | sort -n | tail -1)
NEXT_NUM=$(printf "%03d" $((10#$NEXT_NUM + 1)))

# Migrate setup_cleanup_agent_enhancement
git mv .claude/specs/setup_cleanup_agent_enhancement \
       .claude/specs/${NEXT_NUM}_setup_cleanup_agent_enhancement

# Update cross-references
find .claude/ -type f -name "*.md" -exec sed -i \
  "s|specs/setup_cleanup_agent_enhancement|specs/${NEXT_NUM}_setup_cleanup_agent_enhancement|g" {} +

# Commit
git add -A
git commit -m "refactor: migrate setup_cleanup_agent_enhancement to proper naming (${NEXT_NUM}_)"
```

**Validation**:
- ✓ Cross-references updated correctly
- ✓ Workflows find migrated topics
- ✓ No broken links in documentation

### Phase 3: Medium-Risk Cleanup (Week 3-4)

**Actions**:
1. Categorize loose markdown files (active vs orphaned)
2. Migrate active files to topic directories
3. Delete orphaned files
4. Update cross-references
5. Test extensively

**Migration Plan**:

**Active Files** (migrate to topics):
```bash
# coordinate_output.md → 714_coordinate_execution_examples/
mkdir -p .claude/specs/714_coordinate_execution_examples/reports
git mv .claude/specs/coordinate_output.md \
       .claude/specs/714_coordinate_execution_examples/reports/001_coordinate_output.md

# Update 20+ cross-references
find .claude/ -type f -name "*.md" -exec sed -i \
  's|specs/coordinate_output\.md|specs/714_coordinate_execution_examples/reports/001_coordinate_output.md|g' {} +
```

**Orphaned Files** (delete after verification):
```bash
# Verify no critical cross-references
grep -r "coordinage_implement.md" .claude/  # Should return zero
grep -r "coordinate_ultrathink.md" .claude/ # Should return zero

# Delete if safe
git rm .claude/specs/coordinage_implement.md
git rm .claude/specs/coordinate_ultrathink.md
```

**Validation**:
- ✓ All cross-references point to new locations
- ✓ No 404 errors in documentation links
- ✓ Command execution examples still accessible
- ✓ Grep search finds migrated files

### Phase 4: Structural Migration (Week 5-8)

**Actions**:
1. Analyze 255 files in top-level plans/reports/summaries
2. Group files by feature/topic area
3. Create topic directories for each group
4. Migrate files preserving git history
5. Update extensive cross-references
6. Update CLAUDE.md and documentation
7. Test all workflows comprehensively

**Analysis First**:
```bash
# Categorize files by similarity
cd .claude/specs/plans
for file in *.md; do
  echo "$file: $(head -5 "$file" | grep -E "^#" | head -1)"
done | sort

# Create topic groupings
# Example: 001-020 → orchestration, 021-040 → workflow, etc.
```

**Migration Strategy**:
1. **Week 5**: Analyze and categorize (no changes)
2. **Week 6**: Migrate plans/ (159 files)
3. **Week 7**: Migrate reports/ (65 files)
4. **Week 8**: Migrate summaries/ (31 files), validate, cleanup

**Validation** (after each week):
- ✓ All workflows find migrated files
- ✓ Cross-references updated
- ✓ No regressions in test suite
- ✓ Documentation accurate
- ✓ Library functions resolve paths correctly

## Risk Mitigation Strategies

### 1. Backup Before Removal

```bash
# Create timestamped backup
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
tar -czf ~/.claude_backups/specs_pre_cleanup_${BACKUP_DATE}.tar.gz .claude/specs/

# Verify backup
tar -tzf ~/.claude_backups/specs_pre_cleanup_${BACKUP_DATE}.tar.gz | head -20
```

### 2. Incremental Removal with Verification

**Never remove multiple tiers in one commit**:
- Phase 1 complete → verify → commit → test
- Phase 2 complete → verify → commit → test
- Allows easy rollback if issues discovered

### 3. Cross-Reference Tracking

**Maintain removal log**:
```markdown
# REMOVAL_LOG.md

## 2025-11-14: Phase 1 - Empty Directories
- Removed: 19 empty topic directories
- Cross-references: None
- Validation: ✓ All tests pass
- Commit: abc123

## 2025-11-21: Phase 2 - Non-Standard Names
- Migrated: setup_cleanup_agent_enhancement → 715_setup_cleanup_agent_enhancement
- Cross-references: 3 updated
- Validation: ✓ Workflows function
- Commit: def456
```

### 4. Rollback Plan

**For each phase, document rollback**:
```bash
# Phase 1 rollback (empty directories - recreate if needed)
mkdir -p .claude/specs/632_test_workflow_description

# Phase 2 rollback (git revert)
git revert <commit-hash>

# Phase 3 rollback (restore from backup)
tar -xzf ~/.claude_backups/specs_pre_cleanup_YYYYMMDD.tar.gz
```

## Automation Opportunities

### 1. Empty Directory Detection (Available)

**Existing Tool**:
```bash
.claude/scripts/detect-empty-topics.sh         # List empty topics
.claude/scripts/detect-empty-topics.sh --cleanup  # Remove empty topics
```

**Output**:
```
Found 19 empty topic directories:
  - 632_test_workflow_description
  - 663_661_and_the_standards_in_claude_docs_to_avoid
  ...

Run with --cleanup to remove these directories
```

### 2. Cross-Reference Scanner (New Tool Needed)

**Proposed Tool**: `.claude/scripts/scan-cross-references.sh`
```bash
#!/bin/bash
# Scan for cross-references to a file or directory
# Usage: ./scan-cross-references.sh .claude/specs/coordinate_output.md

TARGET="$1"
BASENAME=$(basename "$TARGET")

echo "=== Cross-References to $BASENAME ==="
grep -r "$BASENAME" .claude/ --include="*.md" --exclude-dir=specs | \
  awk -F: '{print $1}' | sort | uniq -c | sort -rn

echo ""
echo "=== Total References: $(grep -r "$BASENAME" .claude/ --include="*.md" --exclude-dir=specs | wc -l) ==="
```

### 3. Migration Assistant (New Tool Needed)

**Proposed Tool**: `.claude/scripts/migrate-to-topic.sh`
```bash
#!/bin/bash
# Migrate loose file to topic directory structure
# Usage: ./migrate-to-topic.sh coordinate_output.md 714_coordinate_execution_examples

SOURCE="$1"
TOPIC="$2"
ARTIFACT_TYPE="${3:-reports}"  # plans, reports, summaries

# Create topic structure
mkdir -p ".claude/specs/$TOPIC/$ARTIFACT_TYPE"

# Generate numbered filename
NEXT_NUM=$(ls -1 ".claude/specs/$TOPIC/$ARTIFACT_TYPE/" | \
  grep -E '^[0-9]{3}_' | sed 's/^\([0-9]*\)_.*/\1/' | sort -n | tail -1)
NEXT_NUM=${NEXT_NUM:-000}
NEXT_NUM=$(printf "%03d" $((10#$NEXT_NUM + 1)))

# Derive filename from source
BASENAME=$(basename "$SOURCE" .md)
DEST=".claude/specs/$TOPIC/$ARTIFACT_TYPE/${NEXT_NUM}_${BASENAME}.md"

# Move with git history preservation
git mv "$SOURCE" "$DEST"

echo "Migrated: $SOURCE → $DEST"
echo "Update cross-references with:"
echo "  find .claude/ -type f -name '*.md' -exec sed -i 's|$SOURCE|$DEST|g' {} +"
```

### 4. Validation Suite (Enhancement)

**Add to existing test suite**:
```bash
# .claude/tests/test_directory_structure.sh

test_no_loose_files() {
  local loose_files=$(find .claude/specs -maxdepth 1 -type f -name "*.md" ! -name "README.md")
  assert_empty "$loose_files" "No loose markdown files in specs root"
}

test_all_topics_numbered() {
  local unnumbered=$(find .claude/specs -maxdepth 1 -type d ! -name "specs" ! -name ".*" | \
    grep -v -E '/[0-9]{3}_')
  assert_empty "$unnumbered" "All topic directories use NNN_ prefix"
}

test_no_empty_topics() {
  local empty=$(.claude/scripts/detect-empty-topics.sh | grep -c "empty")
  assert_equals 0 "$empty" "No empty topic directories exist"
}
```

## Conclusion

### Safety Criteria Summary

**Safe to Remove Immediately** (Tier 1):
- Empty topic directories: 19 directories (100% safe)
- Automation available: `.claude/scripts/detect-empty-topics.sh --cleanup`

**Safe with Migration** (Tier 2-3):
- Non-standard directories: 2 directories (requires renumbering)
- Loose markdown files: 12 files (5 active → migrate, 7 orphaned → delete)
- Estimated effort: 4-8 hours

**Requires Structural Migration** (Tier 4):
- Top-level artifact directories: 255 files (requires comprehensive migration)
- Estimated effort: 8-12 hours
- High risk if done incorrectly

### Key Success Factors

1. **Incremental Approach**: Remove in phases, validate each step
2. **Backup First**: Always create timestamped backups before removal
3. **Cross-Reference Tracking**: Update all references before deleting
4. **Workflow Validation**: Test all commands after each phase
5. **Git History Preservation**: Use `git mv` and `git rm`, never force delete tracked files
6. **Documentation Updates**: Keep CLAUDE.md and guides synchronized with changes

### Recommended Timeline

- **Week 1**: Phase 1 (empty directories) - Zero risk, immediate value
- **Week 2**: Phase 2 (non-standard names) - Low risk, prepares for future
- **Week 3-4**: Phase 3 (loose files) - Medium risk, requires careful migration
- **Week 5-8**: Phase 4 (structural migration) - High complexity, phased approach

**Total Cleanup Effort**: 8-10 weeks for complete cleanup
**Quick Win**: Week 1 removes 19 directories (immediate 8% reduction in directory count)

## References

- [Directory Protocols](.claude/docs/concepts/directory-protocols.md)
- [Development Workflow](.claude/docs/concepts/development-workflow.md)
- [Empty Directory Detection](.claude/scripts/detect-empty-topics.sh)
- [Topic Utilities](.claude/lib/topic-utils.sh)
- [Unified Location Detection](.claude/lib/unified-location-detection.sh)
