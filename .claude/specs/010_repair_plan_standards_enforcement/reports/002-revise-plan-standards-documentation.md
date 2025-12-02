# Plan Revision: Standards Documentation Architecture

## Metadata
- **Date**: 2025-12-02
- **Agent**: research-specialist
- **Topic**: Plan revision insights for CLAUDE.md standards reference architecture
- **Report Type**: codebase analysis and best practices
- **Workflow**: revise

## Executive Summary

The current plan proposes creating a new `plan_metadata_standard` section in CLAUDE.md that defines all metadata fields, formats, and validation rules. However, analysis reveals CLAUDE.md already follows a "reference architecture" pattern where most sections link to comprehensive documentation in .claude/docs/ while providing only quick reference summaries. The plan should be revised to align with this existing pattern: create comprehensive plan-metadata-standard.md in .claude/docs/reference/standards/ and add a lightweight section to CLAUDE.md that references it with a quick summary. This revision maintains architectural consistency, improves discoverability through the standards directory structure, and allows detailed validation specifications without bloating CLAUDE.md.

## Findings

### 1. Current CLAUDE.md Architecture: Reference Hub Pattern

**Evidence from CLAUDE.md Structure Analysis**:

CLAUDE.md uses HTML comment markers to delimit named sections that can be extracted programmatically. The file contains 21 major sections (lines 43-366 in /home/benjamin/.config/CLAUDE.md).

**Pattern Analysis** (sample sections):

**Section: `code_standards` (lines 67-83)**:
```markdown
## Code Standards
[Used by: /implement, /refactor, /plan]

See [Code Standards](.claude/docs/reference/standards/code-standards.md) for complete coding conventions...

**Quick Reference - Bash Sourcing**:
- All bash blocks MUST follow three-tier sourcing pattern...
- See [Mandatory Bash Block Sourcing Pattern](.claude/docs/reference/standards/code-standards.md#mandatory-bash-block-sourcing-pattern)
```

**Section: `documentation_policy` (lines 300-344)**:
```markdown
## Documentation Policy
[Used by: /document, /plan]

### README Requirements

See [Documentation Standards](.claude/docs/reference/standards/documentation-standards.md) for complete README.md structure requirements...

**Directory Classification Quick Reference**:
- **Active Development** (commands/, agents/, lib/...): README.md required at all levels
- **Utility** (data/, backups/): Root README.md only
...
```

**Pattern Identified**: 18 of 21 sections follow reference architecture:
1. Section header with `[Used by: commands]` metadata
2. Opening line: "See [Full Document Title](path/to/doc.md) for complete..."
3. Quick Reference subsection with 3-7 bullet points
4. Links to full documentation for details

**Exceptions** (sections with embedded content):
- `directory_protocols` (lines 43-58): Embeds key concepts inline before linking to full doc
- `skills_architecture` (lines 227-259): Includes comparison table inline
- `documentation_policy` (lines 300-344): Has 3 subsections (README Requirements, Format, Updates, TODO.md) with mixed inline content

**File Location**: /home/benjamin/.config/CLAUDE.md (lines 43-366)

### 2. Standards Extraction Mechanism Uses Section Markers

**Evidence from standards-extraction.sh Analysis**:

The `extract_claude_section()` function (lines 79-123 in /home/benjamin/.config/.claude/lib/plan/standards-extraction.sh) uses awk to extract content between `<!-- SECTION: name -->` and `<!-- END_SECTION: name -->` markers.

**Extraction Pattern**:
```bash
# Pattern: <!-- SECTION: name --> ... <!-- END_SECTION: name -->
awk -v section="$section_name" '
  /<!-- SECTION:/ {
    if ($0 ~ "<!-- SECTION: " section " -->") {
      in_section = 1
      next
    }
  }
  /<!-- END_SECTION:/ {
    if (in_section && $0 ~ "<!-- END_SECTION: " section " -->") {
      in_section = 0
      exit
    }
  }
  in_section {
    print
  }
' "$claude_md"
```

**Planning Standards Extracted** (lines 148-179):
The `extract_planning_standards()` function extracts 6 specific sections:
1. `code_standards`
2. `testing_protocols`
3. `documentation_policy`
4. `error_logging`
5. `clean_break_development`
6. `directory_organization`

**Usage in Commands**: Commands source standards-extraction.sh and call `format_standards_for_prompt()` to inject standards into agent prompts. The extraction system works with ANY section name - it's designed for extensibility.

**File Location**: /home/benjamin/.config/.claude/lib/plan/standards-extraction.sh (lines 1-320)

### 3. Existing Standards Documentation Structure

**Evidence from .claude/docs/reference/standards/ Directory**:

```
/home/benjamin/.config/.claude/docs/reference/standards/
├── README.md (catalog of all standards)
├── code-standards.md (148 lines, comprehensive bash sourcing patterns)
├── documentation-standards.md (directory classification, templates)
├── testing-protocols.md (test discovery, coverage requirements)
├── output-formatting.md (suppression patterns, console summaries)
├── command-authoring.md (command development patterns)
├── enforcement-mechanisms.md (pre-commit hooks, validators)
├── todo-organization-standards.md (TODO.md structure)
├── clean-break-development.md (refactoring patterns)
├── adaptive-planning.md (complexity thresholds)
└── [13 more standards files...]
```

