# State Management Standard

**Version**: 2.0  
**Status**: Active  
**Created**: 2025-12-29  
**Purpose**: Unified state management standard defining status markers, state schemas, and synchronization

---

## Overview

This standard defines the complete state management system for ProofChecker, including:

- **Status Markers**: Standardized markers for tracking task and phase progress
- **State Schemas**: JSON schemas for distributed state tracking
- **Status Synchronization**: Atomic multi-file update mechanisms
- **Timestamp Formats**: Consistent timestamp formatting across all files

---

## Status Markers

### Standard Status Markers

#### `[NOT STARTED]`
**Meaning**: Task or phase has not yet begun.

**Valid Transitions**:
- `[NOT STARTED]` → `[IN PROGRESS]` (work begins)
- `[NOT STARTED]` → `[BLOCKED]` (blocked before starting)

#### `[IN PROGRESS]`
**Meaning**: Task or phase is currently being worked on.

**Valid Transitions**:
- `[IN PROGRESS]` → `[COMPLETED]` (work finishes successfully)
- `[IN PROGRESS]` → `[BLOCKED]` (work encounters blocker)
- `[IN PROGRESS]` → `[ABANDONED]` (work is abandoned)

**Timestamps**: Always include `**Started**: YYYY-MM-DD`

#### `[BLOCKED]`
**Meaning**: Task or phase is blocked by dependencies or issues.

**Valid Transitions**:
- `[BLOCKED]` → `[IN PROGRESS]` (blocker resolved, work resumes)
- `[BLOCKED]` → `[ABANDONED]` (blocker cannot be resolved)

**Required Information**:
- `**Blocked**: YYYY-MM-DD` timestamp
- `**Blocking Reason**: {reason}` or `**Blocked by**: {dependency}`

#### `[ABANDONED]`
**Meaning**: Task or phase was started but abandoned without completion.

**Valid Transitions**:
- `[ABANDONED]` → `[NOT STARTED]` (restart from scratch, rare)
- `[ABANDONED]` is typically terminal

**Required Information**:
- `**Abandoned**: YYYY-MM-DD` timestamp
- `**Abandonment Reason**: {reason}`

#### `[COMPLETED]`
**Meaning**: Task or phase is finished successfully.

**Valid Transitions**: Terminal state (no further transitions)

**Required Information**:
- `**Completed**: YYYY-MM-DD` timestamp
- Do not add emojis; rely on status marker and text alone

### Command-Specific Status Markers

**In-Progress Markers**:
- `[RESEARCHING]`: Task research actively underway (used by `/research`)
- `[PLANNING]`: Implementation plan being created (used by `/plan`)
- `[REVISING]`: Plan revision in progress (used by `/revise`)
- `[IMPLEMENTING]`: Implementation work actively underway (used by `/implement`)

**Completion Markers**:
- `[RESEARCHED]`: Research completed, deliverables created
- `[PLANNED]`: Implementation plan completed, ready for implementation
- `[REVISED]`: Plan revision completed, new plan version created
- `[COMPLETED]`: Implementation finished successfully (terminal state)
- `[PARTIAL]`: Implementation partially completed (can resume)
- `[BLOCKED]`: Work blocked by dependencies or issues

### Status Transition Diagram

```
[NOT STARTED] ─────────────────────────────────────────────────┐
    │                                                           │
    │ (/research)         (/plan)          (/implement)        │
    ▼                     ▼                 ▼                  ▼
[RESEARCHING]    [PLANNING]        [IMPLEMENTING]         [BLOCKED]
    │                │                     │                   │
    ▼                ▼                     ▼                   │
[RESEARCHED] ──→ [PLANNED] ──(/revise)──→ [REVISING]          │
                    │            │             │               │
                    │            │             ▼               │
                    │            │        [REVISED]            │
                    │            └─────────────┘               │
                    │ (/implement)                             │
                    ▼                                          │
             [IMPLEMENTING] ─────────────────────────────────> │
                    │                                          │
                    ├────> [COMPLETED] (all phases done)       │
                    ├────> [PARTIAL] (some phases done)        │
                    └────> [BLOCKED] (cannot proceed) ─────────┘
                                     
    ┌──────────────────────────────────────────────────────────┘
    │ (work abandoned)
    ▼
[ABANDONED]
```

