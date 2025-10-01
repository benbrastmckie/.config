---
allowed-tools: Read, Write, Edit, MultiEdit, Bash, Grep, Glob
argument-hint: [project-directory] [--analyze] [--apply-report <report-path>]
description: Setup or improve CLAUDE.md with smart extraction, standards analysis, and report-driven updates
command-type: primary
dependent-commands: validate-setup
---

# Setup Project Standards

I'll create or improve the CLAUDE.md file by intelligently organizing content - keeping it concise by extracting detailed sections into auxiliary files when appropriate.

## Command Modes

### 1. Standard Mode (default)
Generate or update CLAUDE.md with smart section extraction.

**Usage**: `/setup [project-directory]`

### 2. Analysis Mode
Analyze existing CLAUDE.md and codebase to identify discrepancies and gaps, generating a comprehensive analysis report.

**Usage**: `/setup --analyze [project-directory]`

**Features**:
- Discovers standards from three sources: CLAUDE.md, codebase patterns, configuration files
- Detects 5 types of discrepancies
- Identifies missing or incomplete sections
- Generates interactive gap-filling report in specs/reports/
- Never modifies files (safe exploration)

### 3. Report Application Mode
Parse a completed analysis report and update CLAUDE.md with reconciled standards.

**Usage**: `/setup --apply-report <report-path> [project-directory]`

**Features**:
- Parses completed `[FILL IN: ...]` sections from analysis reports
- Creates backup before modifying CLAUDE.md
- Updates standards based on user decisions
- Validates generated CLAUDE.md structure
- Suggests running /validate-setup

## Target Directory
$1 (or current directory)

## Argument Parsing

I'll detect the mode based on arguments:

### Standard Mode
- No flags: `/setup` or `/setup /path/to/project`
- Behavior: Generate or update CLAUDE.md with extraction workflow

### Analysis Mode
- `--analyze` flag present: `/setup --analyze` or `/setup --analyze /path/to/project`
- Arguments can be in any order: `/setup --analyze` or `/setup /path --analyze`
- Behavior: Run standards analysis, generate report, never modify CLAUDE.md

### Report Application Mode
- `--apply-report <path>` flag present: `/setup --apply-report specs/reports/NNN_report.md`
- Can include directory: `/setup --apply-report report.md /path/to/project`
- Arguments can be in any order
- Behavior: Parse report, backup CLAUDE.md, update with reconciled standards

### Implementation Logic
```
if "--apply-report" in arguments:
    report_path = argument after "--apply-report"
    project_dir = remaining non-flag argument or current directory
    run report_application_mode(report_path, project_dir)
elif "--analyze" in arguments:
    project_dir = remaining non-flag argument or current directory
    run analysis_mode(project_dir)
else:
    project_dir = $1 or current directory
    run standard_mode(project_dir)
```

## Standards for Commands

When creating or updating CLAUDE.md, I'll ensure it's optimized for discovery and use by other slash commands:

### Command Integration Requirements

#### Required Sections with Metadata
All generated CLAUDE.md files will include:

1. **Code Standards** section
   - `[Used by: /implement, /refactor, /plan]` metadata
   - Indentation, line length, naming conventions
   - Error handling patterns
   - Language-specific standards

2. **Testing Protocols** section
   - `[Used by: /test, /test-all, /implement]` metadata
   - Test commands and patterns
   - Coverage requirements
   - Test discovery rules

3. **Documentation Policy** section
   - `[Used by: /document, /plan]` metadata
   - README requirements
   - Documentation format guidelines
   - Character encoding rules

4. **Standards Discovery** section
   - `[Used by: all commands]` metadata
   - Discovery method explanation
   - Subdirectory inheritance rules
   - Fallback behavior

#### Section Format
Each section must follow the parseable schema:

```markdown
## Section Name
[Used by: /command1, /command2]

### Subsection
- **Field Name**: value
- **Another Field**: value
```

### Project Type Detection
I'll detect project type and generate appropriate standards:

- **Lua/Neovim**: 2-space indent, snake_case, pcall error handling, `:TestSuite`
- **JavaScript/Node**: 2-space indent, camelCase, try-catch, `npm test`
- **Python**: 4-space indent, snake_case, try-except, `pytest`
- **Shell**: 2-space indent, snake_case, `set -e`, shellcheck

### Validation
After generation, I'll validate that:
- All required sections exist
- Each section has `[Used by: ...]` metadata
- Field format is consistent (`**Field**: value`)
- Commands can parse the structure

