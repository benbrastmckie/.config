# /repair Command Plan Standards Analysis

## Metadata
- **Date**: 2025-12-02
- **Agent**: research-specialist
- **Topic**: Repair command plan generation standards analysis
- **Report Type**: codebase analysis and standards comparison
- **Complexity**: 3

## Executive Summary

The /repair command generates plans that diverge from /plan command standards in metadata structure, field naming conventions, and structural organization. Analysis reveals /repair uses ad-hoc metadata fields (Type, Plan ID, Created timestamp) while /plan uses standardized fields (Feature, Scope, Estimated Phases). Both commands invoke plan-architect agent but pass different context, causing plan-architect to produce inconsistent outputs. Establishing a unified plan metadata standard in documentation will enable validation, enforcement, and consistent plan structure across all plan-generating commands (/plan, /repair, /revise, /debug). Integration with existing validation infrastructure (pre-commit hooks, linters) and plan-parsing libraries ensures enforcement without manual review.

## Findings

### 1. Metadata Field Divergence Between /plan and /repair Plans

**Evidence from Comparative Analysis**:

**File**: `/home/benjamin/.config/.claude/specs/006_plan_command_orchestration_fix/plans/001-plan-command-orchestration-fix-plan.md` (created by /plan)

Lines 3-17 show /plan metadata structure:
```markdown
## Metadata
- **Date**: 2025-12-02 (Revised)
- **Feature**: Fix pseudo-code Task invocations across all workflow commands (system-wide)
- **Scope**: Audit and fix all 7 workflow commands in .claude/commands/ using incorrect Task invocation patterns
- **Estimated Phases**: 6
- **Estimated Hours**: 21-28 hours (increased from 18-24 to include agent file fixes)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Complexity Score**: 132.5 (increased from 87.5 due to 7 commands with 16+ Task invocations)
- **Structure Level**: 0
- **Research Reports**:
  - [Plan Command Orchestration Failure Analysis](../reports/001-plan-command-orchestration-failure.md)
  - [Command Orchestration Review - Cross-Command Analysis](../reports/command_orchestration_review.md)
  - [Agent Task Invocation Violations Analysis](../reports/003-agent-violations-analysis.md)
```

**File**: `/home/benjamin/.config/.claude/specs/020_repair_implement_20251202_003956/plans/001-repair-implement-20251202-003956-plan.md` (created by /repair)

Lines 3-13 show /repair metadata structure:
```markdown
## Metadata
- **Date**: 2025-12-02T01:04:41Z (revised)
- **Feature**: /implement command error fixes
- **Status**: [COMPLETE]
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Plan ID**: 001-repair-implement-20251202-003956-plan
- **Created**: 2025-12-02T00:39:56Z
- **Type**: repair
- **Complexity**: 2 (Medium)
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/020_repair_implement_20251202_003956/reports/001-implement-errors-repair.md
  - /home/benjamin/.config/.claude/specs/020_repair_implement_20251202_003956/reports/002-standards-conformance-analysis.md
- **Estimated Duration**: 13-18 hours (6 phases)
- **Phase Count**: 6
```

**Key Divergences Identified**:

1. **Field Naming Inconsistency**:
   - /plan uses: `Estimated Hours` (numeric range)
   - /repair uses: `Estimated Duration` (time range with phase count)

2. **Timestamp Format Divergence**:
   - /plan uses: Human-readable date `2025-12-02 (Revised)`
   - /repair uses: ISO 8601 timestamp `2025-12-02T01:04:41Z (revised)`

3. /repair-Specific Fields Not in /plan Standard**:
   - `Plan ID`: Unique identifier (e.g., `001-repair-implement-20251202-003956-plan`)
   - `Created`: Separate creation timestamp field
   - `Type`: Plan type classification (`repair`)
   - `Phase Count`: Explicit phase count (redundant with phase section parsing)

4. **Missing /plan Fields in /repair Plans**:
   - `Scope`: High-level scope description (multi-line)
   - `Estimated Phases`: Phase count estimate (before planning)
   - `Complexity Score`: Numeric complexity calculation (used for tier selection)
   - `Structure Level`: Plan structure tier (0/1/2 for single-file/phase-dir/hierarchical)

5. **Research Reports Format Divergence**:
   - /plan uses: Relative paths with markdown links `[Title](../reports/file.md)`
   - /repair uses: Absolute paths as bullet list items without links

### 2. plan-architect Agent Receives Different Context from Each Command

**Evidence from Command Source Analysis**:

**File**: `/home/benjamin/.config/.claude/commands/plan.md`

