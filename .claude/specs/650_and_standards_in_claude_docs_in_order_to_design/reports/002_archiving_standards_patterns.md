# Archiving Standards and Directory Organization Patterns Research

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: Archiving standards and patterns for plan archival infrastructure
- **Report Type**: codebase analysis and pattern recognition
- **Related Spec**: 650 (Plan Archive Infrastructure for Completed Plans)
- **Previous Report**: 001_plan_archival_infrastructure_analysis.md

## Executive Summary

This research identifies comprehensive archiving standards and directory organization patterns across the Claude Code infrastructure. Key findings: (1) No formal archiving standards exist beyond spec 650's initial analysis, (2) Directory Protocols documentation defines artifact lifecycle but not archival procedures, (3) Gitignore compliance patterns are well-established with debug/ committed and plans/reports/summaries/ gitignored, (4) Existing utilities (cleanup_plan_directory, ensure_artifact_directory, rollback-command-file.sh) provide reusable patterns for archival operations, (5) Writing Standards mandate timeless documentation without historical markers, (6) Backup retention policies define cleanup patterns but not archival workflows, (7) Error handling patterns emphasize verification checkpoints and graceful degradation. These findings provide the foundation for implementing a standards-compliant plan archival system.

## Findings

### 1. Directory Protocols Documentation (Primary Reference)

**File**: `.claude/docs/concepts/directory-protocols.md` (1,045 lines)

**Structure Standards**:
- Topic-based organization: `specs/{NNN_topic}/{artifact_type}/`
- Eight subdirectory types with distinct lifecycle policies
- Lazy directory creation (on-demand, not eager)
- Numbering convention: Three-digit sequential within artifact type (001, 002, 003)

**Artifact Taxonomy** (lines 177-297):
```
specs/{NNN_topic}/
├── plans/          # Active implementation plans (gitignored, indefinite retention)
├── reports/        # Research reports (gitignored, indefinite retention)
├── summaries/      # Implementation summaries (gitignored, indefinite retention)
├── debug/          # Debug reports (COMMITTED, permanent retention)
├── scripts/        # Investigation scripts (gitignored, 0 days retention)
├── outputs/        # Test outputs (gitignored, 0 days retention)
├── artifacts/      # Operation artifacts (gitignored, 30 days retention)
└── backups/        # Backups (gitignored, 30 days retention)
```

**Key Observation**: No `archived/` subdirectory defined in standard structure. This confirms spec 650's finding that archival is not yet implemented.

**Artifact Lifecycle** (lines 447-536):
- Phase 1: Creation (manual or automatic via agents)
- Phase 2: Usage (cross-referencing, workflow consumption)
- Phase 3: Cleanup (automatic for temporary artifacts)
- Phase 4: Archival (documented but not implemented)

**Retention Policies Table** (line 524):
| Artifact Type | Retention Policy | Cleanup Trigger | Automated |
|---------------|------------------|-----------------|-----------|
| Debug reports | Permanent | Never | No |
| Investigation scripts | 0 days | Workflow completion | Yes |
| Test outputs | 0 days | Test verification complete | Yes |
| Operation artifacts | 30 days | Configurable age-based | Optional |
| Backups | 30 days | Operation verified successful | Optional |
| Reports | Indefinite | Never | No |
| Plans | Indefinite | Never | No |
| Summaries | Indefinite | Never | No |

**Notable Absence**: Plans listed as "Indefinite" retention with "Never" cleanup trigger. No mention of archival workflow for completed plans.

### 2. Gitignore Compliance Standards

**File**: `.gitignore` (lines 80-87)

```gitignore
# Archive directory (local only, not tracked)
.claude/archive/

# Topic-based specs organization (added by /migrate-specs)
# Gitignore all specs subdirectories
specs/*/*
# Un-ignore debug subdirectories within topics
!specs/*/debug/
!specs/*/debug/**
```

**Key Observations**:
1. `.claude/archive/` is explicitly gitignored and documented as "local only, not tracked"
2. All `specs/{topic}/{artifact}/` directories are gitignored via pattern
3. Exception: `debug/` subdirectories are UN-gitignored (committed to git)
4. Pattern supports any subdirectory name (including potential `archived/`)

