---
command-type: primary
dependent-commands: list, expand
description: Revise the most recently discussed plan with user-provided changes (supports interactive and automated modes)
argument-hint: <revision-details> [--auto-mode] [--context <json>] [report-path1] [report-path2] ...
allowed-tools: Read, Write, Edit, Glob, Grep, Task, MultiEdit, TodoWrite, SlashCommand
---

# /revise Command

Revises the most recently discussed implementation plan or research report according to user-provided details, optionally incorporating insights from research reports. **This command only modifies the artifact file - it does not implement any changes or execute code.**

## Usage

### Syntax Options

**Option 1: Revision-first (original)**
```bash
/revise <revision-details> [context-path1] [context-path2] ...
```

**Option 2: Path-first (explicit artifact targeting)**
```bash
/revise <artifact-path> <revision-details> [context-path1] ...
```

**Option 3: Auto-mode (for /implement integration)**
```bash
/revise <plan-path> --auto-mode --context '<json-context>'
```

### Arguments

**Interactive Mode**:
- `<revision-details>` (required): Description of changes to make
- `<artifact-path>` (optional): Explicit path to plan or report (inferred from conversation if omitted)
- `[context-path1] [context-path2] ...` (optional): Research reports to guide revision

**Automated Mode**:
- `<plan-path>` (required): Path to plan file to revise
- `--auto-mode` (required): Enable automated revision mode
- `--context '<json>'` (required): Structured JSON context with revision details

### Artifact Types Supported

- **Plans**: Implementation plans (all structure levels: L0/L1/L2)
- **Reports**: Research reports (single-file)

## Examples

### Plan Revisions

#### Add Phase to Plan
```bash
# Revision-first syntax
/revise "Add Phase 6 for deployment and monitoring"

# Path-first syntax
/revise specs/plans/025_feature.md "Add Phase 6 for deployment and monitoring"
```

#### Modify Phase Tasks
```bash
# With research context
/revise "Update Phase 3 tasks based on performance findings" specs/reports/018_performance.md

# Path-first with context
/revise specs/plans/025_feature/ "Update Phase 3 tasks" specs/reports/018_performance.md
```

#### Update Plan Metadata
```bash
# Simple metadata update
/revise "Update complexity to High and add security risk assessment"

# Explicit path
/revise specs/plans/025_feature.md "Update complexity to High"
```

### Report Revisions

#### Update Report Findings
```bash
# Basic report revision
/revise "Update findings based on implementation results" specs/reports/010_analysis.md

# With additional research context
/revise specs/reports/010_analysis.md "Incorporate new security patterns" specs/reports/015_security.md
```

#### Section-Specific Update
```bash
# Target specific section
/revise "Update Authentication section with OAuth implementation learnings" specs/reports/010_security.md

# Multiple sections
/revise "Revise Recommendations and Future Work sections based on completed implementation" specs/reports/010_analysis.md
```

#### Add New Findings
```bash
# Add to existing report
/revise "Add performance benchmark results to Performance section" specs/reports/012_optimization.md
```

#### Example Output with Structure Recommendations
```
✓ Revised plan: specs/plans/025_feature_plan.md
  - Updated Phase 3 tasks based on complexity analysis
  - Added error handling requirements
  - Updated testing approach

**Structure Recommendations**:

*Collapse Opportunities (simple expanded phases):*
- Phase 2: Basic Configuration (4 tasks, complexity 3.5)
  - Command: `/collapse phase specs/plans/025_feature_plan 2`

*Expansion Opportunities (complex inline phases):*
- Phase 5: Database Migration and API Updates (12 tasks, complexity 9.2)
  - Command: `/expand phase specs/plans/025_feature_plan 5`
```

### Automated Mode

#### Triggered by /implement (Complexity Trigger)
```
/revise specs/plans/025_plan.md --auto-mode --context '{
  "revision_type": "expand_phase",
  "current_phase": 3,
  "reason": "Phase complexity score exceeds threshold (9.2 > 8)",
  "suggested_action": "Expand phase 3 into separate file",
  "complexity_metrics": {"tasks": 12, "score": 9.2}
}'
```

#### Triggered by /implement (Test Failure Pattern)
```
/revise specs/plans/025_plan.md --auto-mode --context '{
  "revision_type": "add_phase",
  "current_phase": 2,
  "reason": "Two consecutive test failures in authentication module",
  "suggested_action": "Add prerequisite phase for dependency setup",
  "test_failure_log": "Error: Module not found: crypto-utils..."
}'
```