Lines 1196-1227 show /plan's plan-architect invocation (Block 2):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan for ${FEATURE_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are creating an implementation plan for: plan workflow

    **Workflow-Specific Context**:
    - Feature Description: ${FEATURE_DESCRIPTION}
    - Output Path: ${PLAN_PATH}
    - Research Reports: ${REPORT_PATHS_LIST}
    - Workflow Type: research-and-plan
    - Operation Mode: new plan creation
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}
    - Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}

    **Project Standards**:
    ${FORMATTED_STANDARDS}

    If an archived prompt file is provided (not 'none'), reference it for complete context.

    IMPORTANT: If your planned approach conflicts with provided standards for well-motivated reasons, include Phase 0 to revise standards with clear justification and user warning. See Standards Divergence Protocol in plan-architect.md.

    Execute planning according to behavioral guidelines and return completion signal:
    PLAN_CREATED: ${PLAN_PATH}
  "
}
```

**File**: `/home/benjamin/.config/.claude/commands/repair.md`

Lines 1159-1206 show /repair's plan-architect invocation (Block 2b-exec):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan for ${ERROR_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are creating an implementation plan for: repair workflow

    **Input Contract (Hard Barrier Pattern)**:
    - Plan Path: ${PLAN_PATH}
    - Feature Description: ${ERROR_DESCRIPTION}
    - Research Reports: ${REPORT_PATHS_JSON}
    - Workflow Type: research-and-plan
    - Operation Mode: new plan creation

    **Project Standards**:
    ${FORMATTED_STANDARDS}

    **CRITICAL**: You MUST create the plan file at the EXACT path specified above.
    The orchestrator has pre-calculated this path and will validate it exists after you return.

    **REPAIR-SPECIFIC REQUIREMENT**:
    Since this is a repair plan addressing logged errors, you MUST include a final phase
    titled 'Update Error Log Status' as the last phase (after all fix phases) with:

    dependencies: [all previous phases]

    **Objective**: Update error log entries from FIX_PLANNED to RESOLVED

    Tasks:
    - [ ] Verify all fixes are working (tests pass, no new errors generated)
    - [ ] Update error log entries to RESOLVED status:
      \`\`\`bash
      source .claude/lib/core/error-handling.sh
      RESOLVED_COUNT=\$(mark_errors_resolved_for_plan \"\${PLAN_PATH}\")
      echo \"Resolved \$RESOLVED_COUNT error log entries\"
      \`\`\`
    - [ ] Verify no FIX_PLANNED errors remain for this plan:
      \`\`\`bash
      REMAINING=\$(query_errors --status FIX_PLANNED | jq -r '.repair_plan_path' | grep -c \"\$(basename \"\$(dirname \"\$(dirname \"\${PLAN_PATH}\")\")\" )\" || echo \"0\")
      [ \"\$REMAINING\" -eq 0 ] && echo \"All errors resolved\" || echo \"WARNING: \$REMAINING errors still FIX_PLANNED\"
      \`\`\`

    Execute planning according to behavioral guidelines and return completion signal:
    PLAN_CREATED: ${PLAN_PATH}
  "
}
```

**Key Context Differences**:

1. **Workflow Identification**:
   - /plan: `You are creating an implementation plan for: plan workflow`
   - /repair: `You are creating an implementation plan for: repair workflow`

2. **Research Reports Format**:
   - /plan: `${REPORT_PATHS_LIST}` (space-separated list)
   - /repair: `${REPORT_PATHS_JSON}` (JSON array)

3. **Prompt File Context** (only /plan):
   - `Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}`
   - `Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}`

4. **Hard Barrier Pattern Emphasis** (only /repair):
   - Explicit `**Input Contract (Hard Barrier Pattern)**:` header
   - `**CRITICAL**: You MUST create the plan file at the EXACT path...` warning

5. **Repair-Specific Requirements** (only /repair):
   - Mandatory final phase: "Update Error Log Status"
   - Error log integration bash snippets
   - FIX_PLANNED → RESOLVED status update requirements

**Impact**: plan-architect agent sees "repair workflow" vs "plan workflow" identifier and receives explicit repair-specific requirements, causing it to generate plans with repair-oriented metadata fields (Type: repair, Plan ID with timestamp, Created timestamp) not present in /plan standard.

### 3. No Canonical Plan Metadata Standard Documentation

**Evidence from Documentation Survey**:

**Search Results**: Grep pattern `^## Metadata|Plan Metadata|plan.*format` across `/home/benjamin/.config/.claude/docs/` found 33 files, but none define a canonical plan metadata schema.

**Files Checked**:
1. `/home/benjamin/.config/.claude/docs/concepts/patterns/metadata-extraction.md`: Defines metadata extraction pattern for agent return values (report/plan summary + paths), NOT plan file internal metadata structure.

2. `/home/benjamin/.config/.claude/lib/plan/README.md`: Documents plan parsing libraries (`plan-core-bundle.sh`, `complexity-utils.sh`, `standards-extraction.sh`) but no metadata field requirements.

3. `/home/benjamin/.config/.claude/agents/plan-architect.md` (lines 1-300): Defines plan creation process, complexity calculation, tier selection, but metadata structure shown only in examples without field requirement specification.

**Evidence of Metadata Parsing Dependencies**:

**File**: `/home/benjamin/.config/.claude/docs/concepts/patterns/metadata-extraction.md` (lines 91-102)
```markdown
# Extract plan metadata
extract_plan_metadata "/path/to/plan.md"

# Returns JSON:
# {
#   "title": "OAuth Implementation Plan",
#   "phases": 5,
#   "complexity": 7.2,
#   "estimated_time": "12-16 hours",
#   "high_complexity_phases": [2, 4],
#   "path": "/path/to/plan.md"
# }
```