**Implication for Archival**:
- Archived plans would be gitignored by default (consistent with active plans)
- No special gitignore rule needed for `specs/{topic}/archived/`
- Pattern `specs/*/*` covers both `plans/` and potential `archived/`
- Local-only archival aligns with existing gitignore philosophy

**Verification Commands** (lines 330-357):
```bash
# Test gitignore rules
git check-ignore -v specs/042_auth/debug/001_issue.md
# Expected: No output (not ignored)

git check-ignore -v specs/042_auth/reports/001_research.md
# Expected: .gitignore:N:specs/ (gitignored)
```

### 3. Existing Utilities for Archival Operations

#### 3.1 cleanup_plan_directory()

**File**: `.claude/lib/plan-core-bundle.sh` (lines 1093-1158)

**Purpose**: Move plan file back to parent and delete directory (Level 1 → 0 during collapse)

**Current Implementation**:
```bash
cleanup_plan_directory() {
  local plan_dir="$1"
  local plan_name=$(basename "$plan_dir")
  local plan_file="$plan_dir/$plan_name.md"
  local parent_dir=$(dirname "$plan_dir")
  local target_file="$parent_dir/$plan_name.md"

  # Move plan file
  mv "$plan_file" "$target_file"

  # Delete directory
  rm -rf "$plan_dir"
}
```

**Reusability for Archival**:
- Pattern can be adapted for moving plans to archived/ subdirectory
- Handles file movement with error checking
- Already integrated with plan operations
- Used during collapse operations (Level 1 → Level 0)

**Adaptation Required**:
- Change target from parent to archived/ subdirectory
- Preserve directory structure for Level 1/2 plans
- Add timestamp to archived filename

#### 3.2 ensure_artifact_directory()

**File**: `.claude/lib/unified-location-detection.sh` (lines 1-150)

**Purpose**: Lazy directory creation (create parent directory only when writing files)

**Usage Pattern**:
```bash
# Before writing any file, ensure parent directory exists
source .claude/lib/unified-location-detection.sh
ensure_artifact_directory "$FILE_PATH" || exit 1
echo "content" > "$FILE_PATH"
```

**Benefits**:
- Eliminates 400-500 empty directories across codebase
- 80% reduction in mkdir calls during location detection
- Directories exist only when they contain actual artifacts

**Reusability for Archival**:
- Use to create archived/ subdirectory on-demand
- Consistent with lazy creation pattern
- No pre-creation of archived/ for every topic

#### 3.3 Rollback Utility

**File**: `.claude/lib/rollback-command-file.sh` (96 lines)

**Purpose**: Restore backup files with verification and safety nets

**Error Handling Pattern** (lines 40-75):
```bash
# Create a backup of current state before rollback (safety net)
if [[ -f "$ORIG_PATH" ]]; then
  SAFETY_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  SAFETY_BACKUP="${ORIG_PATH}.pre-rollback-${SAFETY_TIMESTAMP}"
  cp "$ORIG_PATH" "$SAFETY_BACKUP"
fi

# Perform rollback
cp "$BACKUP_PATH" "$ORIG_PATH"

# Verify rollback
RESTORED_HASH=$(sha256sum "$ORIG_PATH" | cut -d' ' -f1)
if [[ "$BACKUP_HASH" != "$RESTORED_HASH" ]]; then
  echo "ERROR: Rollback verification failed - checksum mismatch"
  # Restore safety backup
  cp "$SAFETY_BACKUP" "$ORIG_PATH"
  exit 1
fi
```

**Patterns Applicable to Archival**:
1. **Safety Nets**: Create backup before destructive operation
2. **Verification**: Checksum validation after file operations
3. **Graceful Degradation**: Rollback on verification failure
4. **Logging**: Record operations to log file

**Adaptation for Archival**:
- Create safety backup before moving plan to archived/
- Verify file integrity after move operation
- Rollback capability if archival fails
- Log archival operations for audit trail

