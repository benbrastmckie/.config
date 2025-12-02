# Plan Metadata Deficiency Research Report

## Metadata
- **Date**: 2025-12-01
- **Agent**: research-specialist
- **Topic**: Plan metadata field deficiencies in /repair and /revise workflows
- **Report Type**: codebase analysis

## Executive Summary

Plans created by `/repair` and `/revise` commands lack the standard **Status** field (and potentially other metadata) found in `/plan` command outputs because these commands do NOT pass project standards to the plan-architect agent. The `/plan` command extracts CLAUDE.md standards sections using `standards-extraction.sh` library and injects them into the plan-architect prompt as a "**Project Standards**" section. The `/repair` and `/revise` commands completely omit this standards extraction step, causing plan-architect to generate plans without standards-mandated metadata fields. This represents a critical architectural inconsistency where 2 of 3 planning commands bypass the standards integration pattern.

## Findings

### 1. Root Cause: Missing Standards Extraction in /repair and /revise Commands

**Evidence from /plan command (CORRECT implementation)**:

File: `/home/benjamin/.config/.claude/commands/plan.md`

**Block 1f: Standards Extraction** (lines 1146-1177):
```bash
# === EXTRACT PROJECT STANDARDS ===
# Source standards extraction library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh" 2>/dev/null || {
  log_command_error "file_error" "Failed to source standards-extraction library" "..."
  echo "WARNING: Standards extraction unavailable, proceeding without standards" >&2
  FORMATTED_STANDARDS=""
}

# Extract and format standards for prompt injection
if [ -z "${FORMATTED_STANDARDS:-}" ]; then
  FORMATTED_STANDARDS=$(format_standards_for_prompt 2>/dev/null) || {
    log_command_error "execution_error" "Standards extraction failed" "{}"
    echo "WARNING: Standards extraction failed, proceeding without standards" >&2
    FORMATTED_STANDARDS=""
  }
fi

# Persist standards for Block 3 divergence detection
append_workflow_state "FORMATTED_STANDARDS<<STANDARDS_EOF
$FORMATTED_STANDARDS
STANDARDS_EOF"
```

**Block 2a-exec: Task Invocation with Standards** (lines 1200-1201):
```markdown
**Project Standards**:
${FORMATTED_STANDARDS}
```

**Evidence from /repair command (MISSING implementation)**:

File: `/home/benjamin/.config/.claude/commands/repair.md`

**Block 2b-exec: Plan Creation Delegation** (lines 1045-1089):
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

    **CRITICAL**: You MUST create the plan file at the EXACT path specified above.
    ...

    Execute planning according to behavioral guidelines and return completion signal:
    PLAN_CREATED: ${PLAN_PATH}
  "
}
```

**CRITICAL ABSENCE**: No "**Project Standards**:" section in Task prompt. No standards extraction logic in any bash blocks.

**Evidence from /revise command (MISSING implementation)**:

File: `/home/benjamin/.config/.claude/commands/revise.md`

**Block 5b-exec: Plan Revision Delegation** (lines 967-995):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Revise implementation plan based on ${REVISION_DETAILS} with mandatory file modification"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are revising an implementation plan for: revise workflow

    **Workflow-Specific Context**:
    - Existing Plan Path: ${EXISTING_PLAN_PATH}
    - Backup Path: ${BACKUP_PATH}
    - Revision Details: ${REVISION_DETAILS}
    - Research Reports: ${REPORT_PATHS_JSON}
    - Workflow Type: research-and-revise
    - Operation Mode: plan revision
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}

    **CRITICAL INSTRUCTIONS FOR PLAN REVISION**:
    ...

    Execute plan revision according to behavioral guidelines and return completion signal:
    PLAN_REVISED: ${EXISTING_PLAN_PATH}
  "
}
```

**CRITICAL ABSENCE**: No "**Project Standards**:" section in Task prompt. No standards extraction logic anywhere in the command.