## Process

### 1. Analyze Existing CLAUDE.md
I'll examine any existing CLAUDE.md to identify:
- Sections that are overly detailed (>30 lines)
- Inline standards that could be extracted
- Testing configurations embedded directly
- Long code examples or templates
- Content better suited for auxiliary files

### 2. Smart Section Extraction

For sections that would benefit from extraction, I'll offer to move them to dedicated files:

| Section Type | Suggested File | Extraction Trigger |
|-------------|---------------|-------------------|
| Testing Standards | `docs/TESTING.md` | >20 lines of test details |
| Code Style Guide | `docs/CODE_STYLE.md` | Detailed formatting rules |
| Documentation Guide | `docs/DOCUMENTATION.md` | Template examples |
| Command Reference | `docs/COMMANDS.md` | >10 commands |
| Architecture | `docs/ARCHITECTURE.md` | Complex diagrams |

### 3. Interactive Extraction Process

For each extractable section, I'll ask:

```
Found: Testing Standards (45 lines) in CLAUDE.md

Would you like to:
[E]xtract to docs/TESTING.md and link it
[K]eep in CLAUDE.md as-is
[S]implify in place without extraction
```

If you choose extraction, I'll:
1. Create the auxiliary file with the content
2. Replace the section in CLAUDE.md with a concise summary and link
3. Add navigation links between files

### 4. Optimal CLAUDE.md Structure

#### Goal: Command-Parseable Standards File
```markdown
# Project Configuration Index

This CLAUDE.md serves as the central configuration and standards index.

## Code Standards
[Used by: /implement, /refactor, /plan]

### General Principles
- **Indentation**: [detected or user-specified]
- **Line Length**: [detected or default]
- **Naming**: [language-appropriate conventions]
- **Error Handling**: [language-specific patterns]

## Testing Protocols
[Used by: /test, /test-all, /implement]

### Test Discovery
[How commands should find tests]

### [Project Type] Testing
- **Test Commands**: [detected test commands]
- **Test Pattern**: [detected test file patterns]
- **Coverage Requirements**: [suggested thresholds]

## Documentation Policy
[Used by: /document, /plan]

### README Requirements
[Standard requirements for documentation]

## Standards Discovery
[Used by: all commands]

### Discovery Method
[Standard discovery explanation]

## Specs Directory Protocol
[Kept inline - essential for spec workflow]
```

### 5. Decision Criteria

I'll recommend extraction when:
- Section is >30 lines of detailed content
- Content is reference material (not daily use)
- Multiple examples or templates present
- Complex configuration rarely changed

I'll keep inline when:
- Quick reference commands (<10 lines)
- Critical navigation/index information
- Specs protocol (core to Claude)
- Daily-use information

### 6. File Organization

```
project/
├── CLAUDE.md              # Concise index
├── docs/
│   ├── TESTING.md        # Extracted test details
│   ├── CODE_STYLE.md     # Extracted style guide
│   └── ...               # Other extracted sections
└── specs/
    ├── plans/
    ├── reports/
    └── summaries/
```

### 7. Benefits

**Concise CLAUDE.md:**
- Quick to scan and navigate
- Focuses on essential info
- Easy to maintain
- Clear hierarchy

**Auxiliary Files:**
- Detailed documentation without length constraints
- Topic-focused organization
- Better version control (smaller diffs)
- Can be referenced from multiple places

## Interactive Setup

I'll ask about your preferences:

1. **Extraction threshold**:
   - Aggressive (>20 lines)
   - Balanced (>30 lines)
   - Conservative (>50 lines)

2. **Directory structure**:
   - Use `docs/` for standards?
   - Preferred file naming?

3. **Content to prioritize for extraction**:
   - Testing details?
   - Code style rules?
   - Architecture diagrams?
   - Command references?

## Example Session

```
Analyzing CLAUDE.md... Found 248 lines.

Extraction opportunities:
1. Testing Standards (52 lines) → docs/TESTING.md
2. Code Style (38 lines) → docs/CODE_STYLE.md
3. Architecture Diagram (44 lines) → docs/ARCHITECTURE.md

After extraction: CLAUDE.md would be 95 lines (62% reduction)

Proceed with extractions? [Y/n/customize]
```

## Standards Analysis Workflow

### Analysis Mode (--analyze)

#### What Gets Analyzed

**Three Sources of Truth**:
1. **CLAUDE.md** (documented standards)
   - Parse all sections with `[Used by: ...]` metadata
   - Extract field values (indentation, naming, test commands, etc.)