### Valid Transitions Table

| From | To | Condition |
|------|-----|-----------|
| `[NOT STARTED]` | `[RESEARCHING]` | `/research` command starts |
| `[NOT STARTED]` | `[PLANNING]` | `/plan` command starts |
| `[NOT STARTED]` | `[IMPLEMENTING]` | `/implement` command starts (no plan) |
| `[RESEARCHING]` | `[RESEARCHED]` | Research completes successfully |
| `[RESEARCHED]` | `[PLANNING]` | `/plan` command starts |
| `[PLANNING]` | `[PLANNED]` | Planning completes successfully |
| `[PLANNED]` | `[REVISING]` | `/revise` command starts |
| `[PLANNED]` | `[IMPLEMENTING]` | `/implement` command starts |
| `[IMPLEMENTING]` | `[COMPLETED]` | Implementation finishes successfully |
| `[IMPLEMENTING]` | `[PARTIAL]` | Implementation partially complete (timeout) |
| `[BLOCKED]` | `[IN PROGRESS]` | Blocker resolved, work resumes |

---

## State Schemas

### File Locations

```
.claude/specs/
├── state.json                      # Main state (cross-references, health)
├── TODO.md                         # User-facing task list
├── archive/
│   └── state.json                  # Archived project tracking
├── maintenance/
│   └── state.json                  # Maintenance operations and health
└── NNN_project_name/
    ├── reports/                    # Research and analysis reports
    ├── plans/                      # Implementation plans (versioned)
    ├── summaries/                  # Brief summaries
    └── state.json                  # Project-specific state
```

### Main State File

**Location**: `.claude/specs/state.json`

**Purpose**: Central tracking of active/completed projects, repository health, cross-references

**Schema**:
```json
{
  "_schema_version": "1.1.0",
  "_last_updated": "2025-12-29T09:00:00Z",
  "next_project_number": 90,
  "project_numbering": {
    "min": 0,
    "max": 999,
    "policy": "increment_modulo_1000"
  },
  "state_references": {
    "archive_state_path": ".claude/specs/archive/state.json",
    "maintenance_state_path": ".claude/specs/maintenance/state.json"
  },
  "active_projects": [],
  "completed_projects": [
    {
      "project_number": 62,
      "project_name": "docstring_coverage",
      "type": "documentation",
      "completed": "2025-12-18",
      "summary": "Verified 100% docstring coverage"
    }
  ],
  "repository_health": {
    "last_assessed": "2025-12-19",
    "overall_score": 94,
    "layer_0_completion": "98%",
    "active_tasks": 30,
    "technical_debt": {
      "sorry_count": 5,
      "axiom_count": 24
    }
  }
}
```

### Plan Metadata Schema

Active projects may include `plan_metadata` tracking plan characteristics and research integration:

```json
{
  "project_number": 300,
  "plan_path": ".claude/specs/300_add_report_detection_to_planner/plans/implementation-001.md",
  "plan_metadata": {
    "phases": 4,
    "total_effort_hours": 4,
    "complexity": "medium",
    "research_integrated": true,
    "plan_version": 1,
    "reports_integrated": [
      {
        "path": "reports/research-001.md",
        "integrated_in_plan_version": 1,
        "integrated_date": "2026-01-05"
      }
    ]
  }
}
```

**reports_integrated Field**:
- Tracks which research reports were integrated into which plan versions
- Enables detection of new reports created after last plan version
- Used by planner during plan revisions to avoid re-integrating old research
- Array of objects with `path`, `integrated_in_plan_version`, `integrated_date`
- Backward compatible: Missing field defaults to empty array

### Archive State File

**Location**: `.claude/specs/archive/state.json`

**Purpose**: Comprehensive tracking of archived projects with metadata, artifacts, impact