**Confirmation via Grep Search**:
```bash
# Search for FORMATTED_STANDARDS in all commands
$ grep -l "FORMATTED_STANDARDS" .claude/commands/*.md
.claude/commands/plan.md
```

**Only `/plan` command uses the standards extraction pattern.**

---

### 2. Standards Extraction Library Exists but is Unused

**Evidence from standards-extraction.sh library**:

File: `/home/benjamin/.config/.claude/lib/plan/standards-extraction.sh`

**Core Function** (lines 202-233):
```bash
# format_standards_for_prompt - Format extracted standards for agent prompt
#
# USAGE:
#   formatted=$(format_standards_for_prompt)
#
# RETURNS:
#   Formatted markdown with headers suitable for prompt injection
#
# OUTPUT FORMAT:
#   ### Code Standards
#   [content]
#
#   ### Testing Protocols
#   [content]
#   ...
```

**Planning-Relevant Sections Extracted** (lines 149-156):
```bash
local sections=(
  "code_standards"
  "testing_protocols"
  "documentation_policy"
  "error_logging"
  "clean_break_development"
  "directory_organization"
)
```

**Library Purpose** (lines 3-6):
```bash
# PURPOSE:
#   Provides utilities for extracting standards sections from CLAUDE.md files
#   and formatting them for injection into plan-architect agent prompts.
```

**Analysis**: The library is SPECIFICALLY designed for this use case and is production-ready. It exists solely to support standards injection into plan-architect prompts, yet `/repair` and `/revise` commands don't use it.

---

### 3. Plan-Architect Agent Expects Standards in Prompt

**Evidence from plan-architect agent**:

File: `/home/benjamin/.config/.claude/agents/plan-architect.md`

**Standards Integration Protocol** (lines 79-95):
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
3. **Detect Divergence**: If your planned approach conflicts with existing standards for well-motivated reasons ...
4. **Validate Alignment**: Include standards compliance as explicit success criteria in each phase
```

**Metadata Template with Status Field** (lines 884-891):
```markdown
## Metadata
- **Date**: YYYY-MM-DD
- **Feature**: [Name]
- **Scope**: [Brief description]
- **Estimated Phases**: [N]
- **Estimated Hours**: [H]
- **Standards File**: /path/to/CLAUDE.md
- **Status**: [NOT STARTED]
- **Research Reports**:
```

**Validation Checks for Status Field** (lines 1153-1154):
```bash
# 5. Status field check (metadata must have Status field)
grep -q "^\- \*\*Status\*\*: \[NOT STARTED\]" "$PLAN_PATH" || echo "WARNING: Missing Status field in metadata"
```

**Quality Checklist** (lines 1209):
```markdown
- [ ] Status field present in metadata (`- **Status**: [NOT STARTED]`)
```

**Analysis**: Plan-architect EXPECTS to receive standards in the prompt and includes validation checks for standards-mandated fields like Status. Without standards being passed, the agent has no reference for required metadata structure.

---

### 4. Real-World Evidence: Plan Comparison

**PLAN WITH PROPER METADATA** (created by /plan command):

File: `/home/benjamin/.config/.claude/specs/994_optimize_claude_command_refactor/plans/001-optimize-claude-refactor-plan.md`

Metadata section (lines 2-13):
```markdown
## Metadata
- **Date**: 2025-12-01
- **Feature**: Refactor /optimize-claude command
- **Scope**: Remove hard abort criteria, standardize command structure, improve documentation guidance
- **Estimated Phases**: 7
- **Estimated Hours**: 5.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]  ← PRESENT
- **Structure Level**: 0
- **Complexity Score**: 42.5 (5 refactor + 9 tasks + 7 phases*5 + 0 integrations + 4.5 hours*0.5)
- **Research Reports**:
  - [/optimize-claude Refactor Research](/home/benjamin/.config/.claude/specs/994_optimize_claude_command_refactor/reports/001_optimize_claude_refactor_research.md)