### 4. Metadata Extraction Utilities

**File**: `.claude/lib/metadata-extraction.sh` (lines 1-200)

**Functions Available**:
- `extract_report_metadata()` - Extract title, 50-word summary, file paths, recommendations
- `extract_plan_metadata()` - Extract title, date, phases, complexity, time estimate
- `extract_summary_metadata()` - Extract workflow type, artifacts count, test status

**Plan Metadata Structure** (lines 89-166):
```json
{
  "title": "Plan Title",
  "date": "2025-11-10",
  "phases": 7,
  "complexity": "Medium",
  "time_estimate": "4-6 hours",
  "success_criteria": 12,
  "path": "/path/to/plan.md",
  "size": 15234
}
```

**Reusability for Archival**:
- Extract metadata before archival for archival index
- Generate README.md for archived/ subdirectory with plan metadata
- Enable discovery of archived plans by metadata search
- Support "why was this archived" documentation

**Context Reduction Pattern** (lines 146-174):
- Metadata-only passing reduces context usage by 95%
- Pass path + summary (250 tokens) instead of full content (5000 tokens)
- Load full content on-demand using Read tool

### 5. Documentation Standards (Writing Standards)

**File**: `.claude/docs/concepts/writing-standards.md` (558 lines)

**Timeless Writing Principles** (lines 67-139):

**Key Rules**:
1. **Present-focused**: Document current state, not historical changes
2. **Ban temporal markers**: Never use "(New)", "(Old)", "(Updated)", "(Deprecated)"
3. **Ban temporal phrases**: Avoid "previously", "recently", "now supports", "used to"
4. **No migration language**: Avoid "migrated to", "replaces the old", "backward compatibility"

**Example Violations**:
```markdown
❌ The system now supports archival (temporal phrase)
❌ Plans are archived after completion (New) (temporal marker)
❌ Migrated to archived/ subdirectory (migration language)
❌ This replaces the old plan cleanup approach (comparison)
```

**Correct Approach**:
```markdown
✓ The system supports plan archival
✓ Completed plans are stored in archived/ subdirectory
✓ Plans use archived/ subdirectory for completed implementations
✓ Archival provides organized storage for completed plans
```

**Implication for Archival Documentation**:
- Archival guides must describe current behavior without historical context
- No documentation of "before archival" vs "after archival"
- Focus on "what archival does" not "why we added archival"
- Exception: CHANGELOG.md can document historical additions

**Legitimate Technical Usage** (lines 254-286):
- "recently modified files" - OK (file state attribute)
- "most recently completed plan" - OK (conversation state)
- "If no longer needed" - OK (conditional statement)
- "Last updated: 2025-11-10" - OK (metadata field)

### 6. Backup Retention Policy

**File**: `.claude/docs/reference/backup-retention-policy.md` (230 lines)

**Retention Guidelines for Plans** (lines 33-40):
```
Retention Policy:
- Keep plan file backups: Until plan completion
- Remove after implementation summary created
- Keep one backup if plan archived for reference

Rationale: Plans are iteratively refined. Backups enable rollback during
active development. Once complete and summarized, original plan serves
as historical record.
```

**Cleanup Commands** (lines 108-148):
```bash
# List all backup files with sizes
find . -name "*.backup-*" -ls

# Remove backups older than 30 days
find . -name "*.backup-*" -mtime +30 -delete

# Remove all backups for spec 497 (after completion)
rm .claude/specs/497_*/plans/*.backup-*
```

**Patterns Applicable to Archival**:
1. **Completion-based cleanup**: Remove backups after summary created
2. **Age-based cleanup**: Remove artifacts older than N days
3. **Verification period**: Keep backups for 7-14 days after changes
4. **Archive before deletion**: Compress old artifacts rather than delete

**Archival Timing Insight**:
- Backups removed "after implementation summary created"
- This is same completion signal for plan archival
- Suggests archival should happen at same checkpoint as backup cleanup

### 7. Development Workflow Integration

**File**: `.claude/docs/concepts/development-workflow.md` (109 lines)

**Artifact Lifecycle Section** (lines 40-75):