2. **Codebase** (actual patterns)
   - **Indentation**: Detect spaces vs tabs, count spaces
   - **Naming**: Analyze variable/function naming conventions
   - **Line Length**: Measure common line lengths
   - **Test Patterns**: Find test file naming patterns
   - **Error Handling**: Detect pcall, try-catch, error handling patterns

3. **Configuration Files**
   - `.editorconfig`: Indentation, line length, charset
   - `package.json`: Scripts, lint config, test commands
   - `pyproject.toml`: Tool configuration
   - `stylua.toml`, `.prettierrc`, `.eslintrc`: Formatting rules
   - `Makefile`: Build and test targets

#### Discrepancy Types Detected

| Type | Description | Example | Priority |
|------|-------------|---------|----------|
| Type 1 | Documented but not followed | CLAUDE.md: 2 spaces, Code: 4 spaces | Critical |
| Type 2 | Followed but not documented | Code uses pcall, not in CLAUDE.md | High |
| Type 3 | Configuration mismatch | .editorconfig ≠ CLAUDE.md | High |
| Type 4 | Missing section | No Testing Protocols section | Medium |
| Type 5 | Incomplete section | Code Standards missing Error Handling | Medium |

#### Confidence Scoring

Pattern detection includes confidence scores:
- **High (>80%)**: Consistent across 80%+ of sampled files
- **Medium (50-80%)**: Majority pattern but some variation
- **Low (<50%)**: No clear consensus, manual review needed

#### Generated Report Structure

```markdown
# Standards Analysis Report

## Metadata
- Analysis Date, Scope, Files Analyzed

## Executive Summary
- X discrepancies found
- Y gaps identified
- Z recommendations

## Current State
### Documented Standards (CLAUDE.md)
[Parsed values]

### Actual Standards (Codebase)
[Detected patterns with confidence scores]

### Configuration Files
[Parsed config values]

## Discrepancy Analysis
### Type 1: Documented but Not Followed
[List of violations]

### Type 2: Followed but Not Documented
[Undocumented patterns]

### Type 3: Configuration Mismatches
[Config conflicts]

### Type 4: Missing Sections
[Required sections not present]

### Type 5: Incomplete Sections
[Sections with missing fields]

## Interactive Gap Filling
[FILL IN: Indentation]
Detected: 4 spaces (85% confidence)
CLAUDE.md: 2 spaces
.editorconfig: 4 spaces

Decision: _______________
Rationale: _______________

[FILL IN: Error Handling]
Detected: pcall usage in 92% of files
CLAUDE.md: Not documented

Decision: _______________
Rationale: _______________

## Recommendations
[Prioritized action items]

## Implementation Plan
[Steps to reconcile standards]
```

#### Discrepancy Detection Algorithms

For each detected discrepancy, I'll apply these algorithms:

**Type 1: Documented but Not Followed**
```
Algorithm:
1. Parse CLAUDE.md for standard values (e.g., "Indentation: 2 spaces")
2. Analyze codebase and detect actual patterns
3. Compare: If documented ≠ actual AND confidence > 50%
   → Report Type 1 discrepancy with priority = CRITICAL

Example:
  CLAUDE.md: "Indentation: 2 spaces"
  Detected: 4 spaces (85% confidence in 47/50 files)
  Result: Type 1 discrepancy (CRITICAL)
```

**Type 2: Followed but Not Documented**
```
Algorithm:
1. Detect consistent patterns in codebase (confidence > 70%)
2. Check if pattern is documented in CLAUDE.md
3. If pattern exists AND not documented
   → Report Type 2 discrepancy with priority = HIGH

Example:
  Detected: pcall() error handling (92% of error-prone operations)
  CLAUDE.md: No error handling field
  Result: Type 2 discrepancy (HIGH)
```

**Type 3: Configuration Mismatches**
```
Algorithm:
1. Parse configuration files for standards values
2. Parse CLAUDE.md for same standards
3. If config_value ≠ claude_md_value
   → Report Type 3 discrepancy with priority = HIGH

Example:
  .editorconfig: indent_size = 4
  CLAUDE.md: "Indentation: 2 spaces"
  Result: Type 3 discrepancy (HIGH)
```

**Type 4: Missing Sections**
```
Algorithm:
1. Define required sections: [Code Standards, Testing Protocols, Documentation Policy, Standards Discovery]
2. Parse CLAUDE.md to check which sections exist
3. For each missing required section
   → Report Type 4 gap with priority = MEDIUM

Example:
  Required: "Testing Protocols" section
  CLAUDE.md: Section not found
  Result: Type 4 gap (MEDIUM)
```