**Standards Directory Pattern**:
- Each standard has dedicated .md file in .claude/docs/reference/standards/
- README.md catalogs all standards with descriptions
- Standards documents are 50-300 lines with complete specifications
- CLAUDE.md sections reference these with quick summaries

**Discovery Mechanism**: Standards directory is well-known location; commands can reference standards by predictable paths.

**File Location**: /home/benjamin/.config/.claude/docs/reference/standards/ (18 files)

### 4. Current Plan Proposes Anti-Pattern: Embedded Standards Definition

**Evidence from Existing Plan Analysis**:

The plan's Phase 1 (lines 140-175 in /home/benjamin/.config/.claude/specs/010_repair_plan_standards_enforcement/plans/001-repair-plan-standards-enforcement-plan.md) proposes:

**Phase 1 Tasks**:
- "Create `plan_metadata_standard` section in CLAUDE.md using SECTION comment markers"
- "Document 6 required fields with format specifications and examples"
- "Document 4 optional fields with format specifications and use cases"
- "Define workflow-specific optional fields for /repair and /revise"
- "Specify metadata section placement"
- "Include format example with all required fields"

**Problem Identified**: This approach embeds complete standards specification in CLAUDE.md, contradicting the established reference architecture pattern where CLAUDE.md provides only quick summaries and links to comprehensive documentation.

**Consistency Issue**: If plan_metadata_standard contains full specifications, it becomes the ONLY standard defined inline in CLAUDE.md instead of in .claude/docs/reference/standards/. This breaks discoverability pattern and creates maintenance burden.

**File Location**: /home/benjamin/.config/.claude/specs/010_repair_plan_standards_enforcement/plans/001-repair-plan-standards-enforcement-plan.md (lines 140-175)

### 5. Phase 5 Documentation Already Anticipates Separate Standards File

**Evidence from Plan Documentation Requirements**:

Phase 5 tasks (lines 348-393 in plan) include:
- "Create /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md reference doc"
- "Document integration points: standards-extraction.sh, metadata-extraction.sh, validation hooks"

**Architectural Tension**: The plan creates BOTH:
1. Comprehensive standard in CLAUDE.md (Phase 1)
2. Reference documentation in .claude/docs/reference/standards/ (Phase 5)

This creates duplication - the same standard exists in two places with risk of divergence over time.

**Resolution Pattern**: Following established architecture, the comprehensive standard should ONLY exist in .claude/docs/reference/standards/plan-metadata-standard.md, with CLAUDE.md section providing quick reference + link.

**File Location**: /home/benjamin/.config/.claude/specs/010_repair_plan_standards_enforcement/plans/001-repair-plan-standards-enforcement-plan.md (lines 348-393)

### 6. Validation Script Integration Already Designed Correctly

**Evidence from Phase 3-4 Analysis**:

Phase 3 creates validate-plan-metadata.sh script (lines 217-282) that:
- Accepts plan file path as argument
- Extracts and validates ## Metadata section
- Validates required fields and formats
- Returns exit codes for pass/fail

Phase 4 integrates validation into:
- validate-all-standards.sh with --plans flag
- Pre-commit hooks for staged plan files

**Observation**: The validation infrastructure is correctly designed and does NOT depend on where the standard is documented. Validators reference the canonical standard through documentation links, not by parsing CLAUDE.md sections.

**File Location**: /home/benjamin/.config/.claude/specs/010_repair_plan_standards_enforcement/plans/001-repair-plan-standards-enforcement-plan.md (lines 217-309)

## Recommendations

### 1. Revise Phase 1: Create Comprehensive Standard in .claude/docs/reference/standards/

**Change from**: "Create `plan_metadata_standard` section in CLAUDE.md with complete field specifications"

**Change to**: "Create `/home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md` with complete specifications"

**Rationale**: Aligns with established standards architecture; provides single source of truth; improves discoverability through standards directory.

**Content Structure for plan-metadata-standard.md**:
```markdown
# Plan Metadata Standard

## Purpose
Defines canonical metadata structure for all plan files...

## Required Metadata Fields
1. **Date**: Format, examples, validation rules
2. **Feature**: Format, length limits, examples
3. **Status**: Enum values, bracket notation
4. **Estimated Hours**: Numeric range format
5. **Standards File**: Absolute path requirement
6. **Research Reports**: Relative path + markdown link format

## Optional Metadata Fields
7. **Scope**: Multi-line description (when to use)
8. **Complexity Score**: Calculation method
9. **Structure Level**: 0/1/2 tier definitions
10. **Estimated Phases**: Phase count before detailed planning

## Workflow-Specific Optional Fields
- /repair: Error Log Query, Errors Addressed
- /revise: Original Plan, Revision Reason
- /debug: Debug Context, Error Types

## Validation Rules
- Field presence validation (ERROR for missing required)
- Format validation (WARNING for format issues)
- Cross-field consistency (e.g., Structure Level matches directory structure)

## Integration Points
- standards-extraction.sh: How to extract this standard
- metadata-extraction.sh: Parsing library expectations
- validate-plan-metadata.sh: Validation script reference
- Pre-commit hooks: Enforcement mechanism

## Examples
[Complete metadata section examples for each workflow]
```

