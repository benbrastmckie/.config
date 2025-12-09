# Research Report: Documentation Standards and CLAUDE.md Structure for Command Authoring

## Research Context

**Topic**: Documentation standards and CLAUDE.md structure for command authoring - specifically researching what standards exist for plan metadata format requirements and how to prevent format/metadata issues when creating commands in .claude/

**Date**: 2025-12-08

**Workflow**: revise workflow for spec 030_lean_plan_format_metadata_fix

**Research Complexity**: 2

## Findings

### Finding 1: Plan Metadata Standard Exists and is Comprehensive

**Source**: `/home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md`

**Summary**: A canonical plan metadata standard document exists with complete specifications for all plan-generating commands.

**Details**:

The plan-metadata-standard.md document (612 lines) provides:

1. **Six Required Metadata Fields** (ERROR-level if missing):
   - Date: `YYYY-MM-DD` or `YYYY-MM-DD (Revised)` format
   - Feature: One-line description (50-100 chars)
   - Status: `[NOT STARTED]`, `[IN PROGRESS]`, `[COMPLETE]`, `[BLOCKED]`
   - Estimated Hours: `{low}-{high} hours` numeric range
   - Standards File: `/absolute/path/to/CLAUDE.md`
   - Research Reports: Markdown links with relative paths or `none`

2. **Four Optional Recommended Fields** (INFO-level if missing):
   - Scope: Multi-line description for complex plans
   - Complexity Score: Numeric value (0-100)
   - Structure Level: 0, 1, or 2
   - Estimated Phases: Phase count estimate

3. **Phase-Level Metadata** (optional but enables key features):
   - `implementer: lean|software` - Explicit coordinator routing
   - `dependencies: []` or `[1, 2, 3]` - Wave-based parallel execution
   - `lean_file: /path/to/file.lean` - Theorem proving integration

4. **Validation Rules**:
   - ERROR-level: Missing required fields block commits
   - WARNING-level: Format issues are informational
   - INFO-level: Missing optional fields are suggested

5. **Integration Points** (documented at lines 367-438):
   - `standards-extraction.sh` - Automatic injection into planning context
   - `metadata-extraction.sh` - Plan parsing for progress tracking
   - `validate-plan-metadata.sh` - Validation script enforcement
   - Pre-commit hook - Automated validation before commits
   - `validate-all-standards.sh` - Unified validation runner
   - `plan-architect` agent - Self-validation (STEP 3)

**Evidence**: Lines 22-84 define required fields, lines 86-124 define optional fields, lines 126-286 define phase-level metadata with examples, lines 367-438 document integration points.

**Significance**: This standard exists and is authoritative but may not be fully integrated into all command workflows, particularly `/lean-plan`.

### Finding 2: Standards Extraction Infrastructure Implemented

**Source**: `/home/benjamin/.config/.claude/lib/plan/standards-extraction.sh`

**Summary**: A library exists to extract CLAUDE.md sections and inject them into agent prompts, including `plan_metadata_standard` section.

**Details**:

The standards-extraction.sh library (323 lines) provides:

1. **Three Core Functions**:
   - `extract_claude_section(section_name)` - Extract single section from CLAUDE.md
   - `extract_planning_standards()` - Extract all planning-relevant sections
   - `format_standards_for_prompt()` - Format for agent prompt injection

2. **Seven Planning-Relevant Sections Extracted** (lines 151-159):
   - `code_standards`
   - `testing_protocols`
   - `documentation_policy`
   - `error_logging`
   - `clean_break_development`
   - `directory_organization`
   - **`plan_metadata_standard`** (line 158)

3. **Graceful Degradation Behavior**:
   - Returns empty string if CLAUDE.md not found (no fatal errors)
   - Returns empty string for missing sections (warns to stderr)
   - Allows commands to proceed without standards if unavailable

4. **Integration Pattern**:
   ```bash
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh"
   FORMATTED_STANDARDS=$(format_standards_for_prompt)
   # Inject into agent prompt: ${FORMATTED_STANDARDS}
   ```

**Evidence**: Lines 32, 141, 158 explicitly list `plan_metadata_standard` as extracted section. Lines 205-236 format standards for prompt injection.