**Key Sections**:
```json
{
  "_schema_version": "1.0.0",
  "archive_metadata": {
    "total_archived_projects": 6,
    "last_updated": "2025-12-19",
    "retention_policy": "indefinite"
  },
  "archived_projects": [
    {
      "project_number": 61,
      "project_name": "add_missing_directory_readmes",
      "project_type": "documentation",
      "timeline": {
        "created": "2025-12-18",
        "completed": "2025-12-18",
        "archived": "2025-12-19",
        "duration_hours": 2.5
      },
      "artifacts": {
        "base_path": ".claude/specs/archive/061_add_missing_directory_readmes/",
        "plans": ["plans/implementation-001.md"]
      }
    }
  ]
}
```

### Maintenance State File

**Location**: `.claude/specs/maintenance/state.json`

**Purpose**: Track maintenance operations, health trends, technical debt

**Key Sections**:
```json
{
  "_schema_version": "1.0.0",
  "maintenance_metadata": {
    "last_maintenance": "2025-12-19",
    "next_scheduled": "2026-01-19",
    "maintenance_frequency": "monthly"
  },
  "maintenance_operations": [
    {
      "operation_id": "maint_20251219_001",
      "operation_type": "todo_maintenance",
      "operation_date": "2025-12-19",
      "activities": {
        "tasks_removed_from_todo": 12,
        "projects_archived": 6
      }
    }
  ],
  "health_trends": {
    "snapshots": [
      {
        "date": "2025-12-19",
        "health_score": 94,
        "sorry_count": 5,
        "active_tasks": 30
      }
    ]
  }
}
```

---

## Timestamp Formats

### TODO.md Structure

TODO.md follows standard YAML frontmatter format with metadata header at the beginning:

```markdown
---
last_updated: 2026-01-04T04:45:44Z
next_project_number: 280
repository_health:
  overall_score: 92
  production_readiness: excellent
task_counts:
  active: 4
  completed: 50
  total: 81
priority_distribution:
  high: 15
  medium: 12
  low: 11
technical_debt:
  sorry_count: 6
  axiom_count: 11
  build_errors: 11
---

# TODO

## High Priority

### 272. Task Title
- **Effort**: 14 hours
- **Status**: [PLANNED]
- **Priority**: Medium
- **Type**: markdown
- **Started**: 2025-12-20
- **Completed**: 2025-12-20
- **Blocked**: 2025-12-20
```

**YAML Header**: Auto-generated from state.json, surfaces repository health and task metrics  
**Task Timestamps**: Date only format (YYYY-MM-DD)

### Implementation Plan Format
**ISO 8601 with Timezone** (YYYY-MM-DDTHH:MM:SSZ):
```markdown
(Started: 2025-12-20T10:15:30Z)
(Completed: 2025-12-20T11:45:15Z)
```

### State File Format
**ISO 8601 Date** (YYYY-MM-DD) for status changes:
```json
{
  "started": "2025-12-20",
  "completed": "2025-12-20"
}
```

**Full ISO 8601** (YYYY-MM-DDTHH:MM:SSZ) for creation timestamps:
```json
{
  "created": "2025-12-20T10:00:00Z",
  "last_updated": "2025-12-20"
}
```

### Field Naming Convention

**Status change timestamps use simple names WITHOUT `_at` suffix**:
- `started` (NOT `started_at`)
- `completed` (NOT `completed_at`)
- `researched` (NOT `researched_at`)
- `planned` (NOT `planned_at`)
- `blocked` (NOT `blocked_at`)
- `abandoned` (NOT `abandoned_at`)

**Creation/update timestamps**:
- `created` - Full ISO8601 timestamp
- `last_updated` - Date only (YYYY-MM-DD)

---

## State Lookup Patterns

### Read/Write Separation

**Design Principle**: Use state.json for reads, status-sync-manager for writes

- **Read operations** (task lookup, validation, metadata extraction): Use state.json
- **Write operations** (status updates, artifact links): Use status-sync-manager
- **Synchronization**: Handled automatically by status-sync-manager

### Fast Task Lookup

Command files should use state.json for fast task validation and metadata extraction:

```bash
# Lookup task in state.json (8x faster than TODO.md parsing)
task_data=$(jq -r --arg num "$task_number" \
  '.active_projects[] | select(.project_number == ($num | tonumber))' \
  .claude/specs/state.json)

# Validate task exists
if [ -z "$task_data" ]; then
  echo "Error: Task $task_number not found"
  exit 1
fi

# Extract all metadata at once
language=$(echo "$task_data" | jq -r '.language // "general"')
status=$(echo "$task_data" | jq -r '.status')
project_name=$(echo "$task_data" | jq -r '.project_name')
description=$(echo "$task_data" | jq -r '.description // ""')
priority=$(echo "$task_data" | jq -r '.priority')
```

**Performance**: ~12ms for state.json lookup vs ~100ms for TODO.md parsing (8x faster)

### Why state.json for Reads?

- ✅ **Fast**: JSON parsing is 8x faster than markdown parsing
- ✅ **Structured**: Direct field access with jq (no grep/sed needed)
- ✅ **Reliable**: Structured data is more reliable than text parsing
- ✅ **Synchronized**: status-sync-manager keeps state.json and TODO.md in sync

### Command File Pattern

```bash
# Stage 1: ParseAndValidate
# 1. Parse task number from $ARGUMENTS
task_number=$(echo "$ARGUMENTS" | awk '{print $1}')

# 2. Validate state.json exists
if [ ! -f .claude/specs/state.json ]; then
  echo "Error: state.json not found. Run /meta to regenerate."
  exit 1
fi

# 3. Lookup task in state.json
task_data=$(jq -r --arg num "$task_number" \
  '.active_projects[] | select(.project_number == ($num | tonumber))' \
  .claude/specs/state.json)

if [ -z "$task_data" ]; then
  echo "Error: Task $task_number not found"
  exit 1
fi

# 4. Extract all metadata
language=$(echo "$task_data" | jq -r '.language // "general"')
status=$(echo "$task_data" | jq -r '.status')
project_name=$(echo "$task_data" | jq -r '.project_name')

# 5. Route to appropriate agent based on language
case "$language" in
  lean) target_agent="lean-implementation-agent" ;;
  *) target_agent="implementer" ;;
esac
```

**See**: `.claude/context/core/system/state-lookup.md` for comprehensive patterns and examples

---

## Status Synchronization

### Multi-File Synchronization

Commands that create or update plans must keep status synchronized across:
- `.claude/specs/TODO.md` (user-facing task list)
- `state.json` (global project state)
- Plan files (implementation plans)

### Atomic Update Requirement

All status updates must be **atomic** - either all files updated successfully, or none updated.

### status-sync-manager

The `status-sync-manager` specialist provides atomic multi-file updates using two-phase commit:

**Phase 1 (Prepare)**:
1. Read all target files into memory
2. Validate current status allows requested transition
3. Prepare all updates in memory
4. Validate all updates are well-formed
5. If any validation fails, abort (no files written)

**Phase 2 (Commit)**:
1. Write files in dependency order: TODO.md → state.json → plan
2. Verify each write before proceeding
3. On any write failure, rollback all previous writes
4. All files updated or none updated (atomic guarantee)

### Usage in Commands

**`/research` command**:
- Preflight: `status-sync-manager.mark_in_progress(task_number, timestamp)`
- Postflight: `status-sync-manager.mark_researched(task_number, timestamp)`

**`/plan` command**:
- Preflight: `status-sync-manager.mark_in_progress(task_number, timestamp)`
- Postflight: `status-sync-manager.mark_planned(task_number, timestamp, plan_path)`

**`/implement` command**:
- Preflight: `status-sync-manager.mark_in_progress(task_number, timestamp, plan_path)`
- Postflight: `status-sync-manager.mark_completed(task_number, timestamp, plan_path)`

### Rollback Mechanism

If any file write fails during commit:
1. Immediately stop further writes
2. Restore all previously written files from backup
3. Return error with details of which file failed
4. System remains in consistent state

---

## Validation

### Status Marker Validation

1. **Format**: Status markers must be in brackets: `[STATUS]`
2. **Case**: Status markers must be uppercase: `[COMPLETED]` not `[completed]`
3. **Spelling**: Must match exactly: `[COMPLETED]` not `[COMPLETE]`
4. **Whitespace**: No extra whitespace: `[IN PROGRESS]` not `[ IN PROGRESS ]`

