---
allowed-tools: Read, Write, Edit, MultiEdit, Bash, Grep, Glob, SlashCommand
argument-hint: [project-directory] [--cleanup [--dry-run]] [--validate] [--analyze] [--apply-report <report-path>] [--enhance-with-docs]
description: Setup or improve CLAUDE.md with smart extraction, cleanup optimization, validation, standards analysis, report-driven updates, and automatic documentation enhancement
command-type: primary
dependent-commands: orchestrate
---

# Setup Project Standards

I'll create or improve the CLAUDE.md file by intelligently organizing content - keeping it concise by extracting detailed sections into auxiliary files when appropriate.

## Shared Utilities Integration

This command uses shared utility libraries for robust operation:
- **Error Handling**: Uses `.claude/lib/error-handling.sh` for validation error handling and recovery
- File existence checks, permission validation, and graceful error reporting
- Ensures setup operations can be safely retried after failures

## Command Modes

### 1. Standard Mode (default)
Generate or update CLAUDE.md with smart section extraction. Automatically detects bloated CLAUDE.md and offers cleanup.

**Usage**: `/setup [project-directory]`

**Auto-Detection**:
- Analyzes existing CLAUDE.md size and structure
- If CLAUDE.md >200 lines OR has sections >30 lines:
  - Prompts: "CLAUDE.md is 248 lines. Optimize first? [Y/n/c]"
  - [Y]es: Run cleanup extraction before setup
  - [N]o: Skip cleanup, continue with standard setup
  - [C]ustomize: Choose specific sections to extract
- Seamlessly integrates cleanup into setup workflow

### 2. Cleanup Mode
Optimize CLAUDE.md by extracting detailed sections to auxiliary files, keeping the main file concise and focused.

**Usage**:
- Standard: `/setup --cleanup [project-directory]`
- Preview: `/setup --cleanup --dry-run [project-directory]`

**Features**:
- Analyzes CLAUDE.md for bloat (>30 line sections)
- Identifies extraction candidates (testing details, style guides, architecture diagrams)
- Interactive selection of what to extract
- Creates organized auxiliary files in docs/ directory
- Updates CLAUDE.md with clear links to extracted content
- Preserves all information while improving navigability
- **Dry-run mode**: Preview extractions without making changes

**Dry-Run Mode** (`--dry-run`):
- Shows exactly what would be extracted
- Displays before/after line counts
- Shows impact analysis (% reduction)
- No files are created or modified
- Helpful for planning and reviewing before committing

**When to Use**:
- CLAUDE.md is >200 lines and hard to navigate
- Detailed reference material buries quick-reference info
- You want to keep CLAUDE.md focused on essentials
- Use `--dry-run` to preview changes before applying
- Equivalent to standalone `/cleanup` command

### 3. Validation Mode
Validate that CLAUDE.md and all linked standards files are properly configured.

**Usage**: `/setup --validate [project-directory]`

**Features**:
- Validates CLAUDE.md exists and has required sections
- Checks all linked standards files are readable
- Verifies specs directory structure
- Tests documented commands are executable
- Identifies missing or incomplete sections
- Generates validation report with fix suggestions

**Equivalent to**: `/validate-setup [project-directory]`

### 4. Analysis Mode
Analyze existing CLAUDE.md and codebase to identify discrepancies and gaps, generating a comprehensive analysis report.

**Usage**: `/setup --analyze [project-directory]`

**Features**:
- Discovers standards from three sources: CLAUDE.md, codebase patterns, configuration files
- Detects 5 types of discrepancies
- Identifies missing or incomplete sections
- Generates interactive gap-filling report in specs/reports/
- Never modifies files (safe exploration)

### 5. Report Application Mode
Parse a completed analysis report and update CLAUDE.md with reconciled standards.

**Usage**: `/setup --apply-report <report-path> [project-directory]`

**Features**:
- Parses completed `[FILL IN: ...]` sections from analysis reports
- Creates backup before modifying CLAUDE.md
- Updates standards based on user decisions
- Validates generated CLAUDE.md structure
- Suggests running `/setup --validate`