**Type 5: Incomplete Sections**
```
Algorithm:
1. Define required fields for each section:
   - Code Standards: Indentation, Line Length, Naming, Error Handling
   - Testing Protocols: Test Commands, Test Pattern, Coverage Requirements
2. Parse existing sections in CLAUDE.md
3. For each section, check if all required fields present
4. If field missing
   → Report Type 5 gap with priority = MEDIUM

Example:
  Section exists: "Code Standards"
  Fields present: Indentation, Naming
  Fields missing: Error Handling, Line Length
  Result: Type 5 gaps (MEDIUM) x2
```

#### Gap Identification and Mapping

For each identified gap, I'll suggest fill values from detected patterns:

```
Gap: Error Handling field missing in Code Standards
     ↓
Search codebase for error handling patterns
     ↓
Detected: pcall() in 45/48 Lua files (94% confidence)
     ↓
Suggested fill: "Error Handling: Use pcall for operations that might fail"
     ↓
Add to report with [FILL IN: Error Handling] marker
```

#### Prioritization Logic

Discrepancies and gaps are prioritized:

| Priority | Conditions | Example |
|----------|-----------|---------|
| CRITICAL | Type 1 AND confidence > 80% | Doc says 2 spaces, 90% of files use 4 |
| HIGH | Type 2 OR Type 3 | Undocumented pcall pattern OR config mismatch |
| MEDIUM | Type 4 OR Type 5 | Missing Testing Protocols section |
| LOW | Type 1 AND confidence < 50% | Weak pattern, manual review needed |

Report sections are ordered by priority (CRITICAL first).

#### Analysis Workflow

```
User runs: /setup --analyze
     ↓
1. Discover Standards
   - Parse CLAUDE.md
   - Analyze codebase patterns (sample representative files)
   - Parse configuration files
     ↓
2. Detect Discrepancies
   - Compare documented vs actual
   - Compare actual vs config
   - Identify missing/incomplete sections
     ↓
3. Generate Report
   - Format findings
   - Add [FILL IN: ...] markers for gaps
   - Include detected patterns to help decision
   - Save to specs/reports/NNN_standards_analysis_report.md
     ↓
4. User Reviews Report
   - Reads analysis
   - Fills in [FILL IN: ...] sections
   - Makes decisions on discrepancies
```

#### Report Generation Details

When generating the analysis report, I'll create a comprehensive document following this structure:

**1. Metadata Section**
```markdown
## Metadata
- **Analysis Date**: YYYY-MM-DD HH:MM:SS
- **Project Directory**: /path/to/project
- **CLAUDE.md Found**: Yes/No (path if found)
- **Files Analyzed**: N source files, M config files
- **Languages Detected**: Lua, Python, JavaScript, etc.
```

**2. Executive Summary**
```markdown
## Executive Summary

Analysis of project standards reveals:
- **Discrepancies**: X found (Y critical, Z high priority)
- **Missing Sections**: N required sections not present
- **Incomplete Fields**: M fields need completion
- **Overall Status**: [CRITICAL/NEEDS_ATTENTION/GOOD]

Key findings:
- Most critical: [Description of highest priority issue]
- Quick wins: [Easy fixes with high impact]
```

**3. Current State Section**

I'll generate three parallel comparisons:

```markdown
## Current State

### Documented Standards (CLAUDE.md)

**Code Standards**:
- Indentation: 2 spaces
- Naming: Not documented
- Line Length: ~100 characters
- Error Handling: Not documented

**Testing Protocols**:
- Section not found

### Actual Standards (Codebase)

**Code Patterns** (analyzed 47 files):
- Indentation: 4 spaces (85% confidence, 40/47 files)
- Naming: snake_case (78% confidence)
- Line Length: Average 87 chars, max observed 120
- Error Handling: pcall() used in 92% of error-prone operations

**Test Patterns** (analyzed 12 test files):
- Pattern: *_spec.lua (100%)
- Test commands: Detected vim-test usage

### Configuration Files

**.editorconfig**:
- indent_size = 4
- max_line_length = 100
- charset = utf-8

**stylua.toml**:
- indent_type = "Spaces"
- indent_width = 4
```

**4. Discrepancy Analysis**

For each discrepancy type, I'll list findings with priority:

```markdown
## Discrepancy Analysis

### Type 1: Documented but Not Followed [CRITICAL]

**Indentation Mismatch**
- **Documented**: 2 spaces (CLAUDE.md line 42)
- **Actual**: 4 spaces (85% confidence, 40/47 files)
- **Impact**: Code doesn't match documentation
- **Recommendation**: Update CLAUDE.md to match reality

### Type 2: Followed but Not Documented [HIGH]

**Error Handling Pattern**
- **Pattern**: pcall() usage (92% of error-prone operations)
- **Files**: nvim/lua/config/init.lua:25, nvim/lua/plugins/lazy.lua:18, [+12 more]
- **Not Documented**: Error Handling field missing in Code Standards
- **Recommendation**: Add "Error Handling: Use pcall for operations that might fail"

### Type 3: Configuration Mismatches [HIGH]

**Indentation: CLAUDE.md vs .editorconfig**
- **CLAUDE.md**: 2 spaces
- **.editorconfig**: 4 spaces
- **Actual codebase**: 4 spaces (matches config, not docs)
- **Recommendation**: Update CLAUDE.md to match .editorconfig

### Type 4: Missing Sections [MEDIUM]

**Testing Protocols**
- **Required**: Yes (used by /test, /test-all, /implement)
- **Present**: No
- **Recommendation**: Add Testing Protocols section with detected patterns

### Type 5: Incomplete Sections [MEDIUM]

**Code Standards - Missing Fields**
- **Section exists**: Yes (line 38-42)
- **Fields present**: Indentation, Line Length
- **Fields missing**: Naming conventions, Error Handling
- **Recommendation**: Complete section with detected patterns
```

**5. Gap Analysis**

Structured summary of what's missing:

```markdown
## Gap Analysis

### Critical Gaps (Require Immediate Attention)
1. Indentation discrepancy (documented ≠ actual)
2. Testing Protocols section completely missing

### High Priority Gaps (Should Address Soon)
1. Error handling pattern undocumented
2. Configuration file mismatch

### Medium Priority Gaps (Complete When Possible)
1. Naming conventions not documented
2. Documentation Policy section incomplete
```

**6. Interactive Gap Filling**

For each gap, I'll create a fill-in section with context:

```markdown
## Interactive Gap Filling

This section allows you to make decisions about how to reconcile discrepancies and fill gaps.

### [FILL IN: Indentation Standard]

**Context**:
- **CLAUDE.md currently says**: 2 spaces
- **Codebase actually uses**: 4 spaces (85% confidence, 40/47 files)
- **.editorconfig specifies**: indent_size = 4
- **Recommendation**: Update to 4 spaces (matches config and reality)

**Your Decision**: _______________
(Options: "4 spaces", "2 spaces", "keep mixed")

**Rationale**: _______________
(Why did you choose this? E.g., "Match existing codebase and config")

---

### [FILL IN: Error Handling]

**Context**:
- **Currently documented**: Not documented
- **Detected pattern**: pcall() used in 92% of error-prone operations
- **Example files**:
  - nvim/lua/config/init.lua:25: `local ok, err = pcall(require, 'config')`
  - nvim/lua/plugins/lazy.lua:18: `pcall(vim.cmd, 'colorscheme')`
- **Recommendation**: "Error Handling: Use pcall for operations that might fail"

**Your Decision**: _______________
(Suggested text or your own standard)

**Rationale**: _______________

---

### [FILL IN: Testing Protocols]

**Context**:
- **Currently documented**: Section not found
- **Detected patterns**:
  - Test files: *_spec.lua (12 files found)
  - Test framework: plenary.nvim (detected in test files)
  - Test runner: vim-test (detected in config)
- **Recommendation**: Add section with:
  ```
  ## Testing Protocols
  [Used by: /test, /test-all, /implement]

  ### Test Discovery
  - **Test Pattern**: *_spec.lua files
  - **Test Framework**: plenary.nvim
  - **Test Commands**: :TestNearest, :TestFile, :TestSuite
  ```

**Your Decision**: [Accept] / [Modify] / [Skip]

**If Modify, provide text**: _______________

**Rationale**: _______________
```

**7. Recommendations Section**

Prioritized action items:

```markdown
## Recommendations

### Immediate Actions (Critical Priority)
1. **Fix indentation documentation**: Update CLAUDE.md to specify 4 spaces (current: 2 spaces)
   - File: CLAUDE.md line 42
   - Change: "Indentation: 2 spaces" → "Indentation: 4 spaces"

### Short-term Actions (High Priority)
2. **Document error handling**: Add Error Handling field to Code Standards
   - Value: "Error Handling: Use pcall for operations that might fail"
3. **Resolve config mismatch**: Ensure CLAUDE.md and .editorconfig agree

### Medium-term Actions (Medium Priority)
4. **Add Testing Protocols section**: Use detected patterns from analysis
5. **Document naming conventions**: Add "Naming: snake_case" based on detection
```