## Operation Modes

### Interactive Mode (Default)

**Purpose**: User-driven plan revisions with full context and explanation

**Behavior**:
- User provides natural language revision description
- Command infers which plan to revise from conversation context
- Presents changes and asks for confirmation
- Creates detailed revision history with rationale
- Suitable for major strategic changes

**Use When**:
- Changing project scope or requirements
- Incorporating new research findings
- Restructuring phases based on lessons learned
- User wants visibility and control over changes

### Automated Mode (`--auto-mode`)

**Purpose**: Programmatic plan revision triggered by `/implement` during execution

**Behavior**:
- Accepts structured JSON context with specific revision parameters
- Executes deterministic revision logic based on `revision_type`
- Returns machine-readable success/failure status
- Creates concise revision history for audit trail
- Designed for /implement integration (no user interaction)

**Use When**:
- `/implement` detects complexity threshold exceeded
- Multiple test failures indicate missing prerequisites
- Scope drift detected (missing phases discovered)
- Automated expansion of phases is needed

**Not Suitable For**:
- Strategic plan changes requiring human judgment
- Incorporating new requirements from stakeholders
- Major scope changes or pivots

## Important Notes

### What This Command Does
- **Modifies plans or reports** with your requested changes
- **Preserves completion status** of already-executed phases (plans only)
- **Adds revision history** to track changes
- **Creates a backup** of the original artifact
- **Updates phase details** (plans) or findings/recommendations (reports)
- **Evaluates structure optimization** opportunities after revision (plans only)
- **Displays recommendations** for collapsing simple phases or expanding complex phases (plans only)
- **Section targeting** for reports (focuses on specific sections when requested)
- **Auto-mode**: Returns structured success/failure response for /implement (plans only)

### What This Command Does NOT Do
- **Does NOT execute any code changes**
- **Does NOT run tests**
- **Does NOT create commits**
- **Does NOT implement the plan**
- **Auto-mode does NOT ask for user confirmation** (deterministic logic only)

To implement the revised plan after revision, use `/implement [plan-file]`

## Mode Comparison

| Aspect | Interactive Mode | Auto-Mode |
|--------|------------------|-----------|
| **Trigger** | User explicitly calls `/revise` | `/implement` detects trigger condition |
| **Input** | Natural language description | Structured JSON context |
| **Confirmation** | Presents changes, asks confirmation (optional) | No confirmation, deterministic execution |
| **Use Case** | User-driven plan/report changes | Automated plan adjustments during implementation |
| **Revision Types** | Any content change | Specific types: expand_phase, add_phase, split_phase, update_tasks, collapse_phase |
| **History Format** | Detailed rationale and context | Concise audit trail with trigger info |
| **Artifact Support** | Plans and reports | Plans only |
| **Context** | Research reports (optional) | JSON context with metrics |

### When to Use Each Mode

**Use Interactive Mode When**:
- Incorporating new requirements from stakeholders
- Revising based on research findings
- Making strategic plan changes
- Updating reports with new findings
- You want visibility and control over changes

**Use Auto-Mode When**:
- `/implement` detects complexity threshold exceeded
- Multiple test failures indicate missing prerequisites
- Automated structure optimization needed
- You're building automated workflows

**Auto-Mode is NOT Suitable For**:
- Strategic plan changes requiring human judgment
- Major scope changes or pivots
- Report modifications
- Initial plan creation

## Progressive Plan Support

This command revises all three progressive structure levels:
- **Level 0**: Revise single `.md` file
- **Level 1**: Revise main plan and/or expanded phase files
- **Level 2**: Revise main plan, phase files, and/or stage files

The command determines which file(s) to revise based on the scope of changes and expansion status.

## Artifact Type Detection

This command works with both implementation plans and research reports.

### Plan Detection
- Check if path matches `*/specs/plans/*.md` or `*/specs/plans/*/`
- Detect structure level using `parse-adaptive-plan.sh detect_structure_level`
- Apply plan revision logic

### Report Detection
- Check if path matches `*/specs/reports/*.md`
- Extract report metadata using `get_report_metadata()` from artifact-utils.sh
- Apply report revision logic

### Auto-Detection
If path not provided explicitly:
- Search conversation history for plan/report mentions
- Prioritize most recently discussed artifact
- Fall back to most recently modified artifact in specs/