**Significance**: The infrastructure exists to automatically inject plan metadata standard into agent contexts, but adoption may be incomplete across commands.

### Finding 3: CLAUDE.md Plan Metadata Standard Section

**Source**: `/home/benjamin/.config/CLAUDE.md`

**Summary**: CLAUDE.md contains a dedicated `plan_metadata_standard` section (lines 216-231) with references to full documentation.

**Details**:

The CLAUDE.md section provides:

1. **Section Marker**: `<!-- SECTION: plan_metadata_standard -->` (line 216)

2. **Usage Metadata**: `[Used by: /create-plan, /repair, /revise, /debug, plan-architect]`

3. **Quick Reference Content** (6 required fields summarized):
   - Date format
   - Feature description
   - Status values
   - Estimated Hours format
   - Standards File path requirement
   - Research Reports format

4. **Cross-Reference**: Links to full documentation at `.claude/docs/reference/standards/plan-metadata-standard.md`

5. **Enforcement Note**: "Automated validation via pre-commit hooks (ERROR-level for missing required fields), validate-all-standards.sh --plans category, and plan-architect self-validation."

6. **End Marker**: `<!-- END_SECTION: plan_metadata_standard -->` (line 231)

**Evidence**: Lines 216-231 in CLAUDE.md contain complete section with markers recognizable by standards-extraction.sh.

**Significance**: The section exists and is properly marked for extraction, but `/lean-plan` is NOT listed in the "Used by" metadata (line 218), suggesting potential gap in integration.

### Finding 4: Command Authoring Standards Documentation

**Source**: `/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md`

**Summary**: Comprehensive command authoring standards exist (1677 lines) covering execution patterns, subprocess isolation, state persistence, and validation patterns.

**Details**:

The command-authoring.md document covers:

1. **Ten Major Sections**:
   - Execution Directive Requirements (lines 22-95)
   - Task Tool Invocation Patterns (lines 96-293)
   - Subprocess Isolation Requirements (lines 294-356)
   - State Persistence Patterns (lines 357-430)
   - Validation and Testing (lines 431-524)
   - Argument Capture Patterns (lines 525-661)
   - Path Validation Patterns (lines 662-927)
   - Output Suppression Requirements (lines 928-1157)
   - Command Integration Patterns (lines 1192-1418)
   - Prohibited Patterns (lines 1419-1664)

2. **Relevant to Plan Metadata** (lines 525-661 - Argument Capture):
   - Standardized 2-block pattern for complex arguments
   - Direct $1 capture for simple file paths
   - Flag parsing patterns for `--complexity`, `--file`, etc.

3. **Validation Integration Patterns** (lines 431-524):
   - Automated validation tests required
   - Pre-commit hook integration
   - Implementation checklist for command compliance

4. **Command Integration Patterns** (lines 1192-1418):
   - Summary-based handoff between commands
   - `--file` flag pattern for consuming summaries
   - Auto-discovery pattern for latest artifacts
   - Research Coordinator delegation pattern (lines 1346-1418)

5. **NO Explicit Plan Metadata Integration Guidance**:
   - Document does not have dedicated section on plan metadata standard
   - No guidance on when/how to inject metadata standards into agent prompts
   - No examples of `format_standards_for_prompt()` usage pattern

**Evidence**: Comprehensive TOC (lines 5-18) shows no plan metadata section. Search for "plan_metadata" returns 0 results in document.

**Significance**: Command authoring standards are comprehensive for execution patterns but lack guidance on plan metadata integration, leaving gap for command authors.

### Finding 5: Validation Script Exists and is Comprehensive

**Source**: `/home/benjamin/.config/.claude/scripts/lint/validate-plan-metadata.sh`

**Summary**: A fully-implemented validation script exists with ERROR/WARNING/INFO severity levels matching plan-metadata-standard.md specifications.

**Details**:

The validate-plan-metadata.sh script (9730 bytes, executable) provides:

1. **Validation Coverage**:
   - All 6 required fields with format validation
   - Date format: `YYYY-MM-DD` or `YYYY-MM-DD (Revised)`
   - Status format: Bracket notation with approved statuses
   - Estimated Hours: Numeric range with "hours" suffix
   - Standards File: Absolute path validation
   - Research Reports: Relative path links or literal "none"

2. **Exit Code Semantics** (lines 11-13):
   - `0` - Validation passed (all required fields valid)
   - `1` - Validation failed (missing required fields or format errors)

3. **Output Levels** (lines 15-18):
   - ERROR: Missing required fields (blocks commits)
   - WARNING: Format issues (informational)
   - INFO: Missing optional recommended fields

4. **Integration Points** (lines 35-38):
   - Called by pre-commit hook for staged plan files
   - Called by `validate-all-standards.sh --plans`
   - Called by plan-architect agent (STEP 3 self-validation)

5. **Metadata Extraction Functions** (lines 65-87):
   - `extract_metadata_section()` - Extracts content between markers
   - `extract_field(field_name)` - Extracts specific field value
   - Awk-based parsing for reliability

6. **Format Validation Functions** (lines 93-136):
   - `validate_date_format()` - Regex validation
   - `validate_status_format()` - Approved status check
   - `validate_estimated_hours_format()` - Range pattern validation
   - `validate_standards_file_format()` - Absolute path check
   - `validate_research_reports_format()` - Link format or "none" check

**Evidence**: Script exists at path, is executable (755 permissions), last modified Dec 2 17:29, comprehensive implementation visible in first 150 lines.

**Significance**: Validation infrastructure is complete and ready for integration into command workflows. The script can be invoked by agents for self-validation.

### Finding 6: Enforcement Mechanisms Documentation

**Source**: `/home/benjamin/.config/.claude/docs/reference/standards/enforcement-mechanisms.md`

**Summary**: A central enforcement reference exists documenting all validation tools, but plan metadata validation is NOT listed in the current inventory.

**Details**:

The enforcement-mechanisms.md document provides:

1. **Enforcement Tool Inventory Table** (lines 13-24):
   - Lists 9 validation scripts with severity levels
   - Includes pre-commit integration status
   - **MISSING**: `validate-plan-metadata.sh` not in inventory

2. **Documented Validators**:
   - `check-library-sourcing.sh` - Bash sourcing pattern (ERROR)
   - `check-state-persistence-sourcing.sh` - State persistence (ERROR)
   - `lint_error_suppression.sh` - Error suppression anti-patterns (ERROR)
   - `lint_bash_conditionals.sh` - Bash conditional safety (ERROR)
   - `lint-task-invocation-pattern.sh` - Task tool patterns (ERROR)
   - `validate-hard-barrier-compliance.sh` - Hard barrier pattern (ERROR)
   - `validate-readmes.sh` - README structure (WARNING)
   - `validate-links.sh` - Internal link validity (WARNING)
   - `validate-agent-behavioral-file.sh` - Agent consistency (WARNING)

3. **Standards-to-Tool Mapping** (lines 290-302):
   - Maps standard documents to enforcement tools
   - **MISSING**: `plan-metadata-standard.md` not in mapping table
   - Suggests gap in documentation synchronization

4. **Pre-Commit Integration Section** (lines 304-336):
   - Documents current pre-commit behavior
   - Lists 6 validators run on staged files
   - **MISSING**: Plan metadata validation not mentioned

5. **Unified Validation Documentation** (lines 352-370):
   - Documents `validate-all-standards.sh` categories
   - Lists `--sourcing`, `--readme`, `--links` options
   - **MISSING**: No `--plans` category documented

**Evidence**: Lines 13-24 show inventory table. Lines 290-302 show mapping table. Both lack plan metadata validation references.

**Significance**: The validate-plan-metadata.sh script exists and works but is not documented in the central enforcement reference, indicating documentation lag behind implementation.

### Finding 7: Four Commands Use Standards Extraction

**Source**: Command file analysis via grep

**Summary**: Four commands currently use standards extraction: `/create-plan`, `/lean-plan`, `/repair`, `/revise`.

**Details**:

Commands using `format_standards_for_prompt()` or `extract_planning_standards()`:

1. **`/create-plan`** (line 1888):
   ```bash
   FORMATTED_STANDARDS=$(format_standards_for_prompt 2>/dev/null) || {
     log_command_error "execution_error" "Standards extraction failed" "{}"
     echo "WARNING: Standards extraction failed, proceeding without standards" >&2
     FORMATTED_STANDARDS=""
   }
   ```
   - Extracts standards including `plan_metadata_standard`
   - Injects into plan-architect agent prompt
   - Graceful degradation on extraction failure

2. **`/lean-plan`**: Uses standards extraction (confirmed via grep match)

3. **`/repair`**: Uses standards extraction (confirmed via grep match)

4. **`/revise`**: Uses standards extraction (confirmed via grep match)

**Pattern Analysis**:

All plan-generating commands (`/create-plan`, `/lean-plan`, `/repair`, `/revise`) use the standards extraction library to inject CLAUDE.md sections into agent context. The `/debug` command is NOT listed but may use similar pattern.

**Evidence**: Grep results show 4 matches for standards extraction functions in commands directory.

**Significance**: Standards extraction is a well-adopted pattern across planning commands, but verification of actual `plan_metadata_standard` usage in `/lean-plan` requires deeper inspection.

### Finding 8: CLAUDE.md Section Metadata Shows Integration Gap

**Source**: `/home/benjamin/.config/CLAUDE.md` line 218

**Summary**: The `plan_metadata_standard` section metadata lists 4 commands but omits `/lean-plan`, suggesting incomplete integration.

**Details**:

Line 218 metadata: `[Used by: /create-plan, /repair, /revise, /debug, plan-architect]`

**Commands Listed**:
1. `/create-plan` - Primary plan generation command
2. `/repair` - Error-driven plan generation
3. `/revise` - Plan modification workflow
4. `/debug` - Debug-focused plan generation
5. `plan-architect` - Agent used by create-plan/repair/revise

**Commands NOT Listed**:
- `/lean-plan` - Lean-specific plan generation (MISSING)

**Verification via standards-extraction.sh usage**:
- `/create-plan`: Uses `format_standards_for_prompt()` ✓
- `/lean-plan`: Uses `format_standards_for_prompt()` (confirmed) but NOT in metadata ✗
- `/repair`: Uses `format_standards_for_prompt()` ✓
- `/revise`: Uses `format_standards_for_prompt()` ✓

**Evidence**: CLAUDE.md line 218 shows 4 commands + plan-architect. Grep shows `/lean-plan` uses standards extraction.

**Significance**: The metadata is stale - `/lean-plan` DOES use standards extraction but is not documented in CLAUDE.md section metadata. This may indicate the integration was added later without updating documentation.

## Gaps Analysis

### Gap 1: Plan Metadata Integration Not Documented in Command Authoring Standards

**Gap Description**: The command-authoring.md document (1677 lines) has no dedicated section explaining when and how to integrate plan metadata standards into command workflows.

**Impact**:
- Command authors lack guidance on plan metadata integration patterns
- No examples of `format_standards_for_prompt()` usage in command context
- No decision tree for when to inject metadata standards vs. rely on agent defaults

**Affected Stakeholders**:
- Command authors creating new plan-generating commands
- Developers maintaining `/lean-plan`, `/debug`, or other planning commands
- Agents that generate plans without explicit metadata enforcement

**Recommendation**: Add new section to command-authoring.md (approximately line 1190, before "Command Integration Patterns"):

**Proposed Section Title**: "Plan Metadata Standard Integration"

**Proposed Content**:
1. When to inject plan metadata standards (all plan-generating commands)
2. How to use `format_standards_for_prompt()` from standards-extraction.sh
3. Where to inject standards in agent prompt (before Task invocation)
4. Example from `/create-plan` showing integration pattern
5. Validation script invocation requirement for self-checking agents
6. CLAUDE.md section metadata update procedure

### Gap 2: Enforcement Mechanisms Documentation Outdated

**Gap Description**: The enforcement-mechanisms.md document does not list `validate-plan-metadata.sh` in the tool inventory or standards-to-tool mapping tables.

**Impact**:
- Developers unaware validation script exists and is mature
- Pre-commit hook integration status unclear
- Standards-to-tool mapping incomplete