**8. Implementation Plan**

Step-by-step guide:

```markdown
## Implementation Plan

### Option 1: Manual Update
1. Review this report and fill in all [FILL IN: ...] sections
2. Manually edit CLAUDE.md based on your decisions
3. Run /validate-setup to verify structure
4. Commit changes

### Option 2: Automated Update (Recommended)
1. Review this report
2. Fill in all [FILL IN: ...] sections with your decisions
3. Save this report
4. Run: `/setup --apply-report specs/reports/NNN_standards_analysis_report.md`
5. Review the backup and updated CLAUDE.md
6. Run /validate-setup to verify
7. Commit changes

### Verification Steps
- [ ] All critical discrepancies resolved
- [ ] Required sections present in CLAUDE.md
- [ ] Configuration files and CLAUDE.md agree
- [ ] /validate-setup passes
- [ ] Other commands can parse CLAUDE.md (/implement, /test, etc.)
```

**File Naming and Location**

Reports are saved with incremental numbering:

```
Discover existing reports: specs/reports/NNN_*.md
Find highest number: e.g., 034
New report number: 035
Filename: 035_standards_analysis_report.md
Full path: specs/reports/035_standards_analysis_report.md
```

If specs/reports/ doesn't exist, I'll create it automatically.

### Report Application Mode (--apply-report)

#### What Gets Applied

The command parses the completed analysis report for:

1. **Filled Gap Markers**: `[FILL IN: ...]` sections with user decisions
2. **Reconciliation Choices**: User selections for handling discrepancies
3. **Standard Values**: Explicit values for indentation, naming, etc.

#### Report Parsing Algorithm

**Step 1: Locate Gap Fill Sections**
```
Pattern: ### [FILL IN: <field_name>]
Extract:
  - Field name (e.g., "Indentation Standard", "Error Handling")
  - Context provided (detected values, recommendations)
  - User's decision (text after "Your Decision:")
  - User's rationale (text after "Rationale:")
```

**Step 2: Parse User Decisions**
```
For each [FILL IN: ...] section:
  1. Extract field name → map to CLAUDE.md section and field
     Examples:
       "Indentation Standard" → Code Standards section, Indentation field
       "Error Handling" → Code Standards section, Error Handling field
       "Testing Protocols" → New section to create

  2. Extract user decision:
     - If "Your Decision: 4 spaces" → value = "4 spaces"
     - If "Your Decision: _______________" (blank) → skip this gap
     - If "Your Decision: [Accept]" → use recommended value from context

  3. Extract rationale (for logging/documentation purposes)
```

**Step 3: Validate Parsed Decisions**
```
Check:
  - Critical gaps are filled (Type 1 discrepancies must be resolved)
  - Values are reasonable (not empty, match expected format)
  - Section references are valid

Warn if:
  - Some gaps unfilled (will skip those)
  - Values don't match detected patterns (user override, but flag it)
```

#### CLAUDE.md Update Strategy

**Backup Creation**
```
timestamp = current time in format: YYYYMMDD_HHMMSS
backup_path = "CLAUDE.md.backup.{timestamp}"
copy CLAUDE.md to backup_path
log: "Backup created: {backup_path}"
```

**Update Algorithm**

For each parsed decision:

**Case 1: Update Existing Field**
```
If field exists in CLAUDE.md:
  1. Locate field line (e.g., "- **Indentation**: 2 spaces")
  2. Extract old value
  3. Replace with new value from user decision
  4. Log: "Updated {section} - {field}: {old_value} → {new_value}"

Example:
  Old: "- **Indentation**: 2 spaces"
  Decision: "4 spaces"
  New: "- **Indentation**: 4 spaces"
```

**Case 2: Add Missing Field to Existing Section**
```
If section exists but field missing:
  1. Locate section end (next ## heading or EOF)
  2. Insert new field before section end
  3. Format: "- **{Field Name}**: {value}"
  4. Log: "Added {section} - {field}: {value}"

Example:
  Section: ## Code Standards
  Decision: Error Handling = "Use pcall for operations that might fail"
  Insert: "- **Error Handling**: Use pcall for operations that might fail"
```