## Report Revision Process

### 1. Report Analysis
Read the existing report to understand:
- Original research questions and scope
- Current findings and recommendations
- Report structure and sections
- Last update date

### 2. Revision Assessment
Determine what needs updating:
- New findings to incorporate
- Sections to revise or expand
- Recommendations to update based on implementation
- Outdated information to remove or revise

### 3. Research Integration
If research reports provided as context:
- Cross-reference findings
- Identify complementary insights
- Update recommendations based on new data

### 4. Report Updates
Apply changes using Edit tool:
- Update specific sections (if targeted)
- Add new findings with current date
- Revise recommendations
- Update metadata (last modified date)
- Preserve original research context

### 5. Version Tracking (Reports)
Add revision entry:
```markdown
## Revision History

### [YYYY-MM-DD] - Revision N
**Changes**: Description of what was revised
**Reason**: Why the revision was needed
**Sections Updated**: List of modified sections
**Related Plans**: Link to implementation plans if applicable
```

### Section-Specific Revision

When revising reports, you can target specific sections:

#### Section Detection from Revision Details
Parse revision details for section keywords:
- "Update <Section Name> section..."
- "Revise findings in <Section Name>..."
- "Add to <Section Name>:"

#### Section Extraction
Use grep to locate section in report:
```bash
# Find section start
section_start=$(grep -n "^## $SECTION_NAME" "$report_path" | cut -d: -f1)

# Find next section (or EOF)
section_end=$(tail -n +$((section_start + 1)) "$report_path" | grep -n "^## " | head -1 | cut -d: -f1)

# Extract section content for context
section_content=$(sed -n "${section_start},${section_end}p" "$report_path")
```

#### Targeted Updates
When section identified:
1. Read only that section for context (efficiency)
2. Apply changes to section specifically
3. Preserve rest of report unchanged
4. Update metadata (section modified date)

## Automated Mode Specification

### Context JSON Structure

When invoked with `--auto-mode`, the command expects a `--context` parameter with JSON in this format:

```json
{
  "revision_type": "<type>",
  "current_phase": <number>,
  "reason": "<explanation>",
  "suggested_action": "<action description>",
  "<additional_context>": <context-specific data>
}
```

### Revision Types

#### 1. `expand_phase` - Expand Complex Phase

**Trigger**: Phase complexity score exceeds threshold (score > 8 or tasks > 10)

**Context Fields**:
```json
{
  "revision_type": "expand_phase",
  "current_phase": 3,
  "reason": "Phase complexity score exceeds threshold (9.2 > 8)",
  "suggested_action": "Expand phase 3 into separate file",
  "complexity_metrics": {
    "tasks": 12,
    "score": 9.2,
    "estimated_duration": "4-5 sessions"
  }
}
```

**Automated Actions**:
1. Invoke `/expand phase <plan> <phase-number>`
2. Update plan structure level metadata (0 → 1)
3. Add revision history entry
4. Return updated plan path

**Response Format**:
```json
{
  "status": "success",
  "action_taken": "expanded_phase",
  "phase_expanded": 3,
  "new_structure_level": 1,
  "updated_files": [
    "specs/plans/025_plan/025_plan.md",
    "specs/plans/025_plan/phase_3_implementation.md"
  ]
}
```

#### 2. `add_phase` - Insert Missing Phase

**Trigger**: Multiple test failures indicate missing prerequisites or scope drift

**Context Fields**:
```json
{
  "revision_type": "add_phase",
  "current_phase": 2,
  "reason": "Two consecutive test failures in authentication module",
  "suggested_action": "Add prerequisite phase for dependency setup",
  "test_failure_log": "Error: Module not found: crypto-utils\nError: Database not initialized",
  "insert_position": "before",
  "new_phase_name": "Setup Dependencies"
}
```

**Automated Actions**:
1. Insert new phase at specified position (before/after current phase)
2. Renumber subsequent phases
3. Populate new phase with basic structure:
   - Objective (derived from reason)
   - Tasks (derived from failure analysis)
   - Dependencies
4. Update phase count in metadata
5. Add revision history entry

**Response Format**:
```json
{
  "status": "success",
  "action_taken": "added_phase",
  "new_phase_number": 2,
  "new_phase_name": "Setup Dependencies",
  "phases_renumbered": true,
  "total_phases": 6
}
```

#### 3. `split_phase` - Split Overly Broad Phase

