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

### Report Application Mode (--apply-report)

#### What Gets Applied

The command parses the completed analysis report for:

1. **Filled Gap Markers**: `[FILL IN: ...]` sections with user decisions
2. **Reconciliation Choices**: User selections for handling discrepancies
3. **Standard Values**: Explicit values for indentation, naming, etc.

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