**Case 3: Create New Section**
```
If section doesn't exist:
  1. Determine section position (follow standard order)
  2. Create section with proper heading
  3. Add [Used by: ...] metadata
  4. Add all fields for that section
  5. Log: "Created section: {section_name}"

Example:
  Decision: Add Testing Protocols
  Create:
    ## Testing Protocols
    [Used by: /test, /test-all, /implement]

    ### Test Discovery
    - **Test Pattern**: *_spec.lua
    - **Test Commands**: :TestNearest, :TestFile, :TestSuite
```

**Metadata Preservation**
```
For each section:
  - Preserve existing [Used by: ...] metadata
  - Add metadata if missing (based on standard schema)
  - Verify format: "[Used by: /command1, /command2]"
```

**Section Ordering**
```
Standard order (maintain when creating new sections):
1. Project Configuration Index (header)
2. Code Standards
3. Testing Protocols
4. Documentation Policy
5. Standards Discovery
6. Specs Directory Protocol
7. Project-specific sections
```

**Preserve Unaffected Content**
```
For sections not mentioned in report:
  - Keep exactly as-is
  - Don't reformat or modify
  - Preserve comments, extra content, custom sections
```

#### Validation Before Write

Before writing updated CLAUDE.md:

```
1. Parse generated CLAUDE.md to verify structure:
   - All required sections present
   - All sections have [Used by: ...] metadata
   - Field format is correct: "- **Field**: value"

2. Check that changes match user decisions:
   - Each filled gap resulted in update
   - No unexpected changes

3. Verify parseability:
   - Other commands can parse the structure
   - Sections are properly delimited
   - Markdown syntax is valid

If validation fails:
  - Don't write file
  - Report specific errors
  - Suggest manual review
  - Backup remains available
```

#### Application Process

```
User runs: /setup --apply-report specs/reports/NNN_report.md
     ↓
1. Parse Report
   - Extract all [FILL IN: ...] sections
   - Validate that critical gaps are filled
   - Parse user decisions
     ↓
2. Backup Existing CLAUDE.md
   - Create CLAUDE.md.backup.TIMESTAMP
   - Preserve original for rollback
     ↓
3. Generate/Update CLAUDE.md
   - Merge detected patterns with user decisions
   - Ensure all sections have [Used by: ...] metadata
   - Follow established schema
   - Preserve unaffected sections
     ↓
4. Validate Structure
   - Check parseability
   - Verify required sections present
   - Confirm metadata format
     ↓
5. Report Results
   - Summary of changes made
   - Backup location
   - Suggest: /validate-setup
```

#### Safety Features

- **Always Creates Backup**: Original CLAUDE.md preserved
- **Validation Before Write**: Checks structure before overwriting
- **Partial Application**: Skips unfilled gaps, applies only completed ones
- **Rollback Available**: Backup can be restored if needed

#### Example Application

```bash
# Generate analysis
/setup --analyze

# Edit the generated report
# Fill in [FILL IN: ...] sections

# Apply the completed report
/setup --apply-report specs/reports/034_standards_analysis_report.md

# Output:
# Backup created: CLAUDE.md.backup.20251001_143022
# Updated sections:
#   - Code Standards: Updated indentation (2 → 4 spaces)
#   - Code Standards: Added error handling (pcall)
#   - Testing Protocols: Updated test command
#
# Validation: Passed
#
# Suggested next step: /validate-setup
```

#### Edge Cases and Error Handling

**Case: No CLAUDE.md Exists**
```
Scenario: User runs --apply-report but no CLAUDE.md exists
Action:
  1. Create new CLAUDE.md from scratch
  2. Use report decisions to populate all sections
  3. Add all required sections with [Used by: ...] metadata
  4. No backup needed (nothing to back up)
  5. Log: "Created new CLAUDE.md from report"
```

**Case: Partially Filled Report**
```
Scenario: User filled in some gaps but not all
Action:
  1. Parse all [FILL IN: ...] sections
  2. Apply only filled sections
  3. Skip unfilled sections (leave CLAUDE.md unchanged for those)
  4. Log: "Applied 5 of 8 gaps (3 skipped - not filled in report)"
  5. List which gaps were skipped
```

**Case: Invalid User Decision**
```
Scenario: User entered invalid value (e.g., "Your Decision: ???")
Action:
  1. Detect invalid/unclear decision
  2. Skip that gap
  3. Warn: "Skipped {field}: decision unclear ('???')"
  4. Continue with other gaps
```