**Trigger**: Phase proves to cover multiple distinct concerns during implementation

**Context Fields**:
```json
{
  "revision_type": "split_phase",
  "current_phase": 4,
  "reason": "Phase 4 combines frontend and backend work - too broad",
  "suggested_action": "Split into frontend (Phase 4) and backend (Phase 5)",
  "split_criteria": {
    "part1_name": "Frontend Implementation",
    "part1_tasks": [1, 2, 3, 4],
    "part2_name": "Backend Implementation",
    "part2_tasks": [5, 6, 7, 8, 9]
  }
}
```

**Automated Actions**:
1. Create new phase after current phase
2. Move specified tasks to new phase
3. Update both phases' objectives
4. Renumber subsequent phases
5. Update dependencies
6. Add revision history

**Response Format**:
```json
{
  "status": "success",
  "action_taken": "split_phase",
  "original_phase": 4,
  "new_phases": [4, 5],
  "phases_renumbered": true,
  "total_phases": 7
}
```

#### 4. `update_tasks` - Modify Phase Tasks

**Trigger**: Implementation reveals tasks need adjustment (add, remove, reorder)

**Context Fields**:
```json
{
  "revision_type": "update_tasks",
  "current_phase": 3,
  "reason": "Migration script required before data model changes",
  "suggested_action": "Add migration task before schema changes",
  "task_operations": [
    {"action": "insert", "position": 2, "task": "Create database migration script"},
    {"action": "remove", "position": 5},
    {"action": "update", "position": 3, "task": "Update schema with foreign keys"}
  ]
}
```

**Automated Actions**:
1. Apply task operations in order
2. Preserve completion markers for existing tasks
3. Update acceptance criteria if needed
4. Add revision history

**Response Format**:
```json
{
  "status": "success",
  "action_taken": "updated_tasks",
  "phase": 3,
  "tasks_added": 1,
  "tasks_removed": 1,
  "tasks_updated": 1
}
```

#### 5. `collapse_phase` - Collapse Simple Expanded Phase

**Trigger**: Phase completed and now simple (tasks ≤ 5, complexity < 6.0)

**Context Fields**:
```json
{
  "revision_type": "collapse_phase",
  "current_phase": 3,
  "reason": "Phase 3 completed and now simple (4 tasks, complexity 3.5)",
  "suggested_action": "Collapse Phase 3 back into main plan",
  "simplicity_metrics": {
    "tasks": 4,
    "complexity_score": 3.5,
    "completion": true
  }
}
```

**Automated Actions**:
1. Validate phase is expanded (not inline)
2. Validate phase has no expanded stages
3. Invoke `/collapse phase <plan> <phase-number>`
4. Update structure level metadata
5. Add revision history entry
6. Return updated plan path

**Response Format**:
```json
{
  "status": "success",
  "action_taken": "collapsed_phase",
  "phase_collapsed": 3,
  "reason": "Phase 3 completed and now simple (4 tasks, complexity 3.5)",
  "new_structure_level": 1,
  "updated_file": "specs/plans/025_plan/025_plan.md"
}
```

**Error Cases**:
- Phase not expanded: Return error with `error_type: "invalid_state"`
- Phase has expanded stages: Return error with message "collapse stages first"
- Collapse operation fails: Return error with collapse command output

### Decision Logic

```
Auto-Mode Invocation
     ↓
Parse --context JSON
     ↓
Validate required fields
  ├─ Missing fields → Return error
  └─ Valid → Continue
     ↓
Switch on revision_type:
  ├─ "expand_phase" → Invoke /expand phase
  ├─ "add_phase" → Insert new phase
  ├─ "split_phase" → Split existing phase
  ├─ "update_tasks" → Modify task list
  ├─ "collapse_phase" → Invoke /collapse phase (validate first)
  └─ Unknown type → Return error
     ↓
Create backup of original plan
     ↓
Execute automated revision logic
  ├─ Success → Add revision history, return success response
  └─ Failure → Restore backup, return error response
     ↓
Return JSON response to /implement
```

### Response Format