This shows `.claude/lib/workflow/metadata-extraction.sh` expects specific metadata fields (`phases`, `complexity`, `estimated_time`) but no documentation specifies:
- Required vs optional fields
- Field naming conventions (snake_case, kebab-case, Title Case)
- Value formats (timestamps, numeric ranges, enumerations)
- Validation rules

**Impact**: Without canonical documentation:
1. Each command team interprets metadata differently
2. plan-architect agent has no specification to validate against
3. Downstream tools (metadata parsers, progress trackers) must handle inconsistent formats
4. Adding new plan-generating commands requires reverse-engineering existing plans

### 4. Existing Infrastructure for Plan Parsing and Validation

**Evidence from Codebase Infrastructure**:

**File**: `/home/benjamin/.config/.claude/lib/plan/plan-core-bundle.sh`

Functions available for metadata parsing:
- `extract_phase_name()` - Extract phase name from heading
- `extract_phase_content()` - Extract full phase content
- `parse_phase_list()` - Get list of all phases
- `detect_structure_level()` - Detect plan structure level (0/1/2)
- `is_phase_expanded()` - Check if phase is expanded

**File**: `/home/benjamin/.config/.claude/lib/plan/complexity-utils.sh`

Functions for complexity analysis:
- `calculate_phase_complexity()` - Calculate complexity score (0-10+)
- `analyze_task_structure()` - Analyze task metrics
- `detect_complexity_triggers()` - Check if thresholds exceeded

**File**: `/home/benjamin/.config/.claude/scripts/validate-all-standards.sh`

Existing validation infrastructure:
```bash
# Run all validators
bash .claude/scripts/validate-all-standards.sh --all

# Run specific validator categories
bash .claude/scripts/validate-all-standards.sh --sourcing      # Library sourcing
bash .claude/scripts/validate-all-standards.sh --suppression   # Error suppression
bash .claude/scripts/validate-all-standards.sh --conditionals  # Bash conditionals
bash .claude/scripts/validate-all-standards.sh --readme        # README structure
bash .claude/scripts/validate-all-standards.sh --links         # Link validity
```

**File**: `/home/benjamin/.config/.claude/hooks/pre-commit`

Pre-commit hook validates standards:
```bash
# Pre-commit hook runs on all staged .claude/ files
# ERROR-level violations (sourcing, suppression, conditionals) block commits
# WARNING-level issues (README, links) are informational only
```

**Integration Opportunity**: Existing validation infrastructure can be extended with plan metadata validator:
1. Create `.claude/scripts/lint/validate-plan-metadata.sh`
2. Integrate into `validate-all-standards.sh --plans` category
3. Add to pre-commit hook for plan file commits
4. Use plan-parsing libraries for field extraction and validation

### 5. Standards Integration Pattern Already Defined

**Evidence from Standards Integration Documentation**:

**File**: `/home/benjamin/.config/.claude/agents/plan-architect.md` (lines 80-95)

plan-architect agent receives project standards via prompt injection:
```markdown
**Standards Integration**:

YOU WILL receive project standards content in your prompt under a "**Project Standards**" heading. This content is extracted from CLAUDE.md and includes planning-relevant sections:

- **Code Standards**: Sourcing patterns, language conventions, architectural requirements
- **Testing Protocols**: Test discovery, coverage requirements, test patterns
- **Documentation Policy**: README requirements, documentation format, update standards
- **Error Logging**: Error handling integration, logging patterns
- **Clean Break Development**: Refactoring approach for enhancements
- **Directory Organization**: File placement rules, directory structure

**What YOU MUST Do**:
1. **Parse Standards Sections**: Read each standards section provided in prompt
2. **Reference During Planning**: Ensure Technical Design, Testing Strategy, and Documentation Requirements align with these standards
3. **Detect Divergence**: If your planned approach conflicts with existing standards for well-motivated reasons (e.g., adopting new technology that requires different conventions), proceed to Standards Divergence Protocol below
4. **Validate Alignment**: Include standards compliance as explicit success criteria in each phase
```

**File**: `/home/benjamin/.config/.claude/lib/plan/standards-extraction.sh`

Standards extraction library functions:
- `extract_claude_section(section_name)` - Extract single named section from CLAUDE.md
- `extract_planning_standards()` - Extract all 6 planning-relevant sections
- `format_standards_for_prompt()` - Format sections for agent prompt injection
- `validate_standards_extraction()` - Test standards extraction functionality

**Integration Pattern** (lines 118-127):
```markdown
**Integration Pattern:**
Used by `/plan`, `/revise`, and other planning commands to inject project standards into agent prompts. Enables automatic standards validation and divergence detection (Phase 0 protocol). See [Standards Integration Pattern](../../docs/guides/patterns/standards-integration.md) for complete usage.
```