### 6. Documentation Enhancement Mode
Automatically discover project documentation and enhance CLAUDE.md by delegating to /orchestrate.

**Usage**: `/setup --enhance-with-docs [project-directory]`

**Features**:
- Discovers documentation files (docs/, TESTING.md, CONTRIBUTING.md, etc.)
- Analyzes testing infrastructure and detects TDD practices
- Identifies gaps between discovered docs and CLAUDE.md
- Automatically updates CLAUDE.md with links and TDD requirements
- Generates workflow summary with changes made

**Workflow**: Delegates to /orchestrate with predetermined 4-phase workflow:
- **Phase 1**: Research (3 parallel agents: doc discovery, test analysis, TDD detection) ~40s
- **Phase 2**: Planning (gap analysis and reconciliation) ~15s
- **Phase 3**: Implementation (CLAUDE.md enhancement) ~10s
- **Phase 4**: Documentation (workflow summary) ~10s
- **Total time**: ~75 seconds

**Use When**:
- Project has documentation not referenced in CLAUDE.md
- Testing practices documented but not enforced
- Want automatic CLAUDE.md enhancement
- After adding new documentation files
- Periodically to keep CLAUDE.md in sync

**Output Artifacts**:
- Updated CLAUDE.md with documentation links
- Research reports (3): doc_discovery/, test_analysis/, tdd_detection/
- Enhancement plan (1): reconciliation strategy
- Workflow summary (1): changes made and cross-references

**Validation**: After enhancement, run `/validate-setup` to verify CLAUDE.md structure and links.

## Target Directory
$1 (or current directory)

## Argument Parsing

### Mode Detection

| Mode | Flags | Arguments | Behavior | Validation |
|------|-------|-----------|----------|------------|
| Standard | (none) | `[project-dir]` | Generate/update CLAUDE.md | None |
| Cleanup | `--cleanup [--dry-run] [--threshold VALUE]` | `[project-dir]` | Extract sections to optimize | `--dry-run` requires `--cleanup` |
| Validation | `--validate` | `[project-dir]` | Validate structure | None |
| Analysis | `--analyze` | `[project-dir]` | Generate discrepancy report | Conflicts with `--cleanup` |
| Report Application | `--apply-report <path>` | `[project-dir]` | Apply report decisions | Path must exist |
| Enhancement | `--enhance-with-docs` | `[project-dir]` | Discover docs and enhance CLAUDE.md | Delegates to /orchestrate |

**Priority**: --apply-report > --enhance-with-docs > --cleanup > --validate > --analyze > standard

Arguments can be in any order. Project directory defaults to current directory if not specified.

### Error Handling

**Flag Validation**:
| Error | Condition | Message |
|-------|-----------|---------|
| Mutually exclusive modes | `--cleanup` + `--analyze` or other combinations | "Cannot use both [flag1] and [flag2] together. Choose one mode." |
| Missing argument | `--apply-report` without path | "--apply-report requires a report file path" |
| File not found | Report path invalid | "Report file not found: [path]. Run /setup --analyze to generate one." |
| Invalid threshold | Unknown threshold value | "Invalid threshold: [value]. Valid: aggressive, balanced, conservative, manual" |
| Incompatible flags | `--dry-run` without `--cleanup` | "--dry-run requires --cleanup mode" |

**Error Suggestions**: For common typos and mistakes, suggest closest match (--clean → --cleanup), show correct syntax, and include relevant help text with available flags.

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
[Used by: Standard Mode (optional), Cleanup Mode (always)]

This extraction process optimizes CLAUDE.md by moving detailed content to auxiliary files while keeping essential information inline.

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

## Extraction Preferences
[Shared by: Standard Mode (with auto-detection), Cleanup Mode]

Control extraction behavior across all modes that use extraction functionality.

### Threshold Settings