```

**PLAN WITH DEFICIENT METADATA** (created by /repair command):

File: `/home/benjamin/.config/.claude/specs/995_repair_todo_20251201_143930/plans/001-repair-todo-20251201-143930-plan.md`

Metadata section (lines 3-14):
```markdown
## Metadata
- **Plan ID**: 001-repair-todo-20251201-143930-plan
- **Created**: 2025-12-01T14:39:30Z
- **Revised**: 2025-12-01T15:04:52Z
- **Workflow Type**: repair
- **Complexity**: 2
- **Status**: [IN PROGRESS]  ← MANUALLY ADDED AFTER CREATION
- **Feature**: /todo errors repair
- **Research Report**: /home/benjamin/.config/.claude/specs/995_repair_todo_20251201_143930/reports/001-todo-errors-repair.md
- **Conformance Analysis**: /home/benjamin/.config/.claude/specs/995_repair_todo_20251201_143930/reports/002-plan-conformance-analysis.md
- **Estimated Effort**: 8-13 hours (revised from 15-20h via infrastructure reuse)
- **Phase Count**: 7 phases
```

**CRITICAL DIFFERENCES**:
1. `/repair` plan uses different field names (Plan ID vs Date, Workflow Type vs Feature)
2. Status field was ADDED MANUALLY (revision timestamp shows it was added in second revision)
3. Missing **Standards File** field entirely
4. Different structure conventions (Created/Revised timestamps instead of Date)

**Another proper example** (also created by /plan):

File: `/home/benjamin/.config/.claude/specs/004_todo_command_subagent_delegation/plans/001-todo-command-subagent-delegation-plan.md`

Metadata section (lines 2-8):
```markdown
## Metadata
- **Date**: 2025-12-01
- **Feature**: Refactor /todo command to enforce hard barrier subagent delegation pattern
- **Scope**: Migrate TODO.md generation logic from orchestrator to todo-analyzer agent
- **Status**: [COMPLETE]  ← PRESENT
- **Estimated Phases**: 5
- **Complexity**: 3 (Moderate - Agent expansion + Command refactor + Preservation logic)
```

---

### 5. Architectural Inconsistency Across Planning Commands

**Command Comparison Matrix**:

| Command   | Standards Extraction | Standards Passed to Agent | Uses standards-extraction.sh | Status Field Present | Standards File Field |
|-----------|---------------------|--------------------------|------------------------------|----------------------|---------------------|
| `/plan`   | ✅ Yes (Block 1f)   | ✅ Yes (Task prompt)      | ✅ Yes                        | ✅ Yes               | ✅ Yes               |
| `/repair` | ❌ No               | ❌ No                     | ❌ No                         | ❌ No (manual add)   | ❌ No                |
| `/revise` | ❌ No               | ❌ No                     | ❌ No                         | ❌ No                | ❌ No                |

**Impact Severity**: **CRITICAL**

- 67% of planning commands (2 of 3) bypass standards integration architecture
- Plans created by different commands have incompatible metadata structures
- `/implement` and `/build` commands may fail when consuming non-standard plan metadata
- Standards compliance cannot be validated for `/repair` and `/revise` plans

---

### 6. Additional Discrepancies Beyond Status Field

**Missing Fields in /repair and /revise Plans**:

1. **Standards File**: No reference to source CLAUDE.md file path
2. **Structure Level**: No indication of plan expansion level (0, 1, 2)
3. **Complexity Score**: Different calculation method (simple integer vs weighted formula)
4. **Date Format**: Uses ISO 8601 timestamps (Created/Revised) instead of YYYY-MM-DD Date field

**Inconsistent Section Names**:
- `/plan` uses: **Date**, **Feature**, **Scope**, **Status**, **Standards File**
- `/repair` uses: **Plan ID**, **Created**, **Revised**, **Workflow Type**, **Complexity**, **Feature**

**Impact**: Automated tools expecting standard metadata structure will fail when processing `/repair` and `/revise` plans.

---

### 7. Standards Integration Pattern Documentation

**Evidence from CLAUDE.md**:

File: `/home/benjamin/.config/CLAUDE.md`

**Standards Integration Section** (line reference from grep):
```markdown
<!-- SECTION: code_standards -->
## Code Standards
[Used by: /implement, /refactor, /plan]