**Key Insight**: /plan and /repair both use standards-extraction.sh to inject CLAUDE.md standards into plan-architect prompts. Adding a "plan_metadata_standard" section to CLAUDE.md would:
1. Automatically inject into all plan-generating commands
2. Enable plan-architect to validate metadata during creation
3. Provide single source of truth for all plan metadata requirements
4. Support divergence detection (Phase 0) if new commands need different metadata

### 6. Example Plan from Reference Documentation

**File**: `/home/benjamin/.config/.claude/specs/005_repair_research_20251201_212513/plans/001-repair-research-20251201-212513-plan.md` (mentioned in research context)

Lines 1-30:
```markdown
# Implementation Plan: /research Command Error Repair

**Plan Metadata**
- Type: repair
- Complexity: 2
- Created: 2025-12-02
- Research Report: /home/benjamin/.config/.claude/specs/005_repair_research_20251201_212513/reports/001-research-errors-repair.md
- Workflow: research-and-plan

---

## Plan Overview

This plan addresses systematic runtime errors in the `/research` command and related commands affecting workflow initialization, state restoration, and library sourcing. These errors prevent successful workflow execution and reduce reliability across multiple commands.

**Root Causes Addressed**:
1. Bash conditional syntax - negation operator `!` escaping during preprocessing
2. State restoration failures - critical variables not restored from state files
3. Library sourcing reliability - validation-utils.sh treated as optional when required
4. Find command failures - undefined directory variables cause cascading errors
5. TODO.md integration gaps - incomplete tracking across artifact-creating commands

**Success Criteria**:
- [ ] All bash conditionals execute without syntax errors
- [ ] State restoration succeeds across all workflow bash blocks
- [ ] validate_agent_artifact() function available when needed
- [ ] Find commands handle missing directory variables gracefully
- [ ] TODO.md updates execute for all artifact-creating commands
- [ ] Error log entries marked RESOLVED after verification
```

**Observation**: This repair plan uses:
- `**Plan Metadata**` header (bold format) instead of `## Metadata` (heading format)
- Different field set: `Type`, `Complexity`, `Created`, `Research Report`, `Workflow`
- Integrated "Plan Overview" with root causes and success criteria (not separate sections)
- No `Feature`, `Scope`, `Estimated Hours`, or `Structure Level` fields

**Impact**: Even within /repair command, plan metadata structure varies between different execution instances, suggesting plan-architect generates metadata based on implicit context rather than explicit specification.

## Recommendations

### 1. Create Canonical Plan Metadata Standard in CLAUDE.md

**Action**: Add new section to `/home/benjamin/.config/CLAUDE.md`:

```markdown
<!-- SECTION: plan_metadata_standard -->
## Plan Metadata Standard
[Used by: /plan, /repair, /revise, /debug, plan-architect]

All implementation plans (Level 0, 1, or 2) must include a standardized `## Metadata` section with required and optional fields in consistent format.

### Required Metadata Fields

**Field Format**: `- **Field Name**: value` (list item with bold field name, colon separator)

1. **Date**: Creation/revision date in ISO 8601 format (YYYY-MM-DD)
   - Format: `2025-12-02` or `2025-12-02 (Revised)`
   - Append "(Revised)" for plan revisions

2. **Feature**: One-line feature description (50-100 chars)
   - Format: Concise statement of what is being implemented/fixed
   - Example: `Fix pseudo-code Task invocations across all workflow commands`

3. **Status**: Current plan status using progress markers
   - Allowed values: `[NOT STARTED]`, `[IN PROGRESS]`, `[COMPLETE]`, `[BLOCKED]`
   - Format: Use bracket notation for consistency with phase markers

4. **Estimated Hours**: Time estimate as numeric range
   - Format: `{low}-{high} hours` (e.g., `21-28 hours`)
   - Include revision notes if estimate changes (e.g., `21-28 hours (increased from 18-24)`)

5. **Standards File**: Absolute path to CLAUDE.md used for standards compliance
   - Format: `/absolute/path/to/CLAUDE.md`
   - Enables traceability to standards version

6. **Research Reports**: List of research reports that informed this plan
   - Format: Markdown links with relative paths
   - Example:
     ```markdown
     - **Research Reports**:
       - [Report Title 1](../reports/001-report-name.md)
       - [Report Title 2](../reports/002-report-name.md)
     ```
   - Use `none` if plan created without research phase

### Optional Metadata Fields

7. **Scope** (recommended for complex plans): Multi-line scope description
   - Format: Paragraph describing boundaries and affected systems
   - Example: `Audit and fix all 7 workflow commands in .claude/commands/ using incorrect Task invocation patterns`

8. **Complexity Score**: Numeric complexity calculation from plan-architect
   - Format: `{score}` (e.g., `132.5`) with optional calculation explanation
   - Example: `132.5 (increased from 87.5 due to 7 commands with 16+ Task invocations)`
   - Used for tier selection (Level 0/1/2 structure)

9. **Structure Level**: Plan structure tier
   - Allowed values: `0` (single file), `1` (phase directory), `2` (hierarchical tree)
   - Corresponds to complexity thresholds in [Adaptive Planning](adaptive-planning.md)