**Success Response**:
```json
{
  "status": "success",
  "action_taken": "<revision_type>",
  "plan_file": "<updated plan path>",
  "backup_file": "<backup path>",
  "revision_summary": "<brief description>",
  "structure_recommendations": {
    "collapse_opportunities": [
      {
        "phase": 2,
        "phase_name": "Simple Phase",
        "tasks": 4,
        "complexity": 3.5,
        "command": "/collapse phase <plan-path> 2"
      }
    ],
    "expansion_opportunities": [
      {
        "phase": 5,
        "phase_name": "Complex Phase",
        "tasks": 12,
        "complexity": 9.2,
        "command": "/expand phase <plan-path> 5"
      }
    ]
  },
  "<context-specific-fields>": "<values>"
}
```

**Error Response**:
```json
{
  "status": "error",
  "error_type": "<error classification>",
  "error_message": "<detailed error>",
  "plan_file": "<original plan path>",
  "backup_restored": true/false
}
```

### Integration with /implement

**When /implement Detects Trigger**:

```
/implement Phase 3
     ↓
Execute tasks
     ↓
Detect complexity > threshold
     ↓
Build revision context JSON
     ↓
Invoke: /revise <plan> --auto-mode --context '<json>'
     ↓
Parse JSON response
  ├─ status=="success" → Continue with updated plan
  └─ status=="error" → Log error, ask user for guidance
```

**Loop Prevention**:
- Track replanning count in checkpoint
- Maximum 2 replans per phase
- After limit, escalate to user

**Checkpoint Updates**:
```json
{
  "replanning_count": 1,
  "last_replan_reason": "Phase 3 complexity exceeded threshold",
  "replan_phase_3_count": 1,
  "replan_history": [
    {
      "phase": 3,
      "type": "expand_phase",
      "timestamp": "2025-10-06T15:00:00Z",
      "reason": "Complexity threshold exceeded"
    }
  ]
}
```

### Validation and Error Handling

**Input Validation**:
- `--auto-mode` flag present
- `--context` parameter provided
- JSON is valid and parseable
- Required fields present for revision_type
- `revision_type` is recognized
- `current_phase` is valid number

**Error Cases**:

1. **Invalid JSON**: Return error, do not modify plan
2. **Unknown revision_type**: Return error with list of valid types
3. **Invalid phase number**: Return error, check plan structure
4. **Missing required fields**: Return error listing missing fields
5. **File operation failure**: Restore backup, return error
6. **Expansion command fails**: Return error with /expand phase output

### Safety Mechanisms

1. **Always Create Backup**: Before any modification
2. **Atomic Operations**: Complete revision or rollback entirely
3. **Validation Before Write**: Verify plan structure after changes
4. **Idempotency**: Same context → same result (deterministic)
5. **Audit Trail**: Every auto-mode revision logged in plan history

### Example Revision History Entry (Auto-Mode)

```markdown
## Revision History

### [2025-10-06 15:23:45] - Auto-Revision: Expand Phase 3
**Trigger**: /implement detected complexity threshold exceeded
**Type**: expand_phase
**Reason**: Phase 3 complexity score 9.2 exceeds threshold 8.0 (12 tasks)
**Action**: Expanded Phase 3 into separate file
**Files Modified**:
- Created: specs/plans/025_plan/phase_3_implementation.md
- Updated: specs/plans/025_plan/025_plan.md (structure level 0 → 1)
**Automated**: Yes (--auto-mode)
```

## Testing Auto-Mode

```bash
# Test expand_phase trigger
/revise specs/plans/test_plan.md --auto-mode --context '{
  "revision_type": "expand_phase",
  "current_phase": 2,
  "reason": "Phase complexity: 11 tasks, score 9.5",
  "suggested_action": "Expand phase 2",
  "complexity_metrics": {"tasks": 11, "score": 9.5}
}'

# Expected: Phase 2 expanded, structure level updated

# Test add_phase trigger
/revise specs/plans/test_plan.md --auto-mode --context '{
  "revision_type": "add_phase",
  "current_phase": 1,
  "reason": "Missing database setup phase",
  "suggested_action": "Add phase before Phase 2",
  "insert_position": "after",
  "new_phase_name": "Database Setup"
}'

# Expected: New phase inserted after Phase 1, phases renumbered

# Test collapse_phase trigger
/revise specs/plans/test_plan.md --auto-mode --context '{
  "revision_type": "collapse_phase",
  "current_phase": 3,
  "reason": "Phase 3 completed and now simple (4 tasks, complexity 3.5)",
  "suggested_action": "Collapse Phase 3 back into main plan",
  "simplicity_metrics": {"tasks": 4, "complexity_score": 3.5, "completion": true}
}'

# Expected: Phase 3 collapsed, structure level updated

# Test error handling
/revise specs/plans/test_plan.md --auto-mode --context '{
  "revision_type": "unknown_type"
}'

# Expected: Error response with valid types listed
```
## Process

