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

The /revise command supports two modes: Interactive Mode (default, user-driven with natural language input) and Auto-Mode (programmatic, JSON-based for /implement integration).

**See**: [Revision Types and Operation Modes](shared/revision-types.md) for comprehensive details on:

- **Interactive Mode**: Purpose, behavior, use cases (strategic changes, research integration, user control)
- **Auto-Mode**: Purpose, behavior, use cases (complexity triggers, test failures, automated adjustments)
- **Mode Comparison**: Detailed comparison table (trigger, input format, confirmation, revision types, artifact support)
- **When to Use Each Mode**: Decision guide for mode selection

**Quick Reference**:
- **Interactive**: `/revise "<changes>" [context-reports...]` - User-driven, natural language, plans + reports
- **Auto-Mode**: `/revise <plan> --auto-mode --context '<json>'` - Automated, deterministic, plans only

## Important Notes

**What This Command Does**: Modifies plans/reports, preserves completion status, adds revision history, creates backups, evaluates structure optimization, displays recommendations, supports section targeting (reports), returns structured responses (auto-mode).

**What This Command Does NOT Do**: Does NOT execute code, run tests, create commits, or implement plans. Auto-mode does NOT ask for user confirmation.

To implement the revised plan after revision, use `/implement [plan-file]`

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

Automated mode (`--auto-mode`) enables programmatic plan revision triggered by /implement during execution. It accepts structured JSON context, executes deterministic revision logic, and returns machine-readable success/failure status for seamless integration.

**See**: [Automated Mode Specification](shared/revise-auto-mode.md) for comprehensive details on:

- **Context JSON Structure**: Required format and fields for automated invocations
- **Revision Types**: expand_phase, add_phase, split_phase, update_tasks, collapse_phase (triggers, context fields, automated actions, response formats)
- **Decision Logic**: Validation, execution flow, backup/rollback procedures
- **Safety Mechanisms**: Atomic operations, idempotency, audit trail
- **Integration with /implement**: Trigger detection, loop prevention, checkpoint updates
- **Testing Auto-Mode**: Example invocations and expected behaviors

**Quick Reference**:
```bash
# Complexity trigger (auto-expand)
/revise <plan> --auto-mode --context '{"revision_type":"expand_phase","current_phase":3,"reason":"Complexity 9.2>8","complexity_metrics":{"tasks":12,"score":9.2}}'

# Test failure trigger (add phase)
/revise <plan> --auto-mode --context '{"revision_type":"add_phase","current_phase":2,"reason":"Missing prerequisites","new_phase_name":"Setup Dependencies"}'
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