10. **Estimated Phases**: Phase count estimate (before detailed planning)
    - Format: Numeric (e.g., `6`)
    - Helps track planning accuracy (estimate vs actual phase count)

### Workflow-Specific Optional Fields

**For /repair Plans**:
- **Error Log Query**: Error log filters used for repair planning
  - Format: `--type {type} --command {command} --since {time}`
  - Example: `--type state_error --command /implement --since 24h`

- **Errors Addressed**: Count of error log entries addressed by this plan
  - Format: `{count} errors (IDs: {comma-separated error IDs})`
  - Links plan to specific error log entries for traceability

**For /revise Plans**:
- **Original Plan**: Path to plan being revised
  - Format: `/absolute/path/to/original-plan.md`
  - Enables revision history tracking

- **Revision Reason**: Brief reason for revision (1-2 sentences)
  - Format: Free text explaining WHY revision was needed
  - Example: `User feedback indicated Phase 3 scope too broad, splitting into 2 phases`

### Metadata Section Placement and Format

**Position**: Immediately after plan title (first heading), before all other sections

**Format Example**:
```markdown
# Feature Name - Implementation Plan

## Metadata
- **Date**: 2025-12-02
- **Feature**: Implement user authentication with JWT tokens
- **Status**: [IN PROGRESS]
- **Estimated Hours**: 12-16 hours
- **Standards File**: /home/user/project/CLAUDE.md
- **Research Reports**:
  - [OAuth Patterns Analysis](../reports/001-oauth-patterns.md)
  - [Security Best Practices](../reports/002-security-practices.md)
- **Scope**: Add JWT-based authentication to REST API, including token generation, validation, refresh mechanism, and integration with existing user management system
- **Complexity Score**: 87.5
- **Structure Level**: 0

## Overview
...
```

### Validation and Enforcement

**Validation Script**: `.claude/scripts/lint/validate-plan-metadata.sh`
- Checks all required fields present
- Validates field formats (dates, numeric ranges, status markers)
- Verifies research report links exist
- Reports missing optional recommended fields (Scope, Complexity Score) as warnings

**Integration**: Add to pre-commit hooks and `validate-all-standards.sh --plans` category

**Error Handling**: Block plan file commits with missing required metadata fields (ERROR-level validation)
<!-- END_SECTION: plan_metadata_standard -->
```

**Rationale**:
- Establishes single source of truth for all plan metadata requirements
- Automatically injected into plan-architect prompts via existing standards-extraction.sh
- Enables validation via existing pre-commit and linter infrastructure
- Supports workflow-specific extensions (repair, revise) without breaking core standard
- Uses CLAUDE.md section pattern already integrated in all commands

### 2. Update /repair Command to Use Standard Metadata Context

**File**: `/home/benjamin/.config/.claude/commands/repair.md` (Block 2b-exec, lines 1159-1206)

**Changes**:

**Current**:
```markdown
**Input Contract (Hard Barrier Pattern)**:
- Plan Path: ${PLAN_PATH}
- Feature Description: ${ERROR_DESCRIPTION}
- Research Reports: ${REPORT_PATHS_JSON}
- Workflow Type: research-and-plan
- Operation Mode: new plan creation
```

**Revised**:
```markdown
**Input Contract (Hard Barrier Pattern)**:
- Plan Path: ${PLAN_PATH}
- Feature Description: ${ERROR_DESCRIPTION}
- Research Reports: ${REPORT_PATHS_LIST}
- Workflow Type: research-and-plan
- Operation Mode: new plan creation
- Command Context: repair
- Error Log Query: ${ERROR_FILTERS}
```

**Explanation**:
1. Change `REPORT_PATHS_JSON` → `REPORT_PATHS_LIST` to match /plan format (space-separated)
2. Add `Command Context: repair` instead of "repair workflow" identifier (normalized)
3. Add `Error Log Query` field to pass repair-specific metadata for plan metadata section
4. Keep repair-specific requirements (error log status update phase) as addendum, not core context

**Impact**: plan-architect receives consistent research reports format and normalized workflow identifier, but repair-specific requirements remain for final phase generation.

### 3. Create Plan Metadata Validation Script

**File**: `/home/benjamin/.config/.claude/scripts/lint/validate-plan-metadata.sh` (new)

**Implementation**:
```bash
#!/bin/bash
# Validate plan metadata compliance with canonical standard

set -euo pipefail

PLAN_FILE="${1:-}"
if [ -z "$PLAN_FILE" ] || [ ! -f "$PLAN_FILE" ]; then
  echo "ERROR: Plan file not found: $PLAN_FILE" >&2
  exit 1
fi

# Extract metadata section (between "## Metadata" and next "##" heading)
METADATA=$(sed -n '/^## Metadata$/,/^##/p' "$PLAN_FILE" | head -n -1)

if [ -z "$METADATA" ]; then
  echo "ERROR: No ## Metadata section found in $PLAN_FILE" >&2
  exit 1
fi