See [Code Standards](.claude/docs/reference/standards/code-standards.md) for complete coding conventions...
<!-- END_SECTION: code_standards -->
```

**Analysis**: CLAUDE.md explicitly documents that `/plan` command uses standards sections. The pattern is INTENDED to be followed by planning commands but is not enforced across `/repair` and `/revise`.

---

## Recommendations

### 1. **CRITICAL - Add Standards Extraction to /repair Command**

**Priority**: Critical
**Effort**: Low (2-3 hours)

**Implementation**:
1. Source `standards-extraction.sh` library in Block 1 (after state-persistence.sh)
2. Add standards extraction block before Block 2b (plan creation delegation):
   ```bash
   # Extract project standards for plan-architect
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh" 2>/dev/null || {
     log_command_error "file_error" "Failed to source standards-extraction library" "..."
     FORMATTED_STANDARDS=""
   }

   FORMATTED_STANDARDS=$(format_standards_for_prompt 2>/dev/null) || FORMATTED_STANDARDS=""

   # Persist for block isolation
   append_workflow_state "FORMATTED_STANDARDS<<STANDARDS_EOF
   $FORMATTED_STANDARDS
   STANDARDS_EOF"
   ```
3. Add standards section to Task prompt in Block 2b-exec:
   ```markdown
   **Project Standards**:
   ${FORMATTED_STANDARDS}
   ```

**Files to Modify**:
- `/home/benjamin/.config/.claude/commands/repair.md` (add Block 1g for standards extraction, modify Block 2b-exec Task prompt)

**Expected Outcome**: `/repair` command will generate plans with standard metadata structure including Status, Standards File, and proper Date field.

---

### 2. **CRITICAL - Add Standards Extraction to /revise Command**

**Priority**: Critical
**Effort**: Low (2-3 hours)

**Implementation**:
1. Source `standards-extraction.sh` library in Block 1
2. Add standards extraction block before Block 5b (plan revision delegation):
   ```bash
   # Extract project standards for plan-architect
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh" 2>/dev/null || {
     log_command_error "file_error" "Failed to source standards-extraction library" "..."
     FORMATTED_STANDARDS=""
   }

   FORMATTED_STANDARDS=$(format_standards_for_prompt 2>/dev/null) || FORMATTED_STANDARDS=""

   append_workflow_state "FORMATTED_STANDARDS<<STANDARDS_EOF
   $FORMATTED_STANDARDS
   STANDARDS_EOF"
   ```
3. Add standards section to Task prompt in Block 5b-exec:
   ```markdown
   **Project Standards**:
   ${FORMATTED_STANDARDS}

   **IMPORTANT**: When revising metadata, ensure it conforms to standard plan template structure (Date, Feature, Scope, Status, Standards File).
   ```

**Files to Modify**:
- `/home/benjamin/.config/.claude/commands/revise.md` (add Block 5a for standards extraction, modify Block 5b-exec Task prompt)

**Expected Outcome**: `/revise` command will update plans to conform to standard metadata structure during revision.

---

### 3. **HIGH - Create Metadata Normalization Migration Script**

**Priority**: High
**Effort**: Medium (4-6 hours)

**Rationale**: Existing plans created by `/repair` without standards will need migration to standard format.

**Implementation**:
1. Create script: `.claude/scripts/normalize-plan-metadata.sh`
2. Detect non-standard metadata fields (Plan ID, Created, Revised, Workflow Type)
3. Convert to standard fields:
   - Plan ID → (remove, use filename)
   - Created → Date (extract date portion)
   - Revised → (remove, use git history)
   - Workflow Type → (remove or map to Feature prefix)
   - Complexity (integer) → Estimated Hours (convert using 3h/complexity-level)
4. Add missing standard fields:
   - **Status**: [NOT STARTED] (or [COMPLETE] based on checkbox analysis)
   - **Standards File**: /home/benjamin/.config/CLAUDE.md
   - **Structure Level**: 0 (default for non-expanded plans)
5. Create backup before modification (`.backup_metadata_migration_{timestamp}`)

**Usage**:
```bash
bash .claude/scripts/normalize-plan-metadata.sh /path/to/plan.md
bash .claude/scripts/normalize-plan-metadata.sh --all  # Migrate all plans in specs/*/plans/
```

**Expected Outcome**: All existing plans will conform to standard metadata structure, enabling consistent processing by `/implement` and `/build` commands.

---

### 4. **MEDIUM - Add Pre-Commit Validation for Plan Metadata**

**Priority**: Medium
**Effort**: Low (1-2 hours)

**Rationale**: Prevent future creation of non-conforming plans.

**Implementation**:
1. Create validator: `.claude/scripts/validate-plan-metadata.sh`
2. Check for required fields:
   - Date (YYYY-MM-DD format)
   - Feature (non-empty)
   - Status ([NOT STARTED], [IN PROGRESS], [COMPLETE])
   - Standards File (absolute path exists)
3. Integrate with `validate-all-standards.sh`:
   ```bash
   bash .claude/scripts/validate-all-standards.sh --plan-metadata
   ```
4. Add to pre-commit hook for plan files

**Expected Outcome**: Git commits will be blocked if plans lack required metadata fields.

---

### 5. **LOW - Document Standards Integration Pattern**

**Priority**: Low
**Effort**: Low (1-2 hours)

**Rationale**: Ensure pattern is discoverable for future command development.

**Implementation**:
1. Create documentation: `.claude/docs/guides/patterns/standards-integration.md`
2. Document:
   - Purpose of standards extraction
   - How to source standards-extraction.sh library
   - How to format standards for agent prompts
   - Required "**Project Standards**:" section in Task prompts
   - Validation requirements for standards-compliant plans
3. Add cross-references to:
   - Command Authoring Standards
   - Plan-architect agent documentation
   - Hard Barrier Subagent Delegation Pattern

**Expected Outcome**: Future command authors will follow standards integration pattern consistently.

---

## References

### Primary Evidence Files

1. **Command Files**:
   - `/home/benjamin/.config/.claude/commands/plan.md` (lines 1146-1201) - Reference implementation with standards extraction
   - `/home/benjamin/.config/.claude/commands/repair.md` (lines 1045-1089) - Missing standards extraction
   - `/home/benjamin/.config/.claude/commands/revise.md` (lines 967-995) - Missing standards extraction

2. **Library Files**:
   - `/home/benjamin/.config/.claude/lib/plan/standards-extraction.sh` (complete file) - Standards extraction utilities

3. **Agent Files**:
   - `/home/benjamin/.config/.claude/agents/plan-architect.md` (lines 79-95, 884-891, 1153-1154, 1209) - Standards integration protocol and metadata template

4. **Plan Examples**:
   - `/home/benjamin/.config/.claude/specs/994_optimize_claude_command_refactor/plans/001-optimize-claude-refactor-plan.md` (lines 2-13) - Proper metadata
   - `/home/benjamin/.config/.claude/specs/004_todo_command_subagent_delegation/plans/001-todo-command-subagent-delegation-plan.md` (lines 2-8) - Proper metadata
   - `/home/benjamin/.config/.claude/specs/995_repair_todo_20251201_143930/plans/001-repair-todo-20251201-143930-plan.md` (lines 3-14) - Deficient metadata

5. **Standards Files**:
   - `/home/benjamin/.config/CLAUDE.md` - Project standards source document

### Line Number References

All line numbers verified via Read tool on 2025-12-01. File content may change; use line numbers as approximate reference points for locating relevant sections.