Defines 6 artifact lifecycle categories:
1. **Core Planning Artifacts** (reports/, plans/, summaries/)
   - Created during planning/research
   - Preserved indefinitely
   - Never cleaned up

2. **Debug Reports** (debug/)
   - Created during debugging
   - Preserved permanently
   - COMMITTED to git

3. **Investigation Scripts** (scripts/)
   - Created during debugging
   - Temporary (0 days retention)
   - Automatic cleanup after workflow completion

4. **Test Outputs** (outputs/)
   - Created during testing
   - Temporary (0 days retention)
   - Automatic cleanup after verification

5. **Operation Artifacts** (artifacts/)
   - Created during expansion/collapse
   - Optional cleanup (30 days retention)
   - Configurable age-based

6. **Backups** (backups/)
   - Created during migrations/operations
   - Optional cleanup (30 days retention)
   - Configurable age-based

**Notable Absence**: No "Archived Plans" category defined in lifecycle documentation.

**Shell Utilities Section** (lines 76-82):
```bash
- create_topic_artifact <topic-dir> <type> <name> <content> - Create artifact
- cleanup_topic_artifacts <topic-dir> <type> [age-days] - Clean specific type
- cleanup_all_temp_artifacts <topic-dir> - Clean all temporary artifacts
```

**Reusability**:
- `create_topic_artifact()` can be used to create archived plans
- `cleanup_topic_artifacts()` pattern for age-based archival cleanup
- Integration point: Add archival to workflow completion

### 8. Error Handling Patterns

**File**: `.claude/lib/checkpoint-utils.sh` (referenced in spec 650)

**Verification Checkpoint Pattern**:
```bash
# Standard pattern from checkpoint-utils.sh
operation_function() {
  # Perform operation
  local result=$(do_operation)

  # Verify success
  if [ ! -f "$expected_file" ]; then
    echo "ERROR: Operation failed - file not created"
    return 1
  fi

  # Verify content
  if [ $(wc -l < "$expected_file") -lt 10 ]; then
    echo "WARNING: File may be incomplete"
  fi

  echo "✓ Operation verified"
  return 0
}
```

**Principles for Archival**:
1. **Mandatory Verification**: Check file exists after move
2. **Content Validation**: Verify file size/integrity after archival
3. **Fail-Fast**: Return error immediately on verification failure
4. **Diagnostic Output**: Clear error messages for debugging

**Standard 0 (Execution Enforcement)**:
- Add verification checkpoint before considering archival complete
- Confirm plan moved successfully
- Verify archived file is readable
- Check cross-references updated

### 9. Cross-Reference Management

**From Directory Protocols** (lines 279-290):

**Files that reference plan paths**:
1. **Checkpoints**: `plan_path` field (deleted on completion, no stale paths)
2. **Summaries**: Reference source plan in metadata section
3. **Execution logs**: Phase-by-phase plan references

**Impact of Archival**:
- Checkpoint already deleted on completion → no update needed
- Summaries can be updated with archive location
- Log references are immutable → use archived plan path

**Cross-Reference Update Strategy**:
```bash
# Update summary file with archived plan path
update_summary_plan_reference() {
  local summary_file="$1"
  local old_path="$2"
  local new_path="$3"

  # Update Plan field in metadata
  sed -i "s|Plan: $old_path|Plan: $new_path (archived)|" "$summary_file"
}
```

### 10. README Generation Patterns

**From Directory Protocols** (lines 296-297):

**README Requirements**:
- Every subdirectory must have a README.md
- Purpose: Clear explanation of directory role
- Content: Module documentation, usage examples, navigation links

**Example Structure**:
```markdown
# Archived Plans

## Overview
Completed implementation plans archived after implementation summary created.

## Archive Format
- Filename: `{original_number}_{topic_name}_archived_{YYYYMMDD}.md`
- Organized by completion date
- Cross-referenced in implementation summaries

## Discovery
Use /list-plans --archived to discover archived plans.

## Restoration
Use restore_archived_plan() to restore plan to active plans/ directory.
```