# Required fields
REQUIRED_FIELDS=("Date" "Feature" "Status" "Estimated Hours" "Standards File" "Research Reports")
ERRORS=0
WARNINGS=0

for field in "${REQUIRED_FIELDS[@]}"; do
  if ! echo "$METADATA" | grep -q "^\- \*\*${field}\*\*:"; then
    echo "ERROR: Missing required field: $field" >&2
    ERRORS=$((ERRORS + 1))
  fi
done

# Validate field formats
# Date format: YYYY-MM-DD or YYYY-MM-DD (Revised)
if ! echo "$METADATA" | grep -P '^\- \*\*Date\*\*: \d{4}-\d{2}-\d{2}( \(Revised\))?$'; then
  echo "WARNING: Date format should be YYYY-MM-DD or YYYY-MM-DD (Revised)" >&2
  WARNINGS=$((WARNINGS + 1))
fi

# Status format: [NOT STARTED], [IN PROGRESS], [COMPLETE], [BLOCKED]
if ! echo "$METADATA" | grep -E '^\- \*\*Status\*\*: \[(NOT STARTED|IN PROGRESS|COMPLETE|BLOCKED)\]$'; then
  echo "WARNING: Status should use bracket notation: [NOT STARTED], [IN PROGRESS], [COMPLETE], or [BLOCKED]" >&2
  WARNINGS=$((WARNINGS + 1))
fi

# Estimated Hours format: {low}-{high} hours
if ! echo "$METADATA" | grep -P '^\- \*\*Estimated Hours\*\*: \d+-\d+ hours'; then
  echo "WARNING: Estimated Hours should be numeric range: {low}-{high} hours" >&2
  WARNINGS=$((WARNINGS + 1))
fi

# Standards File format: absolute path
STANDARDS_PATH=$(echo "$METADATA" | grep '^\- \*\*Standards File\*\*:' | sed 's/.*: //')
if [[ ! "$STANDARDS_PATH" =~ ^/ ]]; then
  echo "ERROR: Standards File must be absolute path" >&2
  ERRORS=$((ERRORS + 1))
fi

# Research Reports: check if links are relative paths to ../reports/
REPORT_LINKS=$(echo "$METADATA" | grep -A 10 '^\- \*\*Research Reports\*\*:' | grep '^\s*-' | tail -n +1)
if [ -n "$REPORT_LINKS" ]; then
  while IFS= read -r link; do
    if ! echo "$link" | grep -q '\[.*\](../reports/.*\.md)'; then
      echo "WARNING: Research report links should use relative paths: [Title](../reports/file.md)" >&2
      WARNINGS=$((WARNINGS + 1))
      break
    fi
  done <<< "$REPORT_LINKS"
fi

# Optional recommended fields (warnings only)
RECOMMENDED_FIELDS=("Scope" "Complexity Score")
for field in "${RECOMMENDED_FIELDS[@]}"; do
  if ! echo "$METADATA" | grep -q "^\- \*\*${field}\*\*:"; then
    echo "INFO: Optional recommended field not present: $field" >&2
  fi
done

if [ $ERRORS -gt 0 ]; then
  echo "VALIDATION FAILED: $ERRORS errors, $WARNINGS warnings" >&2
  exit 1
elif [ $WARNINGS -gt 0 ]; then
  echo "VALIDATION PASSED: 0 errors, $WARNINGS warnings" >&2
  exit 0
else
  echo "VALIDATION PASSED: 0 errors, 0 warnings" >&2
  exit 0
fi
```

**Integration**:
1. Add to `validate-all-standards.sh`:
   ```bash
   # Add --plans category
   if [[ "$RUN_PLANS" == "true" ]]; then
     validate_plans
   fi
   ```

2. Add to pre-commit hook:
   ```bash
   # Validate plan files
   for plan_file in $STAGED_PLAN_FILES; do
     bash .claude/scripts/lint/validate-plan-metadata.sh "$plan_file" || EXIT_CODE=1
   done
   ```

3. Add to plan-architect behavioral file as self-validation step (Step 3)

### 4. Update plan-architect Agent to Validate Metadata During Creation

**File**: `/home/benjamin/.config/.claude/agents/plan-architect.md`

**Section**: STEP 3 (Plan Verification), lines 180-215

**Changes**:

**Current** (lines 180-215):
```markdown
### STEP 3 (REQUIRED BEFORE STEP 4) - Verify Plan File Created

**MANDATORY VERIFICATION - Plan File Exists**

After creating plan with Write tool, YOU MUST verify the file was created successfully:

**Verification Steps**:
1. **Verify Existence**: Confirm file exists at provided PLAN_PATH
2. **Verify Structure**: Check required sections present
3. **Verify Research Links**: Confirm research reports referenced (if provided) **[Revision 3]**
4. **Verify Cross-References**: Check metadata includes all report paths **[Revision 3]**
```

**Add** (new substep after existing verifications):
```markdown
5. **Verify Metadata Compliance**: Run metadata validation against canonical standard
   ```bash
   source "${CLAUDE_PROJECT_DIR}/.claude/scripts/lint/validate-plan-metadata.sh"
   validate_plan_metadata "$PLAN_PATH"
   VALIDATION_EXIT=$?
   if [ $VALIDATION_EXIT -ne 0 ]; then
     echo "ERROR: Plan metadata validation failed - see output above" >&2
     # Review and fix metadata section before returning
     # Re-run validation until VALIDATION_EXIT=0
   fi
   ```
   - Required fields: Date, Feature, Status, Estimated Hours, Standards File, Research Reports
   - Format validation: Date (YYYY-MM-DD), Status ([BRACKET]), Estimated Hours ({low}-{high} hours)
   - Research reports: Relative paths with markdown links [Title](../reports/file.md)
```

**Self-Verification Checklist Update**:
```markdown
**Self-Verification Checklist**:
- [ ] Plan file created at exact PLAN_PATH provided in prompt
- [ ] File contains all required sections
- [ ] Research reports listed in metadata (if provided)
- [ ] All report paths match those provided in prompt
- [ ] Metadata validation passes (validate-plan-metadata.sh exit 0)
- [ ] Plan structure is parseable by /implement
```

**Impact**: plan-architect validates its own metadata before returning, ensuring all plans (from /plan, /repair, /revise, /debug) conform to canonical standard regardless of workflow context.

### 5. Document Integration with Existing Infrastructure

**File**: `/home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md` (new)

**Content**:
```markdown
# Plan Metadata Standard

## Purpose

Defines canonical metadata structure for all implementation plans, enabling consistent parsing, validation, and progress tracking across workflows.

## Integration Points

### 1. Standards Extraction (Automatic Injection)

**File**: `.claude/lib/plan/standards-extraction.sh`

The `plan_metadata_standard` section in CLAUDE.md is automatically extracted and injected into plan-architect agent prompts via:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh"
FORMATTED_STANDARDS=$(format_standards_for_prompt)
```

**Commands Using Standards Injection**:
- `/plan` (Block 2, line 1170-1180)
- `/repair` (Block 2a-standards, line 948-989)
- `/revise` (plan revision workflow)
- `/debug` (debug report to plan workflow)

**Effect**: All plan-generating commands automatically receive canonical metadata standard, ensuring plan-architect creates compliant plans without manual coordination.

### 2. Metadata Parsing (Existing Libraries)

**File**: `.claude/lib/workflow/metadata-extraction.sh`

Function `extract_plan_metadata()` parses plan metadata section and returns JSON:

```bash
PLAN_METADATA=$(extract_plan_metadata "/path/to/plan.md")
echo "$PLAN_METADATA" | jq '.estimated_time'  # "12-16 hours"
echo "$PLAN_METADATA" | jq '.phases'          # 5
```

**Parsed Fields** (from standard):
- `title` - Extracted from first # heading
- `phases` - Count of ### Phase headings
- `complexity` - Extracted from Complexity Score field
- `estimated_time` - Extracted from Estimated Hours field
- `status` - Extracted from Status field (bracket notation)

**Consumers**:
- `/implement` - Extracts phases for progress tracking
- `/orchestrate` - Extracts complexity for adaptive planning
- Metadata extraction pattern - Returns condensed plan summary

### 3. Validation (Pre-commit Hooks)

**File**: `.claude/scripts/lint/validate-plan-metadata.sh`

Validates plan metadata compliance with canonical standard:

```bash
bash .claude/scripts/lint/validate-plan-metadata.sh /path/to/plan.md
# Exit 0: Validation passed
# Exit 1: Validation failed (blocks commit)
```

**Integrated Into**:
- Pre-commit hook (`.claude/hooks/pre-commit`) - Blocks commits with invalid metadata
- `validate-all-standards.sh --plans` - Batch validation of all plans
- plan-architect self-validation (STEP 3) - Validates during plan creation

**Validation Rules**:
- ERROR: Missing required fields (Date, Feature, Status, Estimated Hours, Standards File, Research Reports)
- ERROR: Standards File not absolute path
- WARNING: Date not in YYYY-MM-DD format
- WARNING: Status not using bracket notation
- WARNING: Estimated Hours not numeric range
- WARNING: Research reports not using relative paths with markdown links
- INFO: Optional recommended fields missing (Scope, Complexity Score)

### 4. Progress Tracking

**File**: `.claude/lib/plan/checkbox-utils.sh`

Functions use metadata Status field for plan-level progress:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh"

# Update plan status
update_plan_status "$PLAN_FILE" "[IN PROGRESS]"

# Check if plan complete
PLAN_STATUS=$(extract_plan_status "$PLAN_FILE")
if [ "$PLAN_STATUS" = "[COMPLETE]" ]; then
  echo "Plan implementation finished"
fi
```

**Status Progression**:
1. `[NOT STARTED]` - Plan created, implementation not begun
2. `[IN PROGRESS]` - At least one phase started
3. `[COMPLETE]` - All phases marked complete
4. `[BLOCKED]` - Implementation blocked (dependency or issue)

## Extension Mechanism

### Workflow-Specific Optional Fields

The canonical standard defines core required fields, but allows workflow-specific optional fields via documented extensions:

**Example - Repair Workflow Extension**:

```markdown
### Workflow-Specific Optional Fields

**For /repair Plans**:
- **Error Log Query**: Error log filters used for repair planning
  - Format: `--type {type} --command {command} --since {time}`
  - Example: `--type state_error --command /implement --since 24h`

- **Errors Addressed**: Count of error log entries addressed by this plan
  - Format: `{count} errors (IDs: {comma-separated error IDs})`
  - Links plan to specific error log entries for traceability
```

**Adding New Workflow Extensions**:
1. Define extension in CLAUDE.md `plan_metadata_standard` section under "Workflow-Specific Optional Fields"
2. Update validation script to recognize new fields (optional validation)
3. Update metadata-extraction.sh if new fields need parsing
4. Document in this file under "Extension Mechanism"

### Divergence Protocol (Phase 0)

If a new workflow requires metadata structure incompatible with canonical standard (rare), use Phase 0 Standards Divergence Protocol:

1. plan-architect detects conflict with provided standard
2. Generates Phase 0: Standards Revision in plan
3. Proposes specific metadata changes with justification
4. User reviews and approves before implementation
5. CLAUDE.md updated with new standard version

See [Standards Integration Pattern](.claude/docs/guides/patterns/standards-integration.md) for complete divergence protocol.

## Migration Strategy

### Existing Plans (Backward Compatibility)

**Approach**: No forced migration of existing plans. Metadata standard applies to:
- New plans created after standard implementation
- Plans revised using /revise command (metadata updated during revision)

**Reason**: Existing plans already integrated into workflows, changing metadata could break tooling dependencies. Progressive migration via natural revision cycle.

**Exception**: If metadata parsing functions (`extract_plan_metadata()`) break on old plans, add backward-compatible parsing logic handling both old and new formats.

### Future Plan-Generating Commands

All new commands that create plans (hypothetical examples: /prototype, /migrate, /deprecate) must:
1. Source standards-extraction.sh for automatic standard injection
2. Pass canonical metadata standard to plan-architect in prompt
3. Validate created plans using validate-plan-metadata.sh
4. Add workflow-specific optional fields to CLAUDE.md extension section if needed

## See Also

- [CLAUDE.md Plan Metadata Standard Section](../../CLAUDE.md#plan_metadata_standard) - Canonical specification
- [Standards Integration Pattern](../guides/patterns/standards-integration.md) - How standards are injected into agents
- [Metadata Extraction Pattern](../concepts/patterns/metadata-extraction.md) - How plan metadata is parsed and used
- [Plan Parsing Libraries](../../lib/plan/README.md) - Tools for metadata extraction and validation
```

**Rationale**: Comprehensive integration documentation ensures developers understand:
- Where canonical standard is defined (CLAUDE.md)
- How it's enforced (validation script + pre-commit)
- How it's integrated (standards-extraction.sh)
- How it's consumed (metadata-extraction.sh, checkbox-utils.sh)
- How to extend it (workflow-specific optional fields)
- Migration strategy (progressive, no forced updates)

## References

### Files Analyzed
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 1-1550) - /plan command implementation and plan-architect invocation
- `/home/benjamin/.config/.claude/commands/repair.md` (lines 1-1584) - /repair command implementation and plan-architect invocation
- `/home/benjamin/.config/.claude/agents/plan-architect.md` (lines 1-300) - plan-architect agent behavioral guidelines
- `/home/benjamin/.config/.claude/specs/006_plan_command_orchestration_fix/plans/001-plan-command-orchestration-fix-plan.md` (lines 1-150) - Example /plan output
- `/home/benjamin/.config/.claude/specs/020_repair_implement_20251202_003956/plans/001-repair-implement-20251202-003956-plan.md` (lines 1-150) - Example /repair output
- `/home/benjamin/.config/.claude/specs/005_repair_research_20251201_212513/plans/001-repair-research-20251201-212513-plan.md` (lines 1-30) - Example repair plan variation
- `/home/benjamin/.config/.claude/lib/plan/README.md` - Plan parsing libraries documentation
- `/home/benjamin/.config/.claude/lib/plan/standards-extraction.sh` - Standards extraction library
- `/home/benjamin/.config/.claude/docs/concepts/patterns/metadata-extraction.md` - Metadata extraction pattern documentation
- `/home/benjamin/.config/.claude/scripts/validate-all-standards.sh` - Validation infrastructure
- `/home/benjamin/.config/.claude/hooks/pre-commit` - Pre-commit hook

### External Documentation
- None (codebase-only analysis)

### Key Patterns Identified
1. **Standards Integration Pattern**: CLAUDE.md sections → standards-extraction.sh → plan-architect prompts
2. **Hard Barrier Pattern**: Pre-calculated paths + post-invocation validation
3. **Metadata Extraction Pattern**: Return condensed metadata instead of full content
4. **Validation Infrastructure**: Pre-commit hooks + linter scripts + ERROR/WARNING levels
5. **Workflow-Specific Extensions**: Core standard + optional workflow fields