### Timestamp Validation

1. **TODO.md**: Must be YYYY-MM-DD format
2. **Plans**: Must be ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)
3. **State files**: Must be YYYY-MM-DD for status changes, full ISO8601 for creation
4. **Required**: Timestamps required for all status transitions

### Transition Validation

1. **Valid transitions**: Must follow transition diagram
2. **Required fields**: Blocking/abandonment reasons required
3. **Timestamp order**: Started < Completed/Blocked/Abandoned
4. **Immutability**: `[COMPLETED]` tasks should not change

### JSON Syntax Validation

```bash
# Validate JSON syntax
jq empty .claude/specs/state.json
jq empty .claude/specs/archive/state.json
jq empty .claude/specs/maintenance/state.json
```

---

## Schema Versioning

All state files include:
```json
"_schema_version": "1.1.0"
```

### Version Format
**Format**: `"MAJOR.MINOR.PATCH"` (Semantic Versioning)
- **MAJOR**: Breaking changes requiring migration
- **MINOR**: New optional fields (backward compatible)
- **PATCH**: Documentation or clarification only

---

## Best Practices

### 1. Always Include Timestamps

**Good**:
```markdown
**Status**: [IN PROGRESS]
**Started**: 2025-12-20
```

**Bad**:
```markdown
**Status**: [IN PROGRESS]
```

### 2. Always Include Blocking/Abandonment Reasons

**Good**:
```markdown
**Status**: [BLOCKED]
**Blocked**: 2025-12-20
**Blocking Reason**: Blocked by failed task 64
```

**Bad**:
```markdown
**Status**: [BLOCKED]
```

### 3. Use Atomic Updates

**Good**:
```python
status_sync_manager.mark_complete(
    task_number=63,
    timestamp="2025-12-20"
)
```

**Bad** (non-atomic):
```python
update_todo(63, "COMPLETED")
update_state(63, "completed")  # May fail, leaving inconsistent state
```

### 4. Preserve Status History

When updating status, preserve previous timestamps:

**Good**:
```markdown
**Status**: [COMPLETED]
**Started**: 2025-12-19
**Completed**: 2025-12-20
```

**Bad** (overwrites history):
```markdown
**Status**: [COMPLETED]
**Completed**: 2025-12-20
```

---

## Related Documentation

- Delegation Standard: `.claude/context/core/standards/delegation.md`
- Artifact Management: `.claude/context/core/system/artifact-management.md`
- Git Commits: `.claude/context/core/system/git-commits.md`
# Project Structure Guide

## Overview
Organization of .claude/specs/ directory for project-based artifact management. All artifacts must comply with lazy directory creation and the no-emojis standard.

## Directory Structure

```
.claude/specs/
├── .claude/specs/TODO.md                          # User-facing master task list
├── state.json                       # Global state file
├── archive/
│   ├── state.json                   # Archive state tracking
│   └── NNN_project_name/            # Archived project directories
│       ├── reports/
│       ├── plans/
│       ├── summaries/
│       └── state.json
├── maintenance/
│   ├── state.json                   # Maintenance operations tracking
│   └── report-YYYYMMDD.md           # Maintenance reports
└── NNN_project_name/                # Active project directories
    ├── reports/
    │   ├── research-001.md
    │   ├── analysis-001.md
    │   └── verification-001.md
    ├── plans/
    │   ├── implementation-001.md
    │   └── implementation-002.md    # Revised plan
    ├── summaries/
    │   ├── project-summary.md
    │   └── research-summary.md
    └── state.json                   # Project-specific state
```

## Project Numbering

### Format
- **NNN_project_name** where NNN is zero-padded 3-digit number
- Examples: 001_bimodal_proof_system, 002_semantics_layer, 003_metalogic

### Numbering Rules
1. Start at 000
2. Increment sequentially up to 999
3. Wrap around to 000 after 999 (ensure old project is archived)
4. Zero-pad to 3 digits