### 2. Add Lightweight CLAUDE.md Section Referencing Standard

**Add new section** (after `quick_reference` section, before `documentation_policy`):

```markdown
<!-- SECTION: plan_metadata_standard -->
## Plan Metadata Standard
[Used by: /plan, /repair, /revise, /debug, plan-architect]

See [Plan Metadata Standard](.claude/docs/reference/standards/plan-metadata-standard.md) for complete metadata field specifications, validation rules, and workflow-specific extensions.

**Required Fields Quick Reference**:
- **Date**: YYYY-MM-DD or YYYY-MM-DD (Revised)
- **Feature**: One-line description (50-100 chars)
- **Status**: [NOT STARTED], [IN PROGRESS], [COMPLETE], [BLOCKED]
- **Estimated Hours**: {low}-{high} hours
- **Standards File**: Absolute path to CLAUDE.md
- **Research Reports**: Markdown links with relative paths or "none"

**Enforcement**: Validated by pre-commit hooks (ERROR level for missing required fields).

See [Plan Metadata Standard](.claude/docs/reference/standards/plan-metadata-standard.md) for optional fields, workflow extensions, and validation specifications.
<!-- END_SECTION: plan_metadata_standard -->
```

**Rationale**: Maintains consistency with other CLAUDE.md sections; provides quick reference for developers; links to comprehensive documentation.

### 3. Update standards-extraction.sh to Include plan_metadata_standard

**Modify** `extract_planning_standards()` function (line 148-179) to add `plan_metadata_standard` to extracted sections array:

```bash
local sections=(
  "code_standards"
  "testing_protocols"
  "plan_metadata_standard"  # ADD THIS
  "documentation_policy"
  "error_logging"
  "clean_break_development"
  "directory_organization"
)
```

**Rationale**: Ensures plan-architect agent receives plan metadata standard in its prompt context automatically.

### 4. Eliminate Phase 1-5 Duplication

**Consolidate** Phase 1 and Phase 5 documentation tasks:
- Phase 1: Create .claude/docs/reference/standards/plan-metadata-standard.md (comprehensive)
- Phase 1 (continued): Add lightweight CLAUDE.md section (quick reference)
- Phase 5: Remove redundant documentation creation task

**Rationale**: Eliminates risk of documentation divergence; reduces implementation complexity; maintains single source of truth.

### 5. Update standards/README.md Catalog

**Add entry** to document inventory table (line 9-26 in /home/benjamin/.config/.claude/docs/reference/standards/README.md):

```markdown
| plan-metadata-standard.md | Required and optional metadata fields for plan files |
```

**Rationale**: Maintains discoverability through standards directory catalog; follows established pattern for new standards.

### 6. Consider Quick Reference Inline Content Preservation

**Analysis**: Some CLAUDE.md sections include inline content that provides immediate value without requiring navigation (e.g., `documentation_policy` includes directory classification quick reference with 5 categories).

**Recommendation**: For plan_metadata_standard, the 6 required fields list IS appropriate inline content because:
- Frequently referenced during plan creation
- Short enough to include without bloating CLAUDE.md
- High-value quick reference that reduces documentation navigation

**Guideline**: Quick reference should be 5-10 lines maximum; comprehensive specifications remain in standards file.

## References

### Files Analyzed

1. `/home/benjamin/.config/CLAUDE.md` (lines 43-366) - CLAUDE.md section structure and reference pattern
2. `/home/benjamin/.config/.claude/lib/plan/standards-extraction.sh` (lines 79-179) - Section extraction mechanism
3. `/home/benjamin/.config/.claude/docs/reference/standards/README.md` (lines 1-33) - Standards directory catalog
4. `/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md` (lines 1-150) - Example comprehensive standard
5. `/home/benjamin/.config/.claude/docs/reference/standards/documentation-standards.md` (lines 1-100) - Example comprehensive standard
6. `/home/benjamin/.config/.claude/specs/010_repair_plan_standards_enforcement/plans/001-repair-plan-standards-enforcement-plan.md` (lines 140-393) - Current plan proposing embedded standard
7. `/home/benjamin/.config/.claude/specs/010_repair_plan_standards_enforcement/reports/001-repair-plan-standards-analysis.md` (lines 1-100) - Research report identifying metadata divergence

### Key Findings Summary

- **18 of 21 CLAUDE.md sections** use reference architecture (link to comprehensive doc + quick summary)
- **Standards extraction system** is designed for extensibility; adding plan_metadata_standard requires only updating extracted sections array
- **Existing plan creates duplication** by embedding standard in CLAUDE.md (Phase 1) AND creating standards file (Phase 5)
- **Validation infrastructure** (Phase 3-4) is correctly designed and agnostic to standard location
- **Standards directory** follows predictable structure; new standard should use path: `.claude/docs/reference/standards/plan-metadata-standard.md`
