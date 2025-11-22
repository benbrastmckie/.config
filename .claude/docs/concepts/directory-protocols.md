# Directory Protocols

Comprehensive guide for the topic-based artifact organization system used in specs/ directories.

## Table of Contents

1. [Overview](#overview)
2. [Directory Structure](#directory-structure)
3. [Artifact Taxonomy](#artifact-taxonomy)
4. [Gitignore Compliance](#gitignore-compliance)
5. [Artifact Lifecycle](#artifact-lifecycle)
6. [Shell Utilities](#shell-utilities)
7. [Usage Patterns](#usage-patterns)
8. [Troubleshooting](#troubleshooting)

---

## Overview

[Used by: /report, /plan, /implement, /debug, /orchestrate, /list-plans, /list-reports, /list-summaries]

The topic-based artifact organization system co-locates all artifacts related to a feature under a single numbered topic directory. This simplifies navigation, cleanup, and cross-referencing while maintaining proper gitignore compliance.

**Key Benefits**:
- All artifacts for a feature in one directory
- Clear artifact lifecycle (create → use → complete → archive)
- Automatic numbering within topic scope
- Proper gitignore compliance (debug/ committed, others ignored)
- Easy cleanup of temporary artifacts
- Metadata-only artifact references reduce context usage by 95%

**Structure**: `specs/{NNN_topic}/{artifact_type}/NNN-artifact-name.md`

**Naming Conventions**:
- **Directories**: snake_case with underscores (e.g., `918_topic_naming_standards/`)
- **Files**: kebab-case with hyphens (e.g., `001-topic-naming-plan.md`)

---

## Directory Structure

### Topic-Based Organization

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

### Topic Directories

- **Format**: `NNN_topic_name/` (e.g., `042_authentication/`, `000_initial/`)
- **Numbering**: Three-digit sequential numbers starting from 000 (000, 001, 002...)
- **Rollover**: Numbers wrap from 999 to 000 (with collision detection)
- **Naming**: Snake_case describing the feature or area
- **Scope**: Contains all artifacts for a single feature or related area

### Topic Naming

Topic directories use AI-powered semantic naming to generate meaningful, descriptive names from user prompts.

**LLM-Based Naming System**:

The system uses a Haiku LLM agent (topic-naming-agent) that analyzes user descriptions and generates semantic topic names. The agent understands context, extracts key technical terms, and formats names as snake_case directory names.

**Naming Process**:
1. Commands invoke topic-naming-agent with user's feature description
2. Agent analyzes semantic meaning (5-15 word prompts)
3. Agent extracts technical terms, action verbs, domain concepts
4. Agent returns formatted name: `^[a-z0-9_]{5,40}$`
5. Commands validate format and create directory

**Commands Using LLM Naming** (7 total):
- /plan, /research, /debug, /optimize-claude
- /errors, /setup (analyze mode), /repair

**Fallback Behavior**:
- Agent timeout (>5s): Falls back to `NNN_no_name_error/` sentinel
- Validation failure: Falls back to `NNN_no_name_error/` sentinel
- Empty prompt: Falls back to `NNN_no_name_error/` sentinel
- Failures logged to centralized error log for investigation
- `no_name_error` clearly signals LLM failure for post-hoc correction

**Examples**:
| User Description | Generated Name |
|------------------|----------------|
| "Fix JWT token expiration bug causing login failures" | `jwt_token_expiration_fix` |
| "Implement OAuth authentication with SSO support" | `oauth_auth_sso_implementation` |
| "Refactor state machine transitions in build command" | `state_machine_transitions_refactor` |
| "Add rate limiting to API gateway endpoints" | `api_gateway_rate_limiting` |
| "Research database connection pooling strategies" | `database_connection_pooling` |

**Monitoring Failures**:
Use `.claude/scripts/check_no_name_directories.sh` to identify naming failures:
```bash
# Check for naming failures
.claude/scripts/check_no_name_directories.sh

# Investigate failures
/errors --type agent_error --command /plan

# Rename no_name directories manually
.claude/scripts/rename_no_name_directory.sh specs/867_no_name jwt_token_fix
```

**Format Requirements**:
- Length: 5-40 characters (optimized for readability)
- Character set: Lowercase letters, digits, underscores only
- Pattern: `^[a-z0-9_]{5,40}$`
- No consecutive underscores
- Must start and end with alphanumeric character

### Atomic Topic Allocation

All commands that create topic directories MUST use atomic allocation to prevent race conditions and ensure sequential numbering.

**Standard Pattern**:
```bash
# 1. Source required libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/topic-utils.sh"

# 2. Generate semantic topic slug (preferred: use sanitize_topic_name)
TOPIC_SLUG=$(sanitize_topic_name "$DESCRIPTION")

# Alternative: Use LLM-generated slug if classification available
# TOPIC_SLUG=$(validate_topic_directory_slug "$CLASSIFICATION_JSON" "$DESCRIPTION")

# 3. Atomically allocate topic directory
RESULT=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_SLUG")
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to allocate topic directory"
  exit 1
fi

# 4. Extract topic number and path
TOPIC_NUMBER="${RESULT%|*}"
TOPIC_PATH="${RESULT#*|}"
```

**Why Atomic Allocation?**

The `allocate_and_create_topic()` function holds an exclusive file lock through BOTH topic number calculation AND directory creation. This eliminates the race condition that occurs with the count-then-create pattern.

**Race Condition (Unsafe Pattern)**:
```
Time  Process A              Process B
T0    count dirs -> 25
T1                           count dirs -> 25
T2    calc next -> 26
T3                           calc next -> 26
T4    mkdir 026_a
T5                           mkdir 026_b (COLLISION!)
```

**Atomic Operation (Safe Pattern)**:
```
Time  Process A                        Process B
T0    [LOCK] count -> 25, calc -> 26
T1                                     [WAITING FOR LOCK]
T2    mkdir 026_a [UNLOCK]
T3                                     [LOCK] count -> 26, calc -> 27
T4                                     mkdir 027_b [UNLOCK]
```

**Performance**: Atomic allocation adds ~10ms overhead per topic creation due to lock contention. This is acceptable for human-driven workflow commands.

**Numbering Behavior**:
- **First topic**: 000 (not 001)
- **Rollover**: After 999, numbers wrap to 000
- **Collision detection**: If the calculated number already exists (after rollover), finds next available
- **Full exhaustion**: Returns error if all 1000 numbers are used (rare edge case)

**Lock File**: `${specs_root}/.topic_number.lock`
- Created automatically on first allocation
- Never deleted (persists for subsequent allocations)
- Empty file (<1KB, gitignored)
- Lock released automatically when process exits

**Concurrency Guarantee**: Tested with 1000 concurrent allocations, 0% collision rate.

**Commands Using Atomic Allocation**:
- `/plan` - Creates implementation plan topic
- `/plan` - Creates research+plan topic
- `/debug` - Creates debug topic
- `/research` - Creates research-only topic
- `/research` - Creates hierarchical research topic

**See**: [Unified Location Detection API](../reference/library-api/overview.md#allocate_and_create_topic) for complete function documentation.

### Artifact Numbering

Within each artifact type subdirectory:
- Files use three-digit numbering: `001_name.md`, `002_name.md`
- Numbering resets per topic and artifact type
- Automatic numbering handled by `get_next_artifact_number()`

### Lazy Directory Creation

Subdirectories are created **on-demand** when files are written, not eagerly when topics are created.

**Benefits**:
- Eliminates 400-500 empty directories across codebase
- 80% reduction in mkdir calls during location detection
- Directories exist only when they contain actual artifacts

**Implementation**:
```bash
# Before writing any file, ensure parent directory exists
source .claude/lib/core/unified-location-detection.sh
ensure_artifact_directory "$FILE_PATH" || exit 1
echo "content" > "$FILE_PATH"
```

**Usage in commands**:
- `/report`: Creates `reports/` only when writing report files
- `/plan`: Creates `plans/` only when writing plan files
- `/research`: Creates `reports/{NNN_research}/` hierarchy on-demand

**See**: [Library API Reference](../reference/library-api/overview.md#ensure_artifact_directory) for complete documentation

**Example**:
```
specs/042_authentication/
├── plans/
│   ├── 001_user_auth.md
│   └── 002_session.md
├── reports/
│   ├── 001_auth_patterns.md            # Single-topic report (/report command)
│   ├── 002_security_practices.md       # Single-topic report
│   └── 003_research/                   # Hierarchical research (/research command)
│       ├── 001_jwt_patterns.md         # Individual subtopic
│       ├── 002_oauth_flows.md          # Individual subtopic
│       ├── 003_security_best_practices.md  # Individual subtopic
│       └── OVERVIEW.md                 # Final synthesis (ALL CAPS, not numbered)
└── debug/
    └── 001_token_refresh.md
```

**Hierarchical Research Subdirectories**:
- Created by `/research` command for multi-subtopic investigations
- Format: `NNN_research/` within `reports/` directory
- Contains numbered individual subtopic reports (001, 002, 003...)
- Contains `OVERVIEW.md` (ALL CAPS, not numbered) as final synthesis
- OVERVIEW.md distinguishes final synthesis from individual subtopic reports

### Common Violation: Eager mkdir in Commands

Commands MUST NOT create artifact subdirectories (`reports/`, `debug/`, `plans/`, `summaries/`) eagerly during setup. This violates the lazy directory creation standard and creates empty directories that persist when workflows fail.

**ANTI-PATTERN** (Historical - Fixed in Spec 870):

```bash
# WRONG: Command creates subdirectories during setup (debug.md, plan.md, etc.)
initialize_workflow_paths "$TOPIC_NAME" || exit 1

RESEARCH_DIR="${TOPIC_PATH}/reports"
DEBUG_DIR="${TOPIC_PATH}/debug"
PLANS_DIR="${TOPIC_PATH}/plans"

# Eager directory creation (VIOLATES lazy creation standard)
mkdir -p "$RESEARCH_DIR"
mkdir -p "$DEBUG_DIR"
mkdir -p "$PLANS_DIR"

# Agent invoked later...
# If workflow fails before agent writes files, empty directories persist
```

**Why This Is Wrong**:

When commands create subdirectories during setup, any workflow failure or interruption before file creation leaves empty directories:

```bash
# Workflow execution timeline
1. initialize_workflow_paths creates topic root: specs/042_auth/
2. Command creates subdirectories: specs/042_auth/reports/, specs/042_auth/debug/
3. User cancels workflow (Ctrl+C) or workflow fails before agent runs
4. Result: Empty subdirectories persist indefinitely

# Real-world impact
specs/042_auth/
├── reports/     # EMPTY - workflow cancelled before research phase
└── debug/       # EMPTY - workflow failed before debug phase
```

**Impact Evidence**:

This anti-pattern was systematically identified and remediated in Spec 870 after root cause analysis:

- **Spec 867**: Empty `debug/` directory created 8 minutes before topic directory (timestamp analysis)
- **Spec 869**: Root cause investigation found 10 violations across 6 commands
- **Accumulated Impact**: 400-500+ empty subdirectories across `.claude/specs/` before remediation
- **False Signals**: Empty directories suggested failed workflows, complicating debugging
- **Standard Violation**: Contradicts lazy creation pattern documented in this file

**Correct Pattern**:

Commands assign directory paths but do NOT create directories. Agents create directories on-demand when writing files:

```bash
# CORRECT: Command setup (path assignment only)
initialize_workflow_paths "$TOPIC_NAME" || exit 1

RESEARCH_DIR="${TOPIC_PATH}/reports"
DEBUG_DIR="${TOPIC_PATH}/debug"
PLANS_DIR="${TOPIC_PATH}/plans"

# No mkdir here - agents handle lazy creation

# In agent behavioral guidelines (e.g., research-specialist.md)
source .claude/lib/core/unified-location-detection.sh

REPORT_PATH="${RESEARCH_DIR}/001_analysis.md"

# Ensure parent directory exists (lazy creation pattern)
ensure_artifact_directory "$REPORT_PATH" || {
  echo "ERROR: Failed to create parent directory for report" >&2
  exit 1
}

# Write tool creates file
# Directory created ONLY when file is written
```

**Workflow Timeline (Correct)**:

```bash
# Workflow execution timeline
1. initialize_workflow_paths creates topic root: specs/042_auth/
2. Command assigns path variables (NO mkdir)
3. Agent calls ensure_artifact_directory() before writing file
4. Directory created: specs/042_auth/reports/
5. File written: specs/042_auth/reports/001_analysis.md

# If workflow fails at step 3 (before agent runs):
specs/042_auth/          # Topic root exists (correct)
# No subdirectories - clean state (correct)

# If workflow succeeds:
specs/042_auth/
└── reports/
    └── 001_analysis.md  # Directory + file both exist (correct)
```

**Audit Checklist for Command Development**:

When developing or modifying commands, verify:

- [ ] Command DOES NOT use `mkdir -p "$RESEARCH_DIR"`
- [ ] Command DOES NOT use `mkdir -p "$DEBUG_DIR"`
- [ ] Command DOES NOT use `mkdir -p "$PLANS_DIR"`
- [ ] Command DOES NOT use `mkdir -p "$SUMMARIES_DIR"`
- [ ] Agent behavioral guidelines DO call `ensure_artifact_directory()` before file writes
- [ ] Only exception: Atomic directory+file creation (mkdir immediately followed by file write in same bash block)

**Verification Commands**:

```bash
# Check for violations (should return empty or only atomic patterns)
grep 'mkdir -p "\$RESEARCH_DIR"' .claude/commands/*.md | grep -v backup
grep 'mkdir -p "\$DEBUG_DIR"' .claude/commands/*.md | grep -v backup
grep 'mkdir -p "\$PLANS_DIR"' .claude/commands/*.md | grep -v backup

# Verify agents use lazy creation (should return multiple matches)
grep 'ensure_artifact_directory' .claude/agents/*.md
```

**See Also**:
- [Code Standards - Directory Creation Anti-Patterns](../reference/standards/code-standards.md#directory-creation-anti-patterns) - Complete anti-pattern documentation with examples
- [Unified Location Detection Library](../reference/library-api/overview.md#ensure_artifact_directory) - `ensure_artifact_directory()` function API
- [Spec 870 Implementation](../../specs/870_fix_lazy_directory_creation_violations_across_6_co/plans/001_fix_lazy_directory_creation_violations_a_plan.md) - Systematic remediation of violations
```

### Complete Topic Structure Example

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

### Artifact Traceability

Implementation summaries create a traceability chain to research reports through plan links:

```
Summary → Plan → Reports
   ↓         ↓
   ↓         └─ Plan metadata contains report links
   ↓
   └─ Summary metadata contains plan link
```

**Traceability Pattern**:
- Summaries link to plans in metadata section
- Plans link to reports in metadata section
- This creates complete traceability without redundant linking

**Path Format**:
- From summaries: `../plans/001_plan.md` (relative path for portability)
- From plans: `../reports/001_report.md` (relative path for portability)

**Example Summary Metadata**:
```markdown
## Metadata
- **Date**: 2025-11-19 14:30
- **Plan**: [Implementation Plan](../plans/001_implementation.md)
- **Phases Completed**: 5/5
- **Git Commits**: [abc123, def456]
```

**Example Plan Metadata**:
```markdown
## Metadata
- **Research Reports**:
  - [Auth Patterns](../reports/001_auth_patterns.md)
  - [Security Practices](../reports/002_security_practices.md)
```

**Why This Pattern**:
- Co-located directory structure makes navigation trivial
- Plans already link to reports (no need for summaries to duplicate)
- Relative paths ensure portability across systems
- Complete traceability with minimal linking overhead

### Metadata-Only References

Artifacts should be referenced by **path + metadata**, not full content, to minimize context usage (see [Command Architecture Standards - Standards 6-8](../reference/architecture/overview.md#context-preservation-standards)).

**Metadata Extraction Utilities** (`.claude/lib/workflow/metadata-extraction.sh`):
- `extract_report_metadata(report_path)` - Extracts title, 50-word summary, key findings, file paths
- `extract_plan_metadata(plan_path)` - Extracts complexity, phases, time estimates, dependencies
- `load_metadata_on_demand(artifact_path)` - Generic metadata loader with caching

**Usage Pattern**:
```bash
# Extract metadata from research reports
for report in "${RESEARCH_REPORTS[@]}"; do
  METADATA=$(extract_report_metadata "$report")
  # METADATA: path, 50-word summary, key findings
  REPORT_REFS+=("$METADATA")
done

# Pass metadata (250 tokens) instead of full content (5000 tokens)
Task {
  prompt: "...
          Research Reports (metadata):
          ${REPORT_REFS[@]}

          Use Read tool to access full content selectively if needed.
          ..."
}
# Context reduction: 95%
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

## Shell Utilities

### metadata-extraction.sh Functions

**Source Utilities**:
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/workflow/metadata-extraction.sh"
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

**extract_report_metadata()**

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

**extract_plan_metadata()**

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

**load_metadata_on_demand()**

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
**Context Usage**: 15,000 tokens (3 reports × 5000 tokens each)

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

## Plan Structure Levels

Plans use progressive organization that grows based on actual complexity discovered during implementation:

**Level 0: Single File** (All plans start here)
- Format: `NNN_plan_name.md`
- All phases and tasks inline in single file
- Use: All features start here, regardless of anticipated complexity

**Level 1: Phase Expansion** (Created on-demand via `/expand-phase`)
- Format: `NNN_plan_name/` directory with some phases in separate files
- Created when a phase proves too complex during implementation
- Structure:
  - `NNN_plan_name.md` (main plan with summaries)
  - `phase_N_name.md` (expanded phase details)

**Level 2: Stage Expansion** (Created on-demand via `/expand-stage`)
- Format: Phase directories with stage subdirectories
- Created when phases have complex multi-stage workflows
- Structure:
  - `NNN_plan_name/` (plan directory)
    - `phase_N_name/` (phase directory)
      - `phase_N_overview.md`
      - `stage_M_name.md` (stage details)

**Progressive Expansion**: Use `/expand-phase <plan> <phase-num>` to extract complex phases. Use `/expand-stage <phase> <stage-num>` to extract complex stages. Structure grows organically based on implementation needs.

**Collapse Operations**: Use `/collapse-phase` and `/collapse-stage` to merge content back and simplify structure.

---

## Phase Dependencies and Wave-Based Execution

Plans support phase dependency declarations that enable parallel execution of independent phases during implementation.

**Dependency Syntax**:
```markdown
### Phase N: [Phase Name]

**Dependencies**: [] or [1, 2, 3]
**Risk**: Low|Medium|High
**Estimated Time**: X-Y hours
```

**Dependency Format**:
- `Dependencies: []` - No dependencies (independent phase, can run in parallel)
- `Dependencies: [1]` - Depends on phase 1 (waits for phase 1 to complete)
- `Dependencies: [1, 2]` - Depends on phases 1 and 2
- `Dependencies: [1, 3, 5]` - Depends on multiple phases

**Rules**:
- Dependencies are phase numbers (integers)
- A phase can only depend on earlier phases (no forward dependencies)
- Circular dependencies are detected and rejected during wave calculation
- Self-dependencies are invalid

**Wave-Based Execution**:
- Orchestrator calculates execution waves using topological sorting (Kahn's algorithm)
- Independent phases within a wave execute in parallel (40-60% time savings)
- Sequential phases execute in dependency order
- Wave execution is automatic when using `/orchestrate`

**Example**:
```markdown
### Phase 1: Foundation Setup
**Dependencies**: []  # No dependencies - Wave 1

### Phase 2: Database Schema
**Dependencies**: [1]  # Depends on Phase 1 - Wave 2

### Phase 3: API Endpoints
**Dependencies**: [1]  # Depends on Phase 1 - Wave 2 (parallel with Phase 2)

### Phase 4: Integration Tests
**Dependencies**: [2, 3]  # Depends on Phases 2 and 3 - Wave 3
```

This creates 3 execution waves:
- Wave 1: Phase 1
- Wave 2: Phases 2 and 3 (parallel execution)
- Wave 3: Phase 4

See [phase_dependencies.md](../reference/workflows/phase-dependencies.md) for detailed dependency syntax and examples.

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

**Target Characteristics**:
- Length: 15-35 characters (shorter is better for command-line use)
- Format: Snake_case with semantic terms only
- Content: Technical/domain terms, no planning meta-words
- No artifacts: No file extensions, basenames, or directory references

**Good Examples**:

| Topic Name | Length | Why Good |
|------------|--------|----------|
| `042_authentication` | 14 chars | Clear, concise, semantic |
| `015_jwt_token_refresh` | 18 chars | Specific technical feature |
| `027_state_machine_fix` | 18 chars | Action + component clear |
| `001_error_handling` | 14 chars | Well-scoped feature area |
| `033_api_rate_limiting` | 18 chars | Specific implementation |

**Poor Examples**:

| Topic Name | Length | Problem | Better Alternative |
|------------|--------|---------|-------------------|
| `042_misc` | 5 chars | Too vague | `042_utility_functions` |
| `001_stuff` | 6 chars | Unclear meaning | `001_project_setup` |
| `099_temp` | 4 chars | Temporary placeholder | `099_config_migration` |
| `050_carefully_research_authentication` | 35 chars | Contains meta-word "carefully" | `050_authentication_research` |
| `066_create_plan_implementation` | 28 chars | Planning verbs, no semantic content | `066_feature_implementation` |
| `078_001_report_findings` | 21 chars | Contains artifact references | `078_security_findings` |

**Naming Guidelines**:

1. **Use domain/technical terms**: `authentication`, `jwt_token`, `state_machine`, `api_rate_limiting`
2. **Preserve action verbs when semantic**: `fix`, `refactor`, `optimize` (not `create`, `update`, `implement`)
3. **Avoid planning meta-words**: Remove `research`, `plan`, `analyze`, `carefully`, `detailed`
4. **No artifact references**: No `001_`, `.md`, `reports`, `plans`, `readme`, `output`
5. **Concise over verbose**: `jwt_refresh` beats `jwt_token_refresh_mechanism`
6. **Word boundaries matter**: 35-char limit preserves complete words (no `auth_patte`)

### LLM Agent Integration

Commands integrate with the topic-naming-agent for semantic name generation:

**Integration Pattern**:
```bash
# Source error handling library
source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || exit 1
ensure_error_log_exists

# Set command metadata
COMMAND_NAME="/plan"  # or /research, /debug, /optimize-claude
WORKFLOW_ID="workflow_$(date +%s)"

# Invoke topic-naming-agent via Task tool
AGENT_OUTPUT=$(invoke_topic_naming_agent "$USER_DESCRIPTION")

# Parse completion signal
if echo "$AGENT_OUTPUT" | grep -q "TOPIC_NAME_GENERATED:"; then
  TOPIC_NAME=$(echo "$AGENT_OUTPUT" | grep "TOPIC_NAME_GENERATED:" | sed 's/TOPIC_NAME_GENERATED: *//')

  # Validate format
  if validate_topic_name_format "$TOPIC_NAME"; then
    # Success: use LLM-generated name
    allocate_and_create_topic "$SPECS_DIR" "$TOPIC_NAME"
  else
    # Validation failed: fallback
    log_command_error "validation_error" "Invalid topic name format" "name=$TOPIC_NAME"
    TOPIC_NAME="no_name"
  fi
else
  # Agent failed: fallback
  log_command_error "agent_error" "Topic naming agent failed" "prompt=$USER_DESCRIPTION"
  TOPIC_NAME="no_name"
fi
```

**Agent Response Time**: <3 seconds average (Haiku 4.5 optimized)
**Cost**: ~$0.003 per topic creation (~$2.16/year at typical usage)
**Failure Rate**: <5% (monitored via check_no_name_directories.sh)

**See**: [Topic Naming with LLM Guide](../guides/development/topic-naming-with-llm.md) for complete integration details, prompt engineering tips, and troubleshooting strategies.

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

- **CLAUDE.md**: Directory protocols section (specs structure summary)
- **spec_updater_guide.md**: Spec updater agent usage and patterns
- **command_architecture_standards.md**: Context preservation standards (Standards 6-8)
- **phase_dependencies.md**: Wave-based execution and dependency syntax
- **.claude/lib/workflow/metadata-extraction.sh**: Shell utility implementations

---

**Cross-Reference**: See [Command Architecture Standards](../reference/architecture/overview.md) for context preservation patterns when working with topic artifacts.