**Case: Conflicting Decisions**
```
Scenario: Report has contradictory decisions
Action:
  1. Detect conflict (e.g., two gaps both setting indentation differently)
  2. Use first encountered value
  3. Warn: "Conflict: {field} set twice. Using first value: {value}"
```

**Case: Report Not Found**
```
Scenario: User provides invalid report path
Action:
  1. Check if file exists
  2. If not: error "Report not found: {path}"
  3. Suggest: Check path or run /setup --analyze first
```

**Case: Report Format Invalid**
```
Scenario: Report doesn't have expected structure
Action:
  1. Attempt to parse
  2. If no [FILL IN: ...] sections found: error
  3. Suggest: Ensure report is from /setup --analyze
```

**Case: Backup Conflict**
```
Scenario: Backup file already exists (same timestamp)
Action:
  1. Append counter: CLAUDE.md.backup.{timestamp}.2
  2. Ensure no overwrite of existing backups
```

**Case: Validation Failure**
```
Scenario: Generated CLAUDE.md fails validation
Action:
  1. Don't write file
  2. Report specific validation errors
  3. Explain what's wrong (e.g., "Missing [Used by: ...] in Code Standards")
  4. Suggest: Review report or manual fix
  5. Keep backup available
```

**Case: Permission Error**
```
Scenario: Cannot write to CLAUDE.md (permissions)
Action:
  1. Error: "Cannot write to CLAUDE.md: permission denied"
  2. Suggest: Check file permissions
  3. Backup not affected
```

#### Rollback Procedure

If user wants to undo --apply-report:

```bash
# Find the backup
ls -lt CLAUDE.md.backup.*

# Restore from backup
cp CLAUDE.md.backup.20251001_143022 CLAUDE.md

# Verify restoration
/validate-setup
```

Or provide a rollback command:
```bash
/setup --rollback CLAUDE.md.backup.20251001_143022
```

### Complete Standards Lifecycle

```
1. /setup --analyze
   → Generates analysis report with gaps

2. User edits report
   → Fills [FILL IN: ...] sections

3. /setup --apply-report <report>
   → Updates CLAUDE.md from report

4. /validate-setup
   → Confirms standards are parseable

5. Other commands use updated standards
   → /implement, /test, /refactor, etc.
```

## Integration with Other Commands

### How /setup Supports Other Commands

This command creates the foundation that other commands rely on:

#### For /implement
- Generates **Code Standards** section with indentation, naming, error handling
- Creates **Testing Protocols** section with test commands
- Ensures standards are parseable for automatic application

#### For /test
- Generates **Testing Protocols** section with test commands and patterns
- Detects project test framework and configuration
- Documents test discovery rules

#### For /document
- Generates **Documentation Policy** section with README requirements
- Sets format guidelines and character encoding rules
- Defines navigation link patterns

#### For /plan
- Creates all standard sections for plan generation
- Documents project conventions for accurate planning
- Ensures plans can capture standards properly

#### For /refactor
- Generates comprehensive standards for validation
- Documents code quality thresholds
- Provides clear validation criteria

### Standards Generation Workflow

```
User runs: /setup
     ↓
/setup analyzes project:
  - Detects language (Lua, JS, Python, etc.)
  - Finds test framework
  - Identifies existing conventions
     ↓
Generates CLAUDE.md with:
  - Code Standards (with [Used by: ...] metadata)
  - Testing Protocols (with test commands)
  - Documentation Policy (with requirements)
  - Standards Discovery (with discovery rules)
     ↓
Validates parseability:
  - Checks all sections have metadata
  - Verifies field format consistency
  - Tests that commands can parse structure
     ↓
Result: CLAUDE.md optimized for command integration
```

### Example: Generated Standards

For a Lua/Neovim project, /setup would generate:

```markdown
## Code Standards
[Used by: /implement, /refactor, /plan]

### General Principles
- **Indentation**: 2 spaces, expandtab
- **Line Length**: ~100 characters (soft limit)
- **Naming**: snake_case for variables/functions, PascalCase for modules
- **Error Handling**: Use pcall for operations that might fail

## Testing Protocols
[Used by: /test, /test-all, /implement]

### Neovim Testing
- **Test Commands**: `:TestNearest`, `:TestFile`, `:TestSuite`, `:TestLast`
- **Test Pattern**: `*_spec.lua`, `test_*.lua`
- **Test Framework**: plenary.nvim, busted
```

These sections are immediately usable by /implement, /test, and other commands.

Let me analyze your project and help organize your CLAUDE.md efficiently.