| Threshold | Line Trigger | Use Case | Effect | Usage |
|-----------|--------------|----------|--------|-------|
| Aggressive | >20 lines | Very large CLAUDE.md (>300 lines) | Maximum extraction, smallest main file | `--threshold aggressive` |
| Balanced (default) | >30 lines | Moderate CLAUDE.md (200-300 lines) | Extract significantly detailed sections | `--cleanup` (default) |
| Conservative | >50 lines | Manageable CLAUDE.md (150-250 lines) | Minimal extraction, keep content inline | `--threshold conservative` |
| Manual | N/A | Full extraction control | Interactive choice for each section | `--threshold manual` |

### Directory and Naming Preferences

| Preference | Options | Default | Usage |
|------------|---------|---------|-------|
| Target directory | `docs/` (default), custom path, per-type | `docs/` | `--target-dir=documentation/` |
| File naming | CAPS.md, lowercase.md, Mixed.md | CAPS.md | `--naming lowercase` |
| Link descriptions | Include/omit descriptions | Include | `--links minimal` |
| Quick references | Include/omit quick refs | Include | `--links descriptions-only` |

**Link Style Examples**:
```markdown
# With descriptions (default)
See [Testing Standards](docs/TESTING.md) for test configuration, commands, and CI/CD.

# Minimal
See [Testing Standards](docs/TESTING.md).

# With quick reference (default)
Quick reference: Run tests with `npm test`
See [Testing Standards](docs/TESTING.md) for complete documentation.
```

### Applying Preferences

**Standard Mode**: Preferences apply when user accepts cleanup prompt
**Cleanup Mode**: Preferences always applied
**Preview**: Use `--dry-run` to see impact before applying

```bash
# Default balanced extraction
/setup --cleanup

# Aggressive extraction with custom directory
/setup --cleanup --threshold aggressive --target-dir=documentation/

# Preview conservative extraction
/setup --cleanup --dry-run --threshold conservative
```

## Cleanup Mode Workflow

### When to Use Each Mode

```
Choose your mode based on your goal:

Standard Mode (/setup)
├─ Goal: Set up or update CLAUDE.md with standards
├─ When: New project or updating standards
└─ Extraction: Optional, if CLAUDE.md becomes bloated

Cleanup Mode (/setup --cleanup)
├─ Goal: Optimize existing CLAUDE.md
├─ When: CLAUDE.md is >200 lines or hard to navigate
└─ Extraction: Primary focus, always runs

Equivalent: /cleanup → /setup --cleanup
```

### Cleanup vs Standard Mode

| Aspect | Standard Mode | Cleanup Mode |
|--------|--------------|--------------|
| **Primary Goal** | Generate/update standards | Optimize CLAUDE.md size |
| **Extraction** | Optional (if bloated) | Always runs |
| **Standards Generation** | Yes | No |
| **Standards Analysis** | Available (--analyze) | Not available |
| **Best For** | Initial setup, updates | Ongoing maintenance |

### Cleanup Workflow

```
User runs: /setup --cleanup
     ↓
1. Analyze CLAUDE.md
   - Measure total lines
   - Identify sections >30 lines
   - Find extraction candidates
     ↓
2. Show Extraction Opportunities
   - List each candidate with line count
   - Show impact (% reduction)
   - Suggest target files
     ↓
3. Interactive Selection
   - User chooses [E]xtract / [K]eep / [S]implify
   - Customize extraction threshold
   - Select specific sections
     ↓
4. Extract Sections
   - Create auxiliary files in docs/
   - Move content preserving structure
   - Add navigation breadcrumbs
     ↓
5. Update CLAUDE.md
   - Replace extracted sections with links
   - Add quick reference if applicable
   - Preserve unextracted content
     ↓
6. Validation
   - Verify all links work
   - Check no information lost
   - Report final line count
     ↓
Done: Optimized CLAUDE.md
```

## Bloat Detection Algorithm

Runs in **Standard Mode** when `/setup` is invoked with no flags and CLAUDE.md exists.

### Detection Thresholds

**Combined Logic**: `bloat_detected = (total_lines > 200) OR (any section > 30 lines)`

| Threshold | Condition | Example |
|-----------|-----------|---------|
| Total line count | File >200 lines | CLAUDE.md is 248 lines (threshold: 200) |
| Oversized sections | Any section >30 lines | Testing Standards: 52 lines (threshold: 30) |