## Subdirectories

### reports/
Contains all research and analysis reports:
- **research-NNN.md**: Research findings from researcher agent
- **analysis-NNN.md**: Repository analysis from reviewer agent
- **verification-NNN.md**: Verification reports from reviewer agent
- **refactoring-NNN.md**: Refactoring reports from refactorer agent

**Report Editing Policy**: Research reports should NOT be edited after creation. Report modification times (mtime) are used by the planner to detect new reports created since the last plan version. If a report needs updates, create a new report version (research-002.md) instead of editing the original.

### plans/
Contains implementation plans with version control:
- **implementation-001.md**: Initial plan
- **implementation-002.md**: First revision
- **implementation-NNN.md**: Subsequent revisions

Version increments when:
- Plan needs significant changes
- User runs /revise command
- Implementation approach changes

**Research reuse for plans:**
- `/plan {task_number}` must harvest research links already attached to the TODO entry and pass them to the planner.
- Generated plans must include a clearly labeled **Research Inputs** section citing each linked research artifact (or explicitly stating none linked when absent).
- If linked research files are missing/dangling, surface a warning and continue; do not create extra directories while resolving links.

**Command contract boundaries:**
- `/plan` may create the project directory and initial `plans/implementation-001.md` if missing. Creation is lazy: create the project root and `plans/` only when emitting the plan; do **not** pre-create `reports/` or `summaries/`.
- `/revise` reuses the existing project directory and plan link from .claude/specs/TODO.md; it increments the plan version in the same `plans/` folder and must **not** create new project directories or change numbering.
- If no plan link exists in .claude/specs/TODO.md, `/revise` must fail gracefully and instruct the user to run `/plan` first.
- `/implement` reuses the plan path attached in .claude/specs/TODO.md when present and updates that plan in place while executing. When no plan link exists on the TODO entry, `/implement` executes the task directly (no failure) while adhering to lazy directory creation (no project roots/subdirs unless an artifact is written) and keeping numbering/state sync intact. When /implement execution writes implementation artifacts, it must also emit an implementation summary in `summaries/implementation-summary-YYYYMMDD.md`; status-only paths do not emit summaries.
- `/implement`, `/task`, `/review`, and `/todo` must update IMPLEMENTATION_STATUS.md, SORRY_REGISTRY.md, and TACTIC_REGISTRY.md together when their operations change task/plan/implementation status or sorry/tactic counts.
- `/research` and researcher agents: create the project root immediately before writing the first research artifact, and create only `reports/` (no `plans/` or `summaries/`) when emitting that artifact; do **not** pre-create other subdirs or placeholders.

- `/review` and reviewer agents: create the review project root only when writing the first report/summary, and only create the subdir needed for the artifact being written; never pre-create both `reports/` and `summaries/` up front.

### summaries/
Contains brief summaries for quick reference. **All detailed artifacts MUST have corresponding summary artifacts** to protect the orchestrator's context window.

**Summary Requirements** (enforced by validation):
- **Format**: 3-5 sentences for research/plan/implementation summaries, 2-3 sentences for batch summaries
- **Token Limit**: <100 tokens for individual summaries, <75 tokens for batch summaries
- **Creation**: Lazy directory creation - create `summaries/` only when writing first summary
- **Validation**: Summary artifact must exist before task completion when detailed artifact created

**Summary Types**:
- **research-summary.md**: Key research findings (3-5 sentences, <100 tokens)
  - Example: "Research identified 7 complexity indicators for task routing. Token counting methodology uses chars ÷ 3 estimation. Progressive summarization reduces batch returns by 95%. Validation layer enforces format compliance. Recommended clean-break approach for deployment."
  
- **plan-summary.md**: Implementation plan overview (3-5 sentences, <100 tokens)
  - Example: "8-phase implementation plan with clean-break approach. Phase 0 audits all consumers. Phases 1-6 implement return formats, summaries, complexity routing, and validation. Phase 7 tests integration. Phase 8 updates documentation."
  