**Pattern for Archival**:
- Generate README.md automatically when archived/ directory created
- Include discovery commands
- Link to related summaries
- Provide restoration instructions

### 11. Existing Spec 650 Analysis

**File**: `.claude/specs/650_plan_archive_infrastructure_for_completed_plans/reports/001_plan_archival_infrastructure_analysis.md` (420 lines)

**Key Findings from Previous Report**:
1. No existing archival system (0 archived/ directories found)
2. Completion detection via checkpoint deletion + summary existence
3. Integration point: /implement Phase 2 (after summary finalization)
4. Estimated effort: 4-6 hours (200-300 lines utility, 10-15 lines integration)

**Proposed Architecture** (lines 33-56):
```bash
# Utility library: plan-archival.sh
is_plan_complete(plan_file)           # Detect completion
archive_plan(plan_file, summary_file) # Move to archived/
verify_archive(archived_path)         # Verify success
list_archived_plans(topic)            # Discovery
```

**Directory Structure** (lines 48-55):
```
specs/{NNN_topic}/
├── plans/          # Active plans
├── archived/       # Completed plans (proposed)
├── summaries/      # Implementation summaries
└── debug/          # Committed reports
```

**Completion Detection** (lines 59-78):
- Summary file exists
- Checkpoint deleted
- All tests passed
- Git commits created
- `CURRENT_PHASE == TOTAL_PHASES`

### 12. Spec 483 Archival Precedent

**Directory**: `.claude/specs/483_remove_all_mentions_of_archived_content_in_claude_/`

**Observation**: Spec 483 discusses removing mentions of "archived content", but no archival system exists. This suggests previous discussions about archival without implementation.

**Status**: Gitignored spec with no committed artifacts (consistent with policy).

### 13. Lazy Directory Creation Pattern

**From Unified Location Detection** (lines 41-43):

**Pattern**:
```bash
# Before writing any file, ensure parent directory exists
ensure_artifact_directory "$FILE_PATH" || exit 1
echo "content" > "$FILE_PATH"
```

**Benefits** (lines 10-14):
- Creates directories only when files are written
- Eliminates 400-500 empty directories
- 80% reduction in mkdir calls
- Directories exist only when they contain actual artifacts

**Application to Archival**:
- Don't create archived/ subdirectory eagerly for all topics
- Create archived/ only when first plan is archived
- Consistent with existing lazy creation philosophy
- No overhead for topics with no completed plans

### 14. Plan Structure Levels

**From Directory Protocols** (lines 798-823):

**Level 0: Single File**
- Format: `NNN_plan_name.md`
- All phases inline in single file

**Level 1: Phase Expansion**
- Format: `NNN_plan_name/` directory with phase files
- Main plan: `NNN_plan_name.md` (with summaries)
- Expanded phases: `phase_N_name.md`

**Level 2: Stage Expansion**
- Format: Phase directories with stage subdirectories
- Phase directory: `phase_N_name/`
- Stage files: `stage_M_name.md`

**Implication for Archival**:
- Level 0 plans: Archive single .md file
- Level 1 plans: Archive entire directory (main plan + phase files)
- Level 2 plans: Archive entire hierarchy (main plan + phase dirs + stage files)
- Archival must preserve directory structure for complex plans

### 15. Standards Compliance Requirements

**Standard 0: Execution Enforcement** (.claude/docs/reference/command_architecture_standards.md)
- Add MANDATORY VERIFICATION checkpoint before archival
- Verify file moved successfully
- Confirm archived file is readable
- Check cross-references updated

**Standard 13: Project Directory Detection**
- Use detect-project-dir.sh pattern
- Respect CLAUDE_PROJECT_DIR environment variable
- Support git worktrees

**Standard 14: Executable/Documentation Separation**
- Implement archival as shared utility library (plan-archival.sh)
- Keep /implement command lean (<250 lines)
- Create comprehensive guide (plan-archival-guide.md)

### 16. Testing Infrastructure

**From Directory Protocols** (lines 265-275):