### User Prompt and Response

When bloat detected, prompts: "CLAUDE.md is 248 lines. Optimize first? [Y/n/c]"

| Response | Action | Result |
|----------|--------|--------|
| [Y]es | Run cleanup extraction | Extract sections → Update links → Continue setup |
| [N]o | Skip optimization | Continue standard setup (can run /setup --cleanup later) |
| [C]ustomize | Show all oversized sections | User selects specific sections → Extract → Continue setup |

### Opt-Out Mechanisms

```bash
# Environment variable (global disable)
export SKIP_CLEANUP_PROMPT=1

# Command flag (single invocation)
/setup --no-cleanup-prompt

# Configuration file (future)
# .claude/config.yml
# cleanup:
#   auto_detect: false
```

After cleanup: Original setup goal continues, extraction committed, user sees both cleanup and setup results.

## Extraction Preview (--dry-run)

Preview extraction changes without modifying files. Helpful for planning, understanding impact, and team review.

### Usage

```bash
# Preview cleanup extraction
/setup --cleanup --dry-run [project-directory]

# Requires --cleanup mode
/setup --dry-run              # Error: requires --cleanup
/setup --analyze --dry-run    # Error: dry-run only with cleanup
```

### Preview Output

Shows for each extraction candidate:
- Section name, current line count, target file
- Rationale (why it qualifies for extraction)
- Impact (lines saved, % reduction)
- Content summary

**Interactive Selection**: Even in dry-run, you can toggle selections, preview different combinations, and see updated impact calculations.

**Comparison**: Generate preview with `/setup --cleanup --dry-run > preview.txt`, then run actual cleanup and compare results.

## Standards Analysis Workflow

### Analysis Mode (--analyze)

Analyzes three sources to detect discrepancies:

| Source | What's Analyzed | Method |
|--------|----------------|--------|
| **CLAUDE.md** | Documented standards | Parse sections with `[Used by: ...]` metadata → Extract field values |
| **Codebase** | Actual patterns | Sample files → Detect indentation, naming, error handling, test patterns → Calculate confidence |
| **Config Files** | Tool configurations | Parse `.editorconfig`, `package.json`, `stylua.toml`, etc. → Extract tool settings |

### Discrepancy Types

| Type | Description | Detection | Priority |
|------|-------------|-----------|----------|
| 1 | Documented ≠ Followed | CLAUDE.md value ≠ codebase pattern (>50% confidence) | Critical |
| 2 | Followed but undocumented | Codebase pattern (>70% confidence) not in CLAUDE.md | High |
| 3 | Config ≠ CLAUDE.md | Config file value ≠ CLAUDE.md value | High |
| 4 | Missing section | Required section not in CLAUDE.md | Medium |
| 5 | Incomplete section | Section exists but missing required fields | Medium |

**Confidence Scoring**: High (>80%), Medium (50-80%), Low (<50%) based on consistency across sampled files.

### Generated Report Structure

Report saved to `specs/reports/NNN_standards_analysis_report.md`:

1. **Metadata**: Date, project dir, files analyzed, languages detected
2. **Executive Summary**: Discrepancy counts, key findings, overall status
3. **Current State**: 3-way comparison (CLAUDE.md vs Codebase vs Config Files)
4. **Discrepancy Analysis**: 5 sections (one per type) with examples, impact, recommendations
5. **Gap Analysis**: Critical/High/Medium gaps, organized by priority
6. **Interactive Gap Filling**: `[FILL IN: Field Name]` sections with:
   - Context (current state, detected patterns, recommendations)
   - User decision field
   - Rationale field
7. **Recommendations**: Prioritized action items (immediate/short-term/medium-term)
8. **Implementation Plan**: Manual editing vs automated `--apply-report` workflow

### Analysis Workflow

```
User: /setup --analyze [project-dir]

Claude:
1. Discover standards (parse CLAUDE.md + sample codebase + read configs)
2. Detect discrepancies (5 types, calculate confidence, prioritize)
3. Generate report with [FILL IN: ...] gap markers

User:
4. Review report
5. Fill [FILL IN: ...] sections with decisions and rationale

User: /setup --apply-report specs/reports/NNN_report.md

Claude:
6. Parse filled report
7. Backup CLAUDE.md
8. Apply decisions (update fields, add sections, reconcile discrepancies)
9. Validate structure
10. Report changes made
```

### Example Analysis

**Indentation Discrepancy (Type 1 - Critical)**:
- CLAUDE.md: "2 spaces" (line 42)
- Codebase: 4 spaces (85% confidence, 40/47 files)
- .editorconfig: `indent_size = 4`
- Report fills: `[FILL IN: Indentation]` with context, recommendation ("Update to 4 spaces")

**Error Handling Gap (Type 2 - High)**:
- CLAUDE.md: Not documented
- Codebase: `pcall()` used in 92% of error-prone operations
- Report fills: `[FILL IN: Error Handling]` with recommendation ("Use pcall for operations that might fail")

**Testing Section Missing (Type 4 - Medium)**:
- CLAUDE.md: No Testing Protocols section
- Codebase: `*_spec.lua` pattern (100% of test files), plenary.nvim detected
- Report fills: `[FILL IN: Testing Protocols]` with suggested section content

### Report Application