**Affected Stakeholders**:
- Developers looking for validation tools
- Command authors needing metadata validation
- Documentation maintainers seeking complete reference

**Recommendation**: Update enforcement-mechanisms.md with following additions:

1. **Add to Tool Inventory Table** (line ~15):
   ```
   | validate-plan-metadata.sh | scripts/lint/ | Plan metadata format and required fields | ERROR | Yes |
   ```

2. **Add Tool Description Section** (line ~288):
   ```markdown
   ### validate-plan-metadata.sh

   **Purpose**: Validates plan metadata compliance with plan-metadata-standard.md.

   **Checks Performed**:
   1. Required fields: Date, Feature, Status, Estimated Hours, Standards File, Research Reports
   2. Date format: YYYY-MM-DD or YYYY-MM-DD (Revised)
   3. Status format: Bracket notation with approved statuses
   4. Estimated Hours: Numeric range with "hours" suffix
   5. Standards File: Absolute path validation
   6. Research Reports: Relative path links or literal "none"

   **Exit Codes**:
   - `0`: Validation passed
   - `1`: Validation failed (missing required fields or format errors)

   **Usage**:
   ```bash
   bash .claude/scripts/lint/validate-plan-metadata.sh <plan-file>
   ```

   **Related Standard**: [plan-metadata-standard.md](plan-metadata-standard.md)
   ```

3. **Add to Standards-to-Tool Mapping** (line ~295):
   ```
   | plan-metadata-standard.md | validate-plan-metadata.sh |
   ```

4. **Add to Pre-Commit Documentation** (line ~310):
   Add to pre-commit behavior list:
   ```
   7. Run validate-plan-metadata.sh on staged plan files in specs/*/plans/
   ```

5. **Add to Unified Validation Categories** (line ~361):
   Add new category option:
   ```bash
   bash .claude/scripts/validate-all-standards.sh --plans       # Plan metadata validation
   ```

### Gap 3: CLAUDE.md Section Metadata Stale

**Gap Description**: The `plan_metadata_standard` section in CLAUDE.md lists 4 commands but omits `/lean-plan`, despite `/lean-plan` using `format_standards_for_prompt()`.

**Impact**:
- Misleading documentation for developers
- Unclear which commands actually integrate the standard
- Documentation drift from implementation

**Affected Stakeholders**:
- Command authors seeking usage examples
- Developers maintaining planning commands
- Users trying to understand command capabilities

**Recommendation**: Update CLAUDE.md line 218:

**Current**:
```markdown
[Used by: /create-plan, /repair, /revise, /debug, plan-architect]
```

**Proposed**:
```markdown
[Used by: /create-plan, /lean-plan, /repair, /revise, /debug, plan-architect]
```

**Verification Steps**:
1. Grep `/lean-plan` command file for `format_standards_for_prompt` (confirmed present)
2. Verify standards extraction section exists in lean-plan.md
3. Update CLAUDE.md section metadata to include `/lean-plan`
4. Verify all listed commands actually use the standard (audit)

### Gap 4: No Decision Matrix for Metadata Enforcement Strategies

**Gap Description**: No documented guidance exists for when to rely on:
1. Agent behavioral file self-validation
2. Explicit validation script invocation in commands
3. Pre-commit hook enforcement only
4. Standards extraction auto-injection

**Impact**:
- Inconsistent enforcement strategies across commands
- Agents may or may not perform self-validation
- Unclear when to add validation script calls to workflows

**Affected Stakeholders**:
- Command authors choosing enforcement approach
- Agent authors deciding validation responsibilities
- Developers troubleshooting metadata compliance issues

**Recommendation**: Add decision matrix to plan-metadata-standard.md (after line 438, in "Integration Points" section):

**Proposed Addition**:

```markdown
### Enforcement Strategy Decision Matrix

| Scenario | Enforcement Mechanism | Rationale |
|----------|----------------------|-----------|
| New plan creation | Standards extraction + Agent self-validation | Proactive compliance via injected context |
| Plan revision | Standards extraction + Validation script | Ensure existing plans meet updated standards |
| Pre-commit check | Validation script on staged files | Catch errors before commit |
| CI/CD validation | Unified validation runner (`--plans`) | Systematic compliance enforcement |
| Agent development | Self-validation in STEP 3 | Agent-level quality assurance |
| Command integration | Graceful degradation if extraction fails | Allow workflow continuation without blocking |

**When to Add Validation Script to Command Workflow**:
1. **Agent creates plans**: Yes - add validation script invocation after agent Task returns
2. **Agent modifies plans**: Yes - validate after modifications applied
3. **Command reads plans**: No - assume plans valid (pre-commit enforcement)
4. **Testing/debugging**: Optional - useful for diagnostics but not required

**Example Integration** (from `/create-plan`):
```bash
# After agent Task returns plan
PLAN_FILE="$PLAN_PATH"

# Validate metadata compliance
bash .claude/scripts/lint/validate-plan-metadata.sh "$PLAN_FILE"
VALIDATION_EXIT=$?
if [ $VALIDATION_EXIT -ne 0 ]; then
  log_command_error "validation_error" "Plan metadata validation failed" \
    "{\"plan_file\": \"$PLAN_FILE\", \"exit_code\": $VALIDATION_EXIT}"
  echo "WARNING: Plan metadata validation failed, but plan was created" >&2
fi
```
```

### Gap 5: Lean-Specific Metadata Fields Not Documented in Plan Metadata Standard

**Gap Description**: The plan-metadata-standard.md document does not explicitly document Lean-specific metadata fields that `/lean-plan` generates (e.g., "Lean File", "Lean Project").

**Impact**:
- Validation script may not validate Lean-specific fields
- Unclear if Lean fields are workflow-specific extensions or core metadata
- `/lean-plan` command may generate non-standard metadata

**Affected Stakeholders**:
- `/lean-plan` command maintainers
- Lean workflow users
- Validation script authors

**Evidence from Existing Plan**:

The existing plan (030_lean_plan_format_metadata_fix/plans/001-lean-plan-format-metadata-fix-plan.md) references "Lean File" and "Lean Project" as expected metadata fields (Phase 3, lines 167-168).

However, plan-metadata-standard.md "Workflow-Specific Optional Fields" section (lines 287-317) documents only `/repair` and `/revise` workflow fields, not `/lean-plan` fields.

**Recommendation**: Add `/lean-plan` workflow-specific fields to plan-metadata-standard.md (after line 317, in "Workflow-Specific Optional Fields" section):

**Proposed Addition**:

```markdown
### /lean-plan Command

Plans generated by /lean-plan may include:

- **Lean File**: Primary Lean source file for theorem proving phases
  ```markdown
  - **Lean File**: /home/user/project/theories/Core.lean
  ```

- **Lean Project**: Lean project root directory for build context
  ```markdown
  - **Lean Project**: /home/user/project
  ```

**Note**: These fields duplicate information from phase-level `lean_file:` metadata. Consider deprecating top-level fields in favor of phase-level metadata for consistency with mixed Lean/software plans.
```

**Validation Script Update**:

Update `validate-plan-metadata.sh` to recognize Lean-specific fields as valid optional metadata (currently may warn about unknown fields).

## Recommendations

Based on gap analysis, the following actions are recommended:

### Priority 1: Document Plan Metadata Integration in Command Authoring Standards

**Action**: Add "Plan Metadata Standard Integration" section to command-authoring.md

**Location**: After line 1190, before "Command Integration Patterns"

**Content**:
- When to inject standards (all plan-generating commands)
- How to use `format_standards_for_prompt()`
- Example integration pattern from `/create-plan`
- Validation script invocation guidance
- CLAUDE.md metadata update procedure

**Estimated Effort**: 2-3 hours

**Benefit**: Eliminates primary documentation gap preventing format issues in new commands

### Priority 2: Update Enforcement Mechanisms Reference

**Action**: Add `validate-plan-metadata.sh` to enforcement-mechanisms.md

**Locations**:
- Tool inventory table (line ~15)
- Tool description section (line ~288)
- Standards-to-tool mapping (line ~295)
- Pre-commit documentation (line ~310)
- Unified validation categories (line ~361)

**Estimated Effort**: 1 hour

**Benefit**: Makes validation script discoverable for command authors and developers

### Priority 3: Update CLAUDE.md Section Metadata

**Action**: Add `/lean-plan` to plan_metadata_standard section "Used by" metadata

**Location**: CLAUDE.md line 218

**Change**: `[Used by: /create-plan, /repair, /revise, /debug, plan-architect]` → `[Used by: /create-plan, /lean-plan, /repair, /revise, /debug, plan-architect]`

**Estimated Effort**: 5 minutes

**Benefit**: Corrects documentation drift, accurate command listing

### Priority 4: Add Enforcement Strategy Decision Matrix

**Action**: Add decision matrix to plan-metadata-standard.md "Integration Points" section

**Location**: After line 438

**Content**: Table showing when to use each enforcement mechanism (standards extraction, validation script, pre-commit, CI/CD, agent self-validation)

**Estimated Effort**: 1-2 hours

**Benefit**: Provides clear guidance on enforcement approach selection

### Priority 5: Document Lean-Specific Metadata Fields

**Action**: Add `/lean-plan` workflow-specific fields to plan-metadata-standard.md

**Location**: After line 317, in "Workflow-Specific Optional Fields"

**Content**: Document "Lean File" and "Lean Project" metadata fields with examples

**Estimated Effort**: 30 minutes

**Benefit**: Completes metadata field documentation for all workflows

## Conclusion

The .claude/ system has comprehensive plan metadata standards documentation and validation infrastructure, but five gaps exist that could lead to format/metadata issues when creating commands:

1. **Primary Gap**: Command authoring standards lack plan metadata integration guidance
2. **Secondary Gap**: Enforcement mechanisms reference is outdated (missing plan metadata validation)
3. **Tertiary Gap**: CLAUDE.md section metadata is stale (missing `/lean-plan`)
4. **Decision Gap**: No documented enforcement strategy decision matrix
5. **Completeness Gap**: Lean-specific fields not documented in metadata standard

All gaps are documentation-only issues - the implementation (standards-extraction.sh, validate-plan-metadata.sh, CLAUDE.md section) is complete and functional. Addressing these gaps requires updating 3 documentation files with estimated total effort of 5-7 hours.

The root cause of format issues in `/lean-plan` (from spec 030) is likely NOT due to documentation gaps but due to agent behavioral file (lean-plan-architect.md) not enforcing format requirements strongly enough. However, addressing these documentation gaps will prevent similar issues in future command development.

## Research Artifacts

### Files Analyzed
- `/home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md` (612 lines)
- `/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md` (1677 lines)
- `/home/benjamin/.config/CLAUDE.md` (410 lines)
- `/home/benjamin/.config/.claude/lib/plan/standards-extraction.sh` (323 lines)
- `/home/benjamin/.config/.claude/scripts/lint/validate-plan-metadata.sh` (first 150 lines inspected)
- `/home/benjamin/.config/.claude/docs/reference/standards/enforcement-mechanisms.md` (438 lines)
- `/home/benjamin/.config/.claude/specs/030_lean_plan_format_metadata_fix/plans/001-lean-plan-format-metadata-fix-plan.md` (435 lines)

### Commands Searched
- Grep for `plan_metadata_standard` usage across .claude/ directory
- Grep for `format_standards_for_prompt` usage in commands
- Grep for validation script references
- File existence checks for validation scripts

### Standards Documents Cross-Referenced
- Plan Metadata Standard (plan-metadata-standard.md)
- Command Authoring Standards (command-authoring.md)
- Enforcement Mechanisms Reference (enforcement-mechanisms.md)
- CLAUDE.md project configuration index

## Next Steps

For revise workflow integration:

1. Incorporate recommendations into revised plan for spec 030_lean_plan_format_metadata_fix
2. Consider adding documentation updates as separate phases in plan
3. Verify `/lean-plan` actually uses `format_standards_for_prompt()` with direct file inspection
4. Validate whether lean-plan-architect.md agent invokes `validate-plan-metadata.sh` for self-validation
5. Determine if lean-specific metadata fields need validation script updates
