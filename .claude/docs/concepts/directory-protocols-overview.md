# Directory Protocols - Overview

Comprehensive guide for the topic-based artifact organization system used in specs/ directories.

## Navigation

This document is part of a multi-part guide:
- **Overview** (this file) - Introduction, directory structure, and topic organization
- [Structure](directory-protocols-structure.md) - Artifact taxonomy, gitignore compliance, and lifecycle
- [Examples](directory-protocols-examples.md) - Shell utilities, usage patterns, troubleshooting, and best practices

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

**Structure**: `specs/{NNN_topic}/{artifact_type}/NNN_artifact_name.md`

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

Topic directories use semantic slug generation to create meaningful, readable names.

**Semantic Slug Generation** (Spec 771):

Commands generate topic slugs in different ways based on available context:

1. **With LLM Classification** (coordinate command):
   - Uses `topic_directory_slug` from workflow-classifier agent
   - Three-tier fallback: LLM slug -> extract significant words -> sanitize
   - Format: `^[a-z0-9_]{1,40}$` (max 40 chars for readability)

2. **Without LLM Classification** (plan, research commands):
   - Uses `sanitize_topic_name()` for semantic word extraction
   - Filters stopwords and preserves meaningful terms
   - Format: `^[a-z0-9_]{1,50}$` (max 50 chars)

**Examples**:
| Description | Generated Slug |
|-------------|----------------|
| "Research the authentication patterns and create plan" | `auth_patterns_implementation` |
| "Fix JWT token expiration bug causing login failures" | `jwt_token_expiration_bug` |
| "Research the /home/user/.config/.claude/ directory" | `claude_directory` |

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

## Related Documentation

- [Structure](directory-protocols-structure.md) - Artifact taxonomy, gitignore compliance, and lifecycle
- [Examples](directory-protocols-examples.md) - Shell utilities, usage patterns, troubleshooting, and best practices
- **CLAUDE.md**: Directory protocols section (specs structure summary)
- **spec_updater_guide.md**: Spec updater agent usage and patterns
- **command_architecture_standards.md**: Context preservation standards (Standards 6-8)
- **phase_dependencies.md**: Wave-based execution and dependency syntax
- **.claude/lib/workflow/metadata-extraction.sh**: Shell utility implementations