See [Report Application Mode](#report-application-mode) for how `--apply-report` parses filled reports and updates CLAUDE.md.

## Report Application Mode (--apply-report)

### Overview

Parses completed analysis report (`[FILL IN: ...]` sections filled by user) and updates CLAUDE.md with reconciled standards.

**Usage**: `/setup --apply-report <report-path> [project-directory]`

### Parsing Algorithm

1. **Locate Gaps**: Find `[FILL IN: <field>]` sections → Extract field name, context, user decision, rationale
2. **Map to CLAUDE.md**:
   - "Indentation" → Code Standards section, Indentation field
   - "Error Handling" → Code Standards section (add if missing)
   - "Testing Protocols" → New section (create if doesn't exist)
3. **Parse Decisions**:
   - Explicit value ("4 spaces") → Use value
   - Blank (`___`) → Skip this gap
   - `[Accept]` → Use recommended value from context
4. **Validate**: Check critical gaps filled → Verify format → Warn on pattern overrides

### Update Strategy

**Backup**: Always create `CLAUDE.md.backup.YYYYMMDD_HHMMSS` first

**Update Cases**:
| Case | Action |
|------|--------|
| Field exists | Locate → Replace value → Log change |
| Section exists, field missing | Insert field → Log addition |
| Section missing | Create section + metadata → Add fields → Log creation |

**Preservation**: Unaffected content unchanged → Standard section order maintained → `[Used by: ...]` metadata preserved

### Edge Cases

| Scenario | Handling |
|----------|----------|
| No CLAUDE.md exists | Create from scratch using report |
| Partially filled report | Apply filled only, skip blanks, log count |
| Invalid decision | Skip gap, warn, continue |
| Report/path issues | Error with helpful suggestion |
| Validation fails | Don't write, report errors, backup safe |

### Workflow Example

```bash
/setup --analyze                    # Generate analysis report
# Edit report, fill [FILL IN: ...] sections
/setup --apply-report specs/reports/034_*.md
# Output: Backup created, sections updated, validation passed
/validate-setup                     # Confirm structure
```

**Rollback**: Restore from backup: `cp CLAUDE.md.backup.TIMESTAMP CLAUDE.md`

## Usage Examples

### Example 1: Auto-Cleanup During Setup
```bash
/setup /path/to/project
```
**Flow**: Detects bloated CLAUDE.md (248 lines) → Prompts "Optimize? [Y/n/c]" → User [Y]es → Extracts sections → Updates with links → Continues setup → Result: Optimized + standards

---

### Example 2: Explicit Cleanup
```bash
/setup --cleanup /path/to/project
```
**Flow**: Analyzes (310 lines) → Shows 5 candidates → User selects → Extracts → Updates → Result: 310 → 166 lines (46%)

---

### Example 3: Preview Before Applying
```bash
/setup --cleanup --dry-run /path/to/project  # Preview
# Review output
/setup --cleanup /path/to/project            # Apply if good
```
**Flow**: Shows preview (what, where, impact) → No changes → User reviews → Runs actual if satisfied

---

### Example 4: Aggressive Extraction
```bash
/setup --cleanup --threshold aggressive /path/to/project
```
**Flow**: Uses >20 line threshold (vs default >30) → Identifies more candidates → Smaller final file

Alternative: `--threshold conservative` (>50 lines) for minimal extraction

---

### Example 5: Standards Analysis
```bash
/setup --analyze /path/to/project        # Generate report
# Edit specs/reports/NNN_*.md, fill [FILL IN: ...] sections
/setup --apply-report specs/reports/NNN_*.md   # Apply
/validate-setup                          # Verify
```
**Flow**: Analyze discrepancies → Generate report with gaps → User fills → Apply to CLAUDE.md → Validate

---

### Example 6: Complete Workflow
```bash
# 1. Initial setup with cleanup
/setup /path/to/project                  # Accept cleanup prompt

# 2. Later: Check discrepancies
/setup --analyze /path/to/project

# 3. Apply corrections
/setup --apply-report specs/reports/NNN_*.md

# 4. Periodic re-optimization
/setup --cleanup --dry-run               # Preview
/setup --cleanup                         # Apply if needed
```
**Flow**: Setup → Analyze → Reconcile → Maintain

---

### Example 7: Documentation Enhancement
```bash
/setup --enhance-with-docs /path/to/project
```
**Flow**: Discovers docs → Analyzes tests → Detects TDD → Creates plan → Enhances CLAUDE.md → Generates summary → Result: CLAUDE.md with doc links + TDD requirements

---

### Quick Reference

| Goal | Command | Result |
|------|---------|--------|
| Setup with optimization | `/setup` → [Y]es prompt | CLAUDE.md + cleanup |
| Optimize existing | `/setup --cleanup` | Extracted sections |
| Preview changes | `/setup --cleanup --dry-run` | No-op preview |
| Check discrepancies | `/setup --analyze` | Analysis report |
| Apply reconciliation | `/setup --apply-report <path>` | Updated CLAUDE.md |
| Enhance with docs | `/setup --enhance-with-docs` | CLAUDE.md + doc links |
| Validate structure | `/validate-setup` | Validation report |

## See Also

### Related Commands

**[/cleanup](cleanup.md)**: Lightweight wrapper for `/setup --cleanup`
- Quick access to cleanup functionality
- Equivalent behavior to /setup --cleanup
- Use when you only need optimization

**[/validate-setup](validate-setup.md)**: Validate CLAUDE.md structure
- Run after /setup to verify standards
- Checks parseability for other commands
- Validates metadata and field formats

**[/implement](implement.md)**: Execute implementation plans
- Uses standards from CLAUDE.md
- Relies on properly structured standards
- Benefits from optimized CLAUDE.md

**[/test](test.md)**: Run project tests
- Uses Testing Protocols from CLAUDE.md
- Discovers tests based on documented patterns
- Benefits from clear test documentation

**[/refactor](refactor.md)**: Analyze code for refactoring
- Validates against CLAUDE.md standards
- Uses code standards for quality checks
- Benefits from comprehensive standards

### Documentation References

**Setup Process**:
- [Command Modes](#command-modes) - All available modes
- [Argument Parsing](#argument-parsing) - Flag combinations
- [Cleanup Mode Workflow](#cleanup-mode-workflow) - Detailed cleanup process

**Standards Analysis**:
- [Bloat Detection Algorithm](#bloat-detection-algorithm) - How detection works
- [Standards Analysis Workflow](#standards-analysis-workflow) - Analysis mode details
- [Report Application Mode](#report-application-mode) - Applying analysis reports

**Extraction**:
- [Smart Section Extraction](#2-smart-section-extraction) - Extraction logic
- [Extraction Preferences](#extraction-preferences) - Configuration options
- [Extraction Preview](#extraction-preview---dry-run) - Dry-run mode details

**Workflows**:
- [Cleanup Mode Workflow](#cleanup-mode-workflow) - When and how to use cleanup
- [Complete Standards Lifecycle](#complete-standards-lifecycle) - Full workflow

### External Resources

**Project Standards**:
- CLAUDE.md - Project standards file (target of setup/cleanup)
- docs/ - Extracted documentation directory
- specs/reports/ - Standards analysis reports
- specs/plans/ - Implementation plans

**Configuration** (Future):
- .claude/config/extraction.yml - Extraction preferences
- .claude/config.yml - Global Claude Code configuration

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

## Enhancement Mode Process

When `--enhance-with-docs` flag is detected:

### 1. Validate Project Directory
- Check if the provided (or current) directory exists
- Convert to absolute path for consistency
- Verify it's a valid project directory

### 2. Display Initial Message
Show the user what will happen:
```
Enhancing CLAUDE.md with discovered documentation...
Project: /absolute/path/to/project

Delegating to /orchestrate for multi-agent workflow:
- Phase 1: Research (3 parallel agents, ~40s)
- Phase 2: Planning (gap analysis, ~15s)
- Phase 3: Implementation (CLAUDE.md enhancement, ~10s)
- Phase 4: Documentation (workflow summary, ~10s)

Starting workflow...
```

### 3. Build Orchestrate Message
Create the predetermined orchestrate invocation message with the project directory:

```
Analyze project documentation at [PROJECT_DIR] and enhance CLAUDE.md with discovered standards. Follow this workflow:

Phase 1: Research (parallel)
  - Agent 1: Discover all documentation files (docs/, TESTING.md, CONTRIBUTING.md, etc.)
  - Agent 2: Analyze testing infrastructure (framework, test count, organization)
  - Agent 3: Detect TDD practices and calculate confidence score

Phase 2: Planning
  - Synthesize research into gap analysis
  - Create reconciliation plan for CLAUDE.md

Phase 3: Implementation
  - Update CLAUDE.md with documentation links
  - Add TDD requirements if detected (≥50% confidence)
  - Enhance Testing Protocols section

Phase 4: Documentation
  - Generate workflow summary with before/after comparison
  - List all changes made

Project directory: [PROJECT_DIR]
```

### 4. Invoke /orchestrate
Use the SlashCommand tool to invoke /orchestrate with the message above. The orchestrate command will handle:
- Launching the 3 research agents in parallel
- Collecting and synthesizing reports
- Creating the enhancement plan
- Implementing CLAUDE.md updates
- Generating the workflow summary

### 5. Display Results
After /orchestrate completes, show summary:
```
Enhancement complete!

Artifacts created:
- Research reports (3): .claude/specs/reports/doc_discovery/, test_analysis/, tdd_detection/
- Enhancement plan (1): .claude/specs/plans/NNN_claude_enhancement.md
- Updated CLAUDE.md with documentation links and TDD requirements
- Workflow summary (1): .claude/specs/summaries/NNN_*.md

Next steps:
1. Review the changes made to CLAUDE.md
2. Run /validate-setup to verify structure
3. Commit changes if satisfied
```

### Error Handling

**If project directory doesn't exist**:
```
Error: Directory not found: /path/to/directory
Usage: /setup --enhance-with-docs [project-directory]
```

**If /orchestrate is unavailable**:
```
Error: /orchestrate command not available
This mode requires the /orchestrate command to function.
Please ensure all Claude Code commands are properly installed.
```

**If orchestrate workflow fails**:
```
Enhancement workflow encountered an error.
See orchestrate output above for details.
CLAUDE.md has not been modified (or has been backed up).
```

### Mode Detection Priority

When parsing arguments, check flags in this order:
1. --apply-report (highest priority)
2. --enhance-with-docs
3. --cleanup
4. --validate
5. --analyze
6. Standard mode (default, no flags)

If `--enhance-with-docs` is detected:
- Ignore all other mode flags
- Extract project directory argument
- Skip all standard setup logic
- Execute Enhancement Mode process above

---

Let me analyze your project and help organize your CLAUDE.md efficiently.