- **implementation-summary-YYYYMMDD.md**: What was implemented (3-5 sentences, <100 tokens)
  - Example: "Implemented artifact-first return format for task-executor with <500 token limit. Added summary artifact enforcement for all detailed artifacts. Created complexity router with 7-factor scoring. Differentiated git commit patterns for simple vs complex tasks."
  
- **batch-summary-YYYYMMDD.md**: Batch execution summary (2-3 sentences, <75 tokens)
  - Example: "Successfully completed 10 tasks across 3 execution waves. 5 simple tasks executed directly, 5 complex tasks followed full workflow. All validation checks passed."
  
- **project-summary.md**: Overall project summary (3-5 sentences, <100 tokens)
  - Example: "Task 169 implements context window protection for /implement command. Reduces return formats by 95% through artifact-first approach. Enforces summary artifacts for all detailed work. Adds complexity-based routing and validation layer."

## Template Standards
- Plans must follow `.claude/context/core/standards/plan.md`.
- Reports must follow `.claude/context/core/standards/report.md`.
- Summaries must follow `.claude/context/core/standards/summary.md`.
- Status markers must align with `.claude/context/core/standards/status-markers.md`.
- Commands and agents should load these standards in their context when producing corresponding artifacts.

## .claude/specs/TODO.md Format

```markdown
# TODO - LEAN 4 ProofChecker

## High Priority

- [ ] Implement soundness proof for bimodal logic [Project #001](001_bimodal_proof_system/plans/implementation-002.md)
- [ ] Complete Kripke model definition [Project #002](002_semantics_layer/plans/implementation-001.md)

## Medium Priority

- [ ] Refactor proof system axioms for readability [Project #001](001_bimodal_proof_system/reports/verification-001.md)
- [ ] Add documentation for modal operators

## Low Priority

- [ ] Explore alternative proof strategies
- [ ] Research decidability procedures

## Completed

- [x] Research bimodal logic foundations [Project #001](001_bimodal_proof_system/reports/research-001.md)
- [x] Create initial implementation plan [Project #001](001_bimodal_proof_system/plans/implementation-001.md)
```

## Artifact Naming Conventions

### Reports
- **research-NNN.md**: Incremental numbering within project
- **analysis-NNN.md**: Incremental numbering within project
- **verification-NNN.md**: Incremental numbering within project

### Plans
- **implementation-NNN.md**: Version number (increments with revisions)

### Summaries
- **{type}-summary.md**: One per type (project, research, plan, implementation)

## Best Practices
1. **Lazy directory creation (roots + subdirs)**: Create the project root **only when writing the first artifact**. Create subdirectories (`reports/`, `plans/`, `summaries/`) **only at the moment you write an artifact into them**. Never pre-create unused subdirs and never add placeholder files (e.g., `.gitkeep`).
2. **Project directory timing and state writes**: `/task` MUST NOT create project directories. `/plan`, `/research`, `/review`, `/implement`, and subagents may create the project root immediately before writing their first artifact, then lazily create only the needed subdir for that artifact. Do not write project `state.json` until an artifact is produced; state updates should accompany artifact creation.
3. **No emojis**: Commands, agents, and artifacts must not include emojis. Use textual markers and status markers for progress instead.
4. **Use descriptive project names** that reflect the task.
5. **Increment versions properly** when revising plans.
6. **Keep summaries brief** (1-2 pages max).
7. **Link TODO items** to relevant reports/plans.
8. **Update state files** after every operation.
9. **Sync .claude/specs/TODO.md** with project progress.
10. **Lean routing**: Use the TODO task `Language` field as the primary Lean intent signal (explicit `--lang` flag overrides; plan `lean:` is secondary). For Lean tasks, route `/implement` to the Lean research subagent when research is requested and the Lean implementation subagent when implementation is requested; validate required MCP servers from `.mcp.json` (at minimum `lean-lsp` via `uvx lean-lsp-mcp`) before creating project roots. If validation fails, return remediation steps and avoid filesystem changes.

## Context Window Protection via Metadata Passing

### Core Pattern

**Subagents return artifact links + brief summaries (metadata) to calling agents, NOT full artifact content.** This protects the orchestrator's context window from bloat while maintaining traceability.

### How It Works

1. **Subagent creates artifact** (research report, implementation plan, code files, etc.)
2. **Subagent validates artifact** (exists, non-empty, within token limits)
3. **Subagent returns to caller**:
   - `artifacts` array: List of artifact objects with `type`, `path`, `summary` fields
   - `summary` field: Brief metadata summary (<100 tokens, ~400 characters)
   - Full artifact content stays in files, NOT in return object

### Artifact Patterns by Command

Different commands create different artifact patterns based on output complexity:

#### /research: 1 Artifact (Report Only)
- **Artifacts Created**: 1 file (research report)
- **Summary Artifact**: NO - Report is single file, self-contained
- **Return Pattern**: Artifact link + brief summary as metadata in return object
- **Rationale**: Single-file output doesn't need separate summary artifact

#### /plan: 1 Artifact (Plan Only, Self-Documenting)
- **Artifacts Created**: 1 file (implementation plan)
- **Summary Artifact**: NO - Plan is self-documenting with metadata section
- **Return Pattern**: Artifact link + brief summary as metadata in return object
- **Rationale**: Plan contains phase breakdown, estimates, and overview - no separate summary needed

#### /revise: 1 Artifact (Revised Plan, Self-Documenting)
- **Artifacts Created**: 1 file (revised implementation plan)
- **Summary Artifact**: NO - Revised plan is self-documenting
- **Return Pattern**: Artifact link + brief summary as metadata in return object
- **Rationale**: Same as /plan - revised plan is self-documenting

#### /implement: N+1 Artifacts (Files + Summary)
- **Artifacts Created**: N implementation files + 1 summary artifact
- **Summary Artifact**: YES - Required for multi-file outputs
- **Return Pattern**: Artifact links (files + summary) + brief summary as metadata in return object
- **Rationale**: Multiple implementation files need summary artifact for overview; protects context window from reading N files

### Summary Artifacts vs Summary Metadata

**Summary Artifact** (file on disk):
- Created for multi-file outputs (e.g., /implement creates N files)
- Provides detailed overview of all changes across multiple files
- Path: `summaries/implementation-summary-YYYYMMDD.md`
- Token limit: <100 tokens (~400 characters)
- Purpose: Single-file overview of multi-file changes

**Summary Metadata** (field in return object):
- Returned by ALL subagents in `summary` field of return object
- Brief description of work done (3-5 sentences, <100 tokens)
- Purpose: Protect orchestrator context window from full artifact content
- NOT a separate file - just metadata in return object

### When to Create Summary Artifacts

**Create summary artifact when**:
- Command creates multiple implementation files (e.g., /implement)
- Output spans multiple files that need unified overview
- Reading all files would bloat orchestrator context window

**Do NOT create summary artifact when**:
- Command creates single file (e.g., /research report, /plan)
- Single file is self-documenting (e.g., plan with metadata section)
- File already contains overview/summary section

### Validation Requirements

All subagents MUST validate artifacts before returning:
1. Verify artifact files exist on disk
2. Verify artifact files are non-empty (size > 0)
3. Verify summary artifacts within token limit (<100 tokens, ~400 chars)
4. Return `validated_artifacts` in return object metadata
5. If validation fails: Return status "failed" with error details

### Integration with subagent-return-format.md

This pattern is enforced by `subagent-return-format.md`:
- `summary` field: Brief metadata (<100 tokens)
- `artifacts` array: List of artifact objects (NOT full content)
- Orchestrator reads `summary` field, NOT artifact files
- Artifact files available for user review, not loaded into context

### References

- **Authoritative Standard**: `.claude/context/core/standards/subagent-return-format.md`
- **Command Lifecycle**: `.claude/context/core/workflows/command-lifecycle.md` (Stages 5-6)
- **Summary Standard**: `.claude/context/core/standards/summary.md`

## Context Protection (Legacy)

All agents create artifacts in these directories and return only:
- File path (reference)
- Brief summary (3-5 sentences)
- Key findings (bullet points)

This protects the orchestrator's context window from artifact content bloat.

## Related Documentation

See `.claude/context/index.md` for navigation to all context files.
