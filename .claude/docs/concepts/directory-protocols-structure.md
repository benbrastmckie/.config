# Directory Protocols - Structure

Artifact taxonomy, gitignore compliance, and artifact lifecycle.

## Navigation

This document is part of a multi-part guide:
- [Overview](directory-protocols-overview.md) - Introduction, directory structure, and topic organization
- **Structure** (this file) - Artifact taxonomy, gitignore compliance, and lifecycle
- [Examples](directory-protocols-examples.md) - Shell utilities, usage patterns, troubleshooting, and best practices

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

**When to Create**:
- During debugging when you need to run tests repeatedly
- When investigating performance issues
- When verifying fixes before committing

### Test Outputs

**Location**: `outputs/`

**Lifecycle**:
- Created during: Testing phases
- Preserved: Temporarily (until verification complete)
- Cleaned up: Automatic after verification
- Retention: 0 days (removed after validation)
- Gitignore: YES (regenerable test artifacts)

**Purpose**: Capture test results, benchmarks, performance metrics

### Operation Artifacts

**Location**: `artifacts/`

**Lifecycle**:
- Created during: Expansion, collapse, migrations, operations
- Preserved: Optional (can be kept for analysis)
- Cleaned up: Optional (configurable retention)
- Retention: 30 days (configurable)
- Gitignore: YES (operational metadata)

**Purpose**: Metadata from plan operations (expansion, collapse, etc.)

### Backups

**Location**: `backups/`

**Lifecycle**:
- Created during: Migrations, major operations
- Preserved: Temporarily (until verified)
- Cleaned up: Optional (configurable retention)
- Retention: 30 days (configurable)
- Gitignore: YES (large files, regenerable)

**Purpose**: Backup plans before destructive operations

---

## Gitignore Compliance

### Compliance Rules

| Artifact Type | Committed to Git | Reason |
|---------------|------------------|--------|
| `debug/` | YES | Project history, issue tracking |
| `plans/` | NO | Local working artifacts |
| `reports/` | NO | Local working artifacts |
| `summaries/` | NO | Local working artifacts |
| `scripts/` | NO | Temporary investigation |
| `outputs/` | NO | Regenerable test results |
| `artifacts/` | NO | Operational metadata |
| `backups/` | NO | Temporary recovery files |

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

### Validation Utility

```bash
# Validate gitignore compliance
validate_gitignore_compliance "specs/042_auth"

# Returns JSON:
# {
#   "debug_committed": true,
#   "plans_ignored": true,
#   "reports_ignored": true,
#   "summaries_ignored": true,
#   "scripts_ignored": true,
#   "outputs_ignored": true,
#   "artifacts_ignored": true,
#   "backups_ignored": true,
#   "violations": []
# }
```

### Automatic Compliance Checking

Compliance checking integrated into workflow commands:

```bash
# /orchestrate automatically validates compliance
/orchestrate "Add authentication"

# Runs validation after artifact creation:
# - Checks debug/ tracked
# - Checks other directories ignored
# - Reports violations before proceeding
```

### Manual Compliance Verification

```bash
# Test specific file
git check-ignore -v specs/042_auth/debug/001_issue.md
# Expected: No output (not ignored)

git check-ignore -v specs/042_auth/reports/001_research.md
# Expected: .gitignore:N:specs/ (gitignored)

# Test entire topic
for type in debug plans reports summaries scripts outputs artifacts backups; do
  if [ -d "specs/042_auth/$type" ]; then
    echo "Checking $type/"
    for file in specs/042_auth/$type/*; do
      if [ "$type" = "debug" ]; then
        git check-ignore "$file" && echo "ERROR: $file should not be ignored"
      else
        git check-ignore "$file" || echo "ERROR: $file should be ignored"
      fi
    done
  fi
done
```

### Fixing Compliance Violations

**Violation: Debug files gitignored**
```bash
# Check .gitignore rules
grep -n "specs" .gitignore

# Should see exception:
# !specs/**/debug/
# !specs/**/debug/**

# If missing, add exception
echo "!specs/**/debug/" >> .gitignore
echo "!specs/**/debug/**" >> .gitignore
```

**Violation: Non-debug files tracked**
```bash
# Check what's tracked
git ls-files specs/042_auth/

# Should only show debug/ files
# If other files tracked, they were committed before gitignore
# Remove from git but keep locally:
git rm --cached specs/042_auth/reports/001_research.md
```

---

## Artifact Lifecycle

### Phase 1: Creation

**Manual Creation**:
```bash
# Create artifact using utility function
source .claude/lib/workflow/metadata-extraction.sh

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

**Retention Policies**:

| Artifact Type | Retention Policy | Cleanup Trigger | Automated |
|---------------|------------------|-----------------|-----------|
| **Debug reports** | Permanent | Never | No |
| **Investigation scripts** | 0 days | Workflow completion | Yes |
| **Test outputs** | 0 days | Test verification complete | Yes |
| **Operation artifacts** | 30 days | Configurable age-based | Optional |
| **Backups** | 30 days | Operation verified successful | Optional |
| **Reports** | Indefinite | Never | No |
| **Plans** | Indefinite | Never | No |
| **Summaries** | Indefinite | Never | No |

---

## Related Documentation

- [Overview](directory-protocols-overview.md) - Introduction, directory structure, and topic organization
- [Examples](directory-protocols-examples.md) - Shell utilities, usage patterns, troubleshooting, and best practices
