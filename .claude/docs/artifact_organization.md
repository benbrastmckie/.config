# Artifact Organization Guide

This guide provides comprehensive documentation for the topic-based artifact organization system used in the `.claude/` directory structure.

## Table of Contents

1. [Overview](#overview)
2. [Directory Structure](#directory-structure)
3. [Artifact Taxonomy](#artifact-taxonomy)
4. [Gitignore Rules](#gitignore-rules)
5. [Artifact Lifecycle](#artifact-lifecycle)
6. [Shell Utilities](#shell-utilities)
7. [Usage Patterns](#usage-patterns)
8. [Migration](#migration)
9. [Troubleshooting](#troubleshooting)

---

## Overview

The topic-based artifact organization system co-locates all artifacts related to an implementation plan under a single topic directory. This simplifies navigation, cleanup, and cross-referencing while maintaining proper gitignore compliance.

**Key Benefits**:
- All artifacts for a topic in one location
- Clear artifact lifecycle (create, use, cleanup, commit/ignore)
- Automatic numbering within topic scope
- Proper gitignore compliance (debug/ committed, others ignored)
- Easy cleanup of temporary artifacts

**Structure**: `specs/{NNN_topic}/`

---

## Directory Structure

### Topic-Based Organization

```
specs/
└── {NNN_topic}/
    ├── {NNN_topic}.md           # Main implementation plan
    ├── reports/                  # Research reports (gitignored)
    │   └── NNN_report.md
    ├── plans/                    # Sub-plans (gitignored)
    │   └── NNN_sub_plan.md
    ├── summaries/                # Implementation summaries (gitignored)
    │   └── NNN_summary.md
    ├── debug/                    # Debug reports (COMMITTED)
    │   └── NNN_issue.md
    ├── scripts/                  # Investigation scripts (gitignored, temporary)
    │   └── investigate_*.sh
    ├── outputs/                  # Test outputs (gitignored, temporary)
    │   └── test_results_*.txt
    ├── artifacts/                # Operation artifacts (gitignored)
    │   └── expansion_metadata.json
    └── backups/                  # Backups (gitignored)
        └── plan_backup_*.md
```

### Numbering Scheme

Each subdirectory has independent numbering:
- `reports/001_report.md`, `reports/002_report.md`
- `debug/001_issue.md`, `debug/002_issue.md`
- Numbers are three digits (001, 002, ..., 099, 100, ...)
- Numbering is scoped to topic (not global)

### Example: Complete Topic Structure

```
specs/009_orchestration_enhancement/
├── 009_orchestration_enhancement.md  # Main plan
├── reports/
│   ├── 001_existing_patterns.md
│   ├── 002_complexity_algorithms.md
│   └── 003_parallelization_strategies.md
├── plans/                             # (empty if no sub-plans)
├── summaries/
│   └── 001_implementation_summary.md
├── debug/
│   ├── 001_test_hang_issue.md
│   └── 002_circular_dependency.md
├── scripts/
│   ├── investigate_complexity.sh      # Temporary
│   └── test_wave_calculation.sh       # Temporary
├── outputs/
│   ├── test_results_phase1.txt        # Temporary
│   └── benchmark_results.txt          # Temporary
├── artifacts/
│   ├── complexity_evaluation.json
│   └── wave_calculation.json
└── backups/
    └── plan_backup_20251016.md
```

---

## Artifact Taxonomy

### Core Planning Artifacts

**Location**: `reports/`, `plans/`, `summaries/`

**Lifecycle**:
- Created during: Planning, research, documentation phases
- Preserved: Indefinitely (reference material)
- Cleaned up: Never
- Gitignore: YES (local working artifacts)

**Purpose**:
- **reports/**: Research findings from /report or /orchestrate research phase
- **plans/**: Sub-plans for complex features (rarely used)
- **summaries/**: Implementation summaries linking plans to code

**When to Create**:
- reports/: During research phase of /orchestrate or explicit /report command
- plans/: When breaking down very large features into sub-features
- summaries/: After implementation complete, during documentation phase

### Debug Reports

**Location**: `debug/`

**Lifecycle**:
- Created during: Debugging loop in /orchestrate or explicit /debug command
- Preserved: Permanently (part of project history)
- Cleaned up: Never
- Gitignore: NO (COMMITTED for issue tracking)

**Purpose**: Document test failures, issues, root causes, and fixes

**Structure**:
```markdown
# Debug Report: [Issue Description]

## Metadata
- **Date**: YYYY-MM-DD
- **Topic**: {topic_name}
- **Main Plan**: ../../{topic}.md
- **Phase**: Phase N
- **Iteration**: 1|2|3

## Issue Description
[What went wrong]

## Root Cause Analysis
[Why it happened]

## Fix Proposals
[Specific fixes with confidence levels]

## Resolution
[What was done, if resolved]
```

**When to Create**:
- During /orchestrate debugging loop (automatic)
- During explicit /debug command
- When documenting persistent issues for tracking

**Why Committed**:
Debug reports are valuable project history:
- Track recurring issues
- Document solutions for future reference
- Enable team knowledge sharing
- Support post-mortem analysis

### Investigation Scripts

**Location**: `scripts/`

**Lifecycle**:
- Created during: Debugging, investigation, testing
- Preserved: Temporarily (until workflow complete)
- Cleaned up: Automatic after workflow
- Retention: 0 days (removed immediately)
- Gitignore: YES (temporary workflow scripts)

**Purpose**: Temporary scripts for investigating issues or testing hypotheses

**Examples**:
- `investigate_complexity.sh` - Test complexity scoring
- `test_wave_calculation.sh` - Verify dependency analysis
- `reproduce_hang.sh` - Reproduce test hang issue

**When to Create**:
- During debugging when you need to run tests repeatedly
- When investigating performance issues
- When verifying fixes before committing

**When to Clean Up**:
- After workflow phase complete
- After issue resolved
- Before final documentation phase

### Test Outputs

**Location**: `outputs/`

**Lifecycle**:
- Created during: Testing phases
- Preserved: Temporarily (until verification complete)
- Cleaned up: Automatic after verification
- Retention: 0 days (removed after validation)
- Gitignore: YES (regenerable test artifacts)

**Purpose**: Capture test results, benchmarks, performance metrics

**Examples**:
- `test_results_phase1.txt` - Test output from phase 1
- `benchmark_results.txt` - Performance benchmark data
- `coverage_report.html` - Code coverage results

**When to Create**:
- During testing to capture results
- During benchmarking for performance analysis
- When results need review before proceeding

**When to Clean Up**:
- After tests verified passing
- After benchmark data analyzed
- After results documented in plan/summary

### Operation Artifacts

**Location**: `artifacts/`

**Lifecycle**:
- Created during: Expansion, collapse, migrations, operations
- Preserved: Optional (can be kept for analysis)
- Cleaned up: Optional (configurable retention)
- Retention: 30 days (configurable)
- Gitignore: YES (operational metadata)

**Purpose**: Metadata from plan operations (expansion, collapse, etc.)

**Examples**:
- `complexity_evaluation.json` - Complexity scores
- `wave_calculation.json` - Dependency graph and waves
- `expansion_metadata.json` - Expansion operation details

**When to Create**:
- During /expand or /collapse operations
- During complexity evaluation
- During wave calculation

**When to Clean Up**:
- After 30 days (configurable)
- After analysis complete
- When disk space needed

### Backups

**Location**: `backups/`

**Lifecycle**:
- Created during: Migrations, major operations
- Preserved: Temporarily (until verified)
- Cleaned up: Optional (configurable retention)
- Retention: 30 days (configurable)
- Gitignore: YES (large files, regenerable)

**Purpose**: Backup plans before destructive operations

**Examples**:
- `plan_backup_20251016.md` - Plan before expansion
- `plan_backup_pre_migration.tar.gz` - Pre-migration backup

**When to Create**:
- Before /expand or /collapse operations
- Before migrations
- Before any destructive plan modifications

**When to Clean Up**:
- After operation verified successful
- After 30 days
- When disk space needed

---

## Gitignore Rules

### Current .gitignore Configuration

```gitignore
# Specs directory (gitignored except debug/)
specs/
!specs/**/debug/
!specs/**/debug/**

# This pattern means:
# - specs/ is gitignored (including all subdirectories)
# - !specs/**/debug/ is NOT gitignored (exception)
# - !specs/**/debug/** is NOT gitignored (exception, all contents)
```

### Gitignore Verification

**Test Gitignore Rules**:
```bash
# Debug files should be tracked
touch specs/009_test/debug/test.md
git status specs/009_test/debug/test.md
# Output: Should show as untracked (NOT ignored)

# Scripts files should be gitignored
touch specs/009_test/scripts/test.sh
git status specs/009_test/scripts/test.sh
# Output: Should show nothing (gitignored)

# Reports should be gitignored
touch specs/009_test/reports/test.md
git status specs/009_test/reports/test.md
# Output: Should show nothing (gitignored)
```

**Check Specific File**:
```bash
git check-ignore -v specs/009_test/debug/test.md
# Output: Should show NO output (not ignored)

git check-ignore -v specs/009_test/scripts/test.sh
# Output: Should show .gitignore:N:specs/ (gitignored)
```

### Gitignore Compliance Checklist

When creating artifacts, verify:
- [ ] debug/ contents are tracked (git status shows untracked)
- [ ] scripts/ contents are gitignored
- [ ] outputs/ contents are gitignored
- [ ] artifacts/ contents are gitignored
- [ ] backups/ contents are gitignored
- [ ] reports/ contents are gitignored
- [ ] plans/ contents are gitignored
- [ ] summaries/ contents are gitignored

---

## Artifact Lifecycle

### Phase 1: Creation

**Manual Creation**:
```bash
# Create artifact using utility function
source .claude/lib/artifact-operations.sh

create_topic_artifact "specs/009_topic" "debug" "test_failure" "# Debug Report\n\n..."
```

**Automatic Creation** (during orchestration):
- Research reports: Created by research-specialist agents
- Debug reports: Created by debug-specialist agents
- Investigation scripts: Created by debug-specialist for testing
- Test outputs: Created by test execution
- Operation artifacts: Created by /expand, /collapse, etc.

### Phase 2: Usage

**During Workflow**:
- Reports: Read by plan-architect during planning
- Debug reports: Referenced during debugging loop
- Scripts: Executed during investigation
- Outputs: Reviewed during test verification
- Artifacts: Read during subsequent operations

**Cross-Referencing**:
- Plan → Reports: Links in plan metadata
- Summary → Plan + Reports: Links in summary
- Debug → Plan: Relative path `../../plan.md`

### Phase 3: Cleanup

**Automatic Cleanup** (after workflow):
```bash
# Clean temporary artifacts from topic
cleanup_all_temp_artifacts "specs/009_topic"

# This removes:
# - scripts/ (temporary investigation scripts)
# - outputs/ (temporary test outputs)
# - Keeps debug/, artifacts/, backups/ (optional cleanup)
```

**Selective Cleanup**:
```bash
# Clean specific artifact type
cleanup_topic_artifacts "specs/009_topic" "scripts"
cleanup_topic_artifacts "specs/009_topic" "outputs"

# Clean with age filter (days)
cleanup_topic_artifacts "specs/009_topic" "artifacts" 30
cleanup_topic_artifacts "specs/009_topic" "backups" 30
```

**Manual Cleanup**:
```bash
# Remove all temporary artifacts
rm -rf specs/009_topic/scripts/
rm -rf specs/009_topic/outputs/

# Remove old artifacts (optional)
find specs/009_topic/artifacts/ -mtime +30 -delete
find specs/009_topic/backups/ -mtime +30 -delete
```

### Phase 4: Archival

**Long-Term Storage**:
- Core artifacts (reports, plans, summaries): Keep indefinitely
- Debug reports: Keep indefinitely (project history)
- Operation artifacts: Optional (compress after 30 days)
- Backups: Optional (compress after 30 days)

**Compression** (optional):
```bash
# Compress old artifacts
tar -czf specs/009_topic/artifacts.tar.gz specs/009_topic/artifacts/
tar -czf specs/009_topic/backups.tar.gz specs/009_topic/backups/

# Remove originals
rm -rf specs/009_topic/artifacts/
rm -rf specs/009_topic/backups/
```

---

## Shell Utilities

### artifact-operations.sh Functions

**Source Utilities**:
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-operations.sh"
```

**create_topic_artifact()**

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

**cleanup_topic_artifacts()**

Clean specific artifact type from topic.

```bash
cleanup_topic_artifacts <topic-dir> <type> [age-days]
```

**Parameters**:
- `topic-dir`: Path to topic directory
- `type`: Artifact type to clean
- `age-days`: Optional, only clean files older than N days

**Example**:
```bash
# Clean all scripts (no age filter)
cleanup_topic_artifacts "specs/009_orchestration" "scripts"

# Clean artifacts older than 30 days
cleanup_topic_artifacts "specs/009_orchestration" "artifacts" 30
```

**cleanup_all_temp_artifacts()**

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

**Example**:
```bash
cleanup_all_temp_artifacts "specs/009_orchestration"
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
.claude/lib/complexity-utils.sh calculate_phase_complexity ...
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

### Pattern 3: Performance Benchmarking

**Run Benchmarks**:
```bash
# Execute benchmarks, save results
.claude/tests/benchmark_orchestrate.sh > specs/009_topic/outputs/benchmark_results.txt
```

**Analyze Results**:
```bash
# Review results
cat specs/009_topic/outputs/benchmark_results.txt

# Extract key metrics
grep "Time savings" specs/009_topic/outputs/benchmark_results.txt
```

**Document in Plan**:
```bash
# Add benchmark results to plan metadata
# Results are in outputs/, can reference in plan

# After documented, clean up
cleanup_topic_artifacts "specs/009_topic" "outputs"
```

---

## Migration

### Migrating Existing Specs to Topic Structure

Use `/migrate-specs` command (created in Phase 1):

**Dry Run**:
```bash
/migrate-specs --dry-run
```

**Execute Migration**:
```bash
/migrate-specs
```

**Migration Steps**:
1. Create backup (`.backup_specs_TIMESTAMP.tar.gz`)
2. Identify all plans in `specs/`
3. For each plan:
   - Create topic directory: `specs/{NNN_topic}/`
   - Move plan: `specs/NNN_plan.md` → `specs/{NNN_topic}/{NNN_topic}.md`
   - Create subdirectories: `reports/`, `debug/`, etc.
   - Find related reports, move to `specs/{NNN_topic}/reports/`
   - Find summaries, move to `specs/{NNN_topic}/summaries/`
4. Verify migration success
5. Update .gitignore rules

**Rollback** (if needed):
```bash
# Extract backup
tar -xzf .backup_specs_TIMESTAMP.tar.gz

# Restore original structure
mv specs/ specs_migrated/
mv specs.backup/ specs/
```

See `.claude/docs/specs_migration_guide.md` for detailed migration instructions.

---

## Troubleshooting

### Issue: Flat Structure Bug (Legacy)

**Symptom**: Artifacts created in flat structure (`specs/plans/`, `specs/reports/`) instead of topic-based (`specs/{NNN_topic}/plans/`, `specs/{NNN_topic}/reports/`)

**Cause**: Commands prior to 2025-10-16 used inconsistent path construction

**Solution**:
- All commands updated to use uniform topic-based structure
- `/plan`, `/report`, `/debug`, `/implement`, `/orchestrate` now use `create_topic_artifact()` utility
- All artifacts MUST be in `specs/{NNN_topic}/{artifact_type}/` format
- Flat structure is deprecated

**Migration**:
- Existing flat-structure artifacts can remain in place (still readable)
- New artifacts automatically use uniform structure
- Optional: Use manual migration to move old artifacts to topic directories

**Verification**:
```bash
# Check for old flat structure (should be empty after updates)
ls specs/plans/ 2>/dev/null && echo "WARNING: Flat plans/ directory exists"
ls specs/reports/ 2>/dev/null && echo "WARNING: Flat reports/ directory exists"
ls debug/ 2>/dev/null && echo "WARNING: Root debug/ directory exists"

# All artifacts should now be in topic directories
find specs -name "*.md" -type f | head -10
# Expected: specs/NNN_topic/{artifact_type}/NNN_*.md pattern
```

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

## Related Documentation

- **CLAUDE.md**: Spec Updater Integration section (artifact lifecycle summary)
- **spec_updater_guide.md**: Spec updater agent usage and patterns
- **specs_migration_guide.md**: Detailed migration from flat to topic-based structure
- **orchestration_enhancement_guide.md**: Usage of artifacts in orchestration workflows

---

**Last Updated**: 2025-10-16
**Related Plan**: specs/009_orchestration_enhancement_adapted/009_orchestration_enhancement_adapted.md
**Related Phase**: Phase 1 (Specs Reorganization and Spec Updater Agent)