**Test Files for Relevant Components**:
- `test_checkpoint_utils.sh` - Checkpoint operations
- `test_state_machine.sh` - Workflow state transitions
- `test_plan_parsing.sh` - Plan structure detection
- `test_implement_integration.sh` - /implement command workflow

**Pattern for Archival Tests**:
- Create `test_plan_archival.sh` following existing patterns
- Test cases:
  - Plan completion detection
  - Archive directory creation (lazy)
  - File move operations (Level 0/1/2)
  - Gitignore compliance
  - Cross-reference updates
  - Verification checkpoints
  - Rollback on failure

### 17. Atomic Operations (Concurrency Safety)

**From Unified Location Detection** (lines 14-33):

**Atomic Topic Allocation Pattern**:
```
Race Condition (OLD):
  Process A: get_next_topic_number() -> 042 [lock released]
  Process B: get_next_topic_number() -> 042 [lock released]
  Result: Duplicate topic numbers, directory conflicts

Atomic Operation (NEW):
  Process A: [lock acquired] -> calculate 042 -> mkdir 042_a [lock released]
  Process B: [lock acquired] -> calculate 043 -> mkdir 043_b [lock released]
  Result: 100% unique topic numbers, 0% collision rate
```

**Implication for Archival**:
- Archival operations may need atomic locking
- Prevent concurrent archival of same plan
- Ensure unique archived filenames with timestamps
- Lock hold time should be minimal (<15ms)

**Recommendation**: Use similar flock pattern for archival:
```bash
archive_plan() {
  (
    flock -x 200
    # Generate timestamp
    # Move plan to archived/
    # Update cross-references
  ) 200>/tmp/plan_archival.lock
}
```

## Recommendations

### 1. Archival Utility Library Design

**Create**: `.claude/lib/plan-archival.sh` (200-300 lines)

**Functions**:
```bash
is_plan_complete()           # Completion detection via checkpoint + summary
archive_plan()               # Move plan to archived/ with verification
verify_archive()             # Post-archival verification checkpoint
list_archived_plans()        # Discovery of archived plans
restore_archived_plan()      # Restore plan from archived/ to plans/
generate_archive_readme()    # Create/update archived/README.md
```

**Error Handling**:
- Safety backup before archival
- Checksum verification after move
- Rollback on verification failure
- Comprehensive logging to `.claude/data/logs/archival-operations.log`

### 2. Directory Structure Standards

**Add to Directory Protocols**:
```
specs/{NNN_topic}/
├── plans/                   # Active implementation plans
├── archived/                # Completed plans (local only, gitignored)
│   ├── README.md           # Auto-generated archive index
│   ├── 001_feature_archived_20251110.md    # Level 0 plan
│   └── 002_enhancement_archived_20251108/  # Level 1 plan directory
│       ├── 002_enhancement_archived_20251108.md
│       └── phase_3_implementation.md
├── summaries/               # Implementation summaries
└── debug/                   # Committed reports
```

**Lazy Creation**: Create archived/ only when first plan archived

**Gitignore**: Already covered by `specs/*/*` pattern

### 3. Archival Naming Convention

**Level 0 Plans** (single file):
```
{original_number}_{topic_name}_archived_{YYYYMMDD}.md
Example: 001_authentication_archived_20251110.md
```

**Level 1/2 Plans** (directories):
```
{original_number}_{topic_name}_archived_{YYYYMMDD}/
Example: 002_user_profile_archived_20251110/
```

**Rationale**:
- Preserves original plan number for traceability
- Timestamp indicates completion date
- `_archived_` suffix prevents name collision with active plans
- Supports multiple archival events for same topic

### 4. Cross-Reference Update Strategy

**Summary File Updates**:
```bash
# Update implementation summary with archived plan path
update_summary_plan_reference() {
  local summary_file="$1"
  local archived_path="$2"
  local completion_date="$3"

  # Add archived plan reference to metadata
  sed -i "/- \*\*Plan\*\*:/a\\
- **Archived**: $archived_path\\
- **Completion Date**: $completion_date" "$summary_file"
}
```

**Checkpoint Handling**:
- No updates needed (checkpoint deleted on completion)

**Log References**:
- Immutable (no updates)
- Reference archived path in new logs

### 5. Integration with /implement Command

**Location**: `.claude/commands/implement.md` Phase 2 (after summary finalization)

**Integration Code** (~10-15 lines):
```bash
# NEW: Archive the completed plan
if is_plan_complete "$PLAN_FILE"; then
  echo "CHECKPOINT: Archiving completed plan"
  archive_plan "$PLAN_FILE" "$FINAL_SUMMARY" || {
    echo "WARNING: Plan archival failed, plan remains in plans/"
  }
  verify_archive "$ARCHIVED_PATH" || {
    echo "ERROR: Archive verification failed"
  }
fi
```

**Placement**: After line 216 (after summary finalization, before checkpoint deletion)

### 6. Documentation Standards Compliance

**Create**: `.claude/docs/guides/plan-archival-guide.md` (1,000-1,500 lines)

**Content Requirements**:
- Timeless writing (no "now supports", "previously", etc.)
- Present-focused descriptions
- Usage examples without historical context
- Troubleshooting scenarios
- Integration with workflow commands

**Update**: `.claude/docs/concepts/directory-protocols.md`
- Add archived/ to artifact taxonomy (section 2)
- Document archival lifecycle phase (section 6)
- Include archival in cleanup utilities (section 7)

### 7. Automated Cleanup Patterns

**Optional Age-Based Cleanup**:
```bash
# Clean archived plans older than 365 days
cleanup_topic_artifacts() {
  local topic_dir="$1"
  local age_days="${2:-365}"

  find "$topic_dir/archived" -name "*_archived_*.md" -mtime +$age_days -delete
  find "$topic_dir/archived" -name "*_archived_*" -type d -mtime +$age_days -exec rm -rf {} +
}
```

**Compression Pattern** (from Backup Retention Policy):
```bash
# Compress archived plans older than 90 days
compress_old_archives() {
  local topic_dir="$1"

  find "$topic_dir/archived" -name "*_archived_*.md" -mtime +90 | while read plan; do
    gzip "$plan"
  done
}
```

### 8. Discovery and Listing Functions

**List Archived Plans**:
```bash
list_archived_plans() {
  local topic_dir="$1"
  local archived_dir="$topic_dir/archived"

  if [ ! -d "$archived_dir" ]; then
    echo "[]"
    return 0
  fi

  # Extract metadata from each archived plan
  local plans=()
  for plan in "$archived_dir"/*.md "$archived_dir"/*/*.md; do
    if [ -f "$plan" ]; then
      local metadata=$(extract_plan_metadata "$plan")
      plans+=("$metadata")
    fi
  done

  # Return JSON array
  printf '%s\n' "${plans[@]}" | jq -s '.'
}
```

**Integration with /list-plans Command**:
- Add `--archived` flag to list archived plans
- Include archived plans in metadata extraction
- Support filtering by completion date

### 9. Restoration Capability

**Restore Function**:
```bash
restore_archived_plan() {
  local archived_path="$1"
  local topic_dir=$(dirname "$(dirname "$archived_path")")
  local plans_dir="$topic_dir/plans"

  # Safety backup before restoration
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local safety_backup="${archived_path}.pre-restore-${timestamp}"
  cp "$archived_path" "$safety_backup"

  # Determine original filename (remove _archived_YYYYMMDD suffix)
  local original_name=$(basename "$archived_path" | sed 's/_archived_[0-9]\{8\}//')
  local target_path="$plans_dir/$original_name"

  # Move back to plans/
  mv "$archived_path" "$target_path"

  # Verify restoration
  if [ ! -f "$target_path" ]; then
    # Rollback
    mv "$safety_backup" "$archived_path"
    echo "ERROR: Restoration failed"
    return 1
  fi

  echo "✓ Plan restored: $target_path"
  return 0
}
```

### 10. README Generation for Archived Subdirectory

**Auto-Generate on First Archival**:
```bash
generate_archive_readme() {
  local archived_dir="$1"
  local readme_path="$archived_dir/README.md"

  cat > "$readme_path" <<'EOF'
# Archived Plans

## Overview
Completed implementation plans archived after implementation summary created.

## Archive Format
- Filename: `{number}_{topic}_archived_{YYYYMMDD}.md`
- Directories: `{number}_{topic}_archived_{YYYYMMDD}/` (for expanded plans)
- Organized by completion date

## Discovery
List archived plans:
```bash
/list-plans --archived
```

## Restoration
Restore archived plan to active plans/:
```bash
restore_archived_plan specs/{topic}/archived/{plan}.md
```

## Cross-References
Each archived plan is referenced in its implementation summary.

## Retention
Archived plans retained indefinitely (local gitignored artifacts).
Optional compression after 90 days: `compress_old_archives {topic_dir}`
EOF
}
```

### 11. Testing Strategy

**Create**: `.claude/tests/test_plan_archival.sh`

**Test Cases** (8-12 tests):
1. `test_is_plan_complete_detection` - Verify completion detection
2. `test_archive_level_0_plan` - Archive single-file plan
3. `test_archive_level_1_plan` - Archive directory plan
4. `test_archive_level_2_plan` - Archive hierarchical plan
5. `test_lazy_archived_directory_creation` - Verify on-demand creation
6. `test_cross_reference_update` - Verify summary updates
7. `test_gitignore_compliance` - Check archived/ is gitignored
8. `test_verification_checkpoint` - Verify fail-fast on errors
9. `test_rollback_on_failure` - Verify rollback when archival fails
10. `test_list_archived_plans` - Verify discovery function
11. `test_restore_archived_plan` - Verify restoration capability
12. `test_archive_readme_generation` - Verify README auto-generation

### 12. Logging and Audit Trail

**Log File**: `.claude/data/logs/archival-operations.log`

**Log Format**:
```
[2025-11-10T14:32:15-05:00] ARCHIVE: specs/042_auth/plans/001_oauth.md -> specs/042_auth/archived/001_oauth_archived_20251110.md
[2025-11-10T14:32:15-05:00] VERIFY: Archive integrity confirmed (SHA256: abc123...)
[2025-11-10T14:32:16-05:00] UPDATE: Summary cross-reference updated: specs/042_auth/summaries/001_summary.md
[2025-11-10T14:32:16-05:00] COMPLETE: Plan archival successful
```

**Rotation Policy**: 10MB max, 5 files retained (consistent with adaptive-planning.log)

## References

### Core Documentation Files
- `.claude/docs/concepts/directory-protocols.md` (1,045 lines)
- `.claude/docs/concepts/development-workflow.md` (109 lines)
- `.claude/docs/concepts/writing-standards.md` (558 lines)
- `.claude/docs/reference/backup-retention-policy.md` (230 lines)
- `.gitignore` (lines 80-87)

### Utility Libraries
- `.claude/lib/plan-core-bundle.sh` (cleanup_plan_directory function, line 1093)
- `.claude/lib/unified-location-detection.sh` (ensure_artifact_directory function)
- `.claude/lib/metadata-extraction.sh` (extract_plan_metadata function, line 89)
- `.claude/lib/rollback-command-file.sh` (error handling patterns)

### Existing Research
- `.claude/specs/650_plan_archive_infrastructure_for_completed_plans/reports/001_plan_archival_infrastructure_analysis.md` (420 lines)
- `.claude/specs/650_plan_archive_infrastructure_for_completed_plans/README.md` (113 lines)

### Standards References
- `.claude/docs/reference/command_architecture_standards.md` (Standards 0, 13, 14)
- `.claude/docs/concepts/patterns/verification-fallback.md` (Verification checkpoint pattern)

### Integration Points
- `.claude/commands/implement.md` (Phase 2, after line 216)
- `.claude/commands/list-plans.md` (Add --archived flag support)

---

**Report Complete**: 2025-11-10
**Lines Analyzed**: 3,500+ across 15 core files
**Patterns Identified**: 17 categories (directory structure, gitignore, utilities, error handling, documentation, testing, etc.)
**Ready for Planning**: Yes - comprehensive foundation for plan archival implementation