1. **Plan Discovery**
   - Identifies the most recent plan mentioned in conversation
   - Searches for both `.md` files (L0) and directories (L1/L2)
   - Falls back to most recently modified plan if none mentioned
   - Detects structure level using `parse-adaptive-plan.sh detect_structure_level`
   - Checks which phases/stages are expanded

2. **Revision Scope Analysis**
   - **High-level changes** (metadata, overview, problem statement):
     - **L0**: Revise single file
     - **L1/L2**: Revise main plan file only
   - **Phase-specific changes** (tasks, testing, phase objectives):
     - **L0**: Revise relevant phase section in main plan
     - **L1**: If phase is expanded, revise `phase_N_name.md`; otherwise revise main plan
     - **L2**: Revise stage files, phase overview, or main plan as appropriate
   - **Cross-cutting changes** (affects multiple phases):
     - Revise multiple files as needed
     - Maintain cross-reference integrity

3. **Report Integration** (if provided)
   - Reads specified research reports
   - Extracts relevant recommendations and findings
   - Incorporates insights into revision strategy

4. **Level-Aware Revision Application**

   **Level 0 (Single File)**:
   - Use Edit tool on single `.md` file
   - Update relevant sections inline
   - Preserve completion markers
   - Add revision history

   **Level 1 (Phase-Expanded)**:
   - Determine target file(s) based on scope and expansion
   - Update main plan for high-level changes
   - Update expanded phase files for phase-specific changes
   - Update inline phases in main plan if not expanded
   - Update cross-references if structure changes
   - Add revision history to main plan

   **Level 2 (Stage-Expanded)**:
   - Navigate to appropriate level (main/phase/stage)
   - Update relevant file(s)
   - Propagate changes through hierarchy if needed
   - Update all affected cross-references
   - Add revision history to main plan

5. **Documentation**
   - Adds revision history to main plan
   - Documents what changed and why
   - References any reports used for guidance
   - Notes which files were modified (L1/L2)

6. **Structure Optimization Analysis**
   - Source `.claude/lib/structure-eval-utils.sh`
   - Identify affected phases using `get_affected_phases()`
   - Evaluate each affected phase for collapse/expansion opportunities
   - Display recommendations using `display_structure_recommendations()`
   - Show commands for user to execute structure optimizations
   - **Interactive Mode**: Display recommendations to user
   - **Auto-Mode**: Include recommendations in JSON response under `structure_recommendations` field

## Plan Structure Preservation

The command maintains:
- Original metadata (date, feature, scope)
- Phase numbering and dependencies
- Completion markers for executed phases
- Success criteria and risk assessments

## Revision History Format

Adds a section like:
```markdown
## Revision History

### [Date] - Revision 1
**Changes**: Description of what was revised
**Reason**: Why the revision was needed
**Reports Used**: List of reports that guided the revision
**Modified Phases**: List of phases that were updated
```

## Error Handling

- **No Plans Found**: Suggests creating a plan first with `/plan`
- **Invalid Report Paths**: Lists which reports couldn't be found
- **Malformed Plan**: Preserves original and creates backup before revision

## Integration with Other Commands

- Use `/list-plans` to see all available plans before choosing one to revise
- Use `/list-reports` to find relevant research reports for guidance
- After revision, use `/implement` to execute the updated plan

## Best Practices

1. **Be Specific**: Provide clear revision details for what should change in the plan
2. **Use Reports**: Reference research reports for evidence-based revisions
3. **Preserve Progress**: Don't remove completion markers for already-executed phases
4. **Document Changes**: The revision history helps track plan evolution
5. **Review Before Implementation**: After revising, review the plan before using `/implement`
6. **Keep Revisions Focused**: Make targeted changes rather than rewriting entire plans

## Notes

- **Plan-only operation**: This command ONLY modifies the plan document, no code changes
- **Conversation-aware**: Prioritizes plans mentioned in the current conversation
- **Backup creation**: Always creates a backup of the original plan before revision
- **Implementation-ready**: Maintains compatibility with `/implement` command
- **Section preservation**: Preserves any custom sections added to the plan
- **Audit trail**: Revision details become part of the plan's permanent history
- **No auto-implementation**: You must explicitly run `/implement` after revising if you want to execute the plan