# Directory Protocols

## Specifications Structure (`specs/`)

[Used by: /report, /plan, /implement, /list-plans, /list-reports, /list-summaries]

The specifications directory uses a uniform topic-based structure where all artifacts for a feature are organized together:

**Structure**: `specs/{NNN_topic}/{artifact_type}/NNN_artifact_name.md`

**Topic Directories** (`{NNN_topic}`):
- Three-digit numbered directories (001, 002, 003...)
- Each topic contains all artifacts for a feature or area
- Topic name describes the feature (e.g., `042_authentication`, `001_cleanup`)

**Artifact Types** (subdirectories within each topic):
- `plans/` - Implementation plans
- `reports/` - Research reports
- `summaries/` - Implementation summaries
- `debug/` - Debug reports (COMMITTED to git for issue tracking)
- `scripts/` - Investigation scripts (temporary)
- `outputs/` - Test outputs (temporary)
- `artifacts/` - Operation artifacts (optional cleanup)
- `backups/` - Backups (optional cleanup)

**Artifact Numbering**:
- Each artifact type uses three-digit numbering within the topic (001, 002, 003...)
- Numbering resets per topic directory
- Example: `specs/042_auth/plans/001_user_auth.md`, `specs/042_auth/plans/002_session.md`

**Metadata-Only References**:

Artifacts should be referenced by **path + metadata**, not full content, to minimize context usage (see [Command Architecture Standards - Standards 6-8](command_architecture_standards.md#context-preservation-standards)).

**Metadata Extraction Utilities** (`.claude/lib/artifact-operations.sh`):
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

**Location**: specs/ directories can exist at project root or in subdirectories (e.g., `.claude/specs/`) for scoped specifications.

**Important**: Most specs/ artifacts are gitignored (plans/, reports/, summaries/, scripts/, outputs/, artifacts/, backups/). Debug reports in `debug/` subdirectories are COMMITTED to git for issue tracking.

## Directory Structure Example

```
{project}/
├── specs/
│   ├── 001_cleanup/
│   │   ├── plans/
│   │   │   ├── 001_refactor_utilities.md
│   │   │   └── 002_fix_artifact_bugs.md
│   │   ├── reports/
│   │   │   └── 001_cleanup_analysis.md
│   │   ├── summaries/
│   │   │   └── 002_implementation_summary.md
│   │   └── debug/
│   │       └── 001_path_resolution.md
│   └── 042_authentication/
│       ├── plans/
│       │   ├── 001_user_authentication.md
│       │   └── 002_session_management.md
│       ├── reports/
│       │   ├── 001_auth_patterns.md
│       │   ├── 002_security_practices.md
│       │   └── 003_alternatives.md
│       ├── summaries/
│       │   └── 001_implementation_summary.md
│       ├── debug/
│       │   └── 001_token_refresh.md
│       ├── scripts/
│       ├── outputs/
│       ├── artifacts/
│       └── backups/
└── .claude/
    └── specs/
        └── 001_config/
            ├── plans/
            ├── reports/
            └── summaries/
```

**Uniform Structure Benefits**:
- All artifacts for a feature in one directory
- Easy to find related plans, reports, summaries, debug reports
- Consistent numbering within each artifact type
- Clear separation between committed (debug/) and gitignored artifacts
- Supports both project-root (`specs/`) and scoped (`.claude/specs/`) locations

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

See `.claude/docs/phase_dependencies.md` for detailed dependency syntax and examples.
