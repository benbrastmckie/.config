---
allowed-tools: Read, Write, Edit, MultiEdit, Bash, Grep, Glob
argument-hint: [project-directory] [--cleanup [--dry-run]] [--validate] [--analyze] [--apply-report <report-path>]
description: Setup or improve CLAUDE.md with smart extraction, cleanup optimization, validation, standards analysis, and report-driven updates
command-type: primary
dependent-commands: none
---

# Setup Project Standards

I'll create or improve the CLAUDE.md file by intelligently organizing content - keeping it concise by extracting detailed sections into auxiliary files when appropriate.

## Shared Utilities Integration

This command uses shared utility libraries for robust operation:
- **Error Handling**: Uses `.claude/lib/error-handling.sh` for validation error handling and recovery
- File existence checks, permission validation, and graceful error reporting
- Ensures setup operations can be safely retried after failures

## Command Modes

The /setup command provides five distinct modes for different CLAUDE.md management tasks: Standard (default, with auto-cleanup detection), Cleanup (optimize file size), Validation (verify structure), Analysis (detect discrepancies), and Report Application (apply analysis results).

**See**: [Setup Command Modes](shared/setup-modes.md) for comprehensive details on:

- **Standard Mode**: Generate/update CLAUDE.md with automatic bloat detection and cleanup prompts
- **Cleanup Mode**: Optimize CLAUDE.md by extracting detailed sections to auxiliary files (`--cleanup`, `--dry-run`)
- **Validation Mode**: Verify CLAUDE.md structure and linked standards files (`--validate`)
- **Analysis Mode**: Generate discrepancy reports comparing CLAUDE.md, codebase, and config files (`--analyze`)
- **Report Application Mode**: Parse and apply completed analysis reports (`--apply-report <path>`)

**Quick Mode Overview**:

| Mode | Usage | Primary Goal |
|------|-------|-------------|
| Standard | `/setup` | Generate/update standards |
| Cleanup | `/setup --cleanup [--dry-run]` | Optimize file size |
| Validation | `/setup --validate` | Verify structure |
| Analysis | `/setup --analyze` | Detect discrepancies |
| Report Application | `/setup --apply-report <path>` | Apply reconciliation |

Each mode includes detailed workflows, interactive prompts, and integration patterns with other commands.

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

**Priority**: --apply-report > --cleanup > --validate > --analyze > standard

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

The extraction system identifies bloated sections and moves detailed content to auxiliary files while keeping CLAUDE.md concise and command-parseable. It uses intelligent decision criteria, interactive prompts, and configurable thresholds.

**See**: [Extraction Strategies](shared/extraction-strategies.md) for comprehensive details on:

- **Extraction Mapping**: Section type to file mapping (Testing → docs/TESTING.md, etc.)
- **Decision Criteria**: When to extract vs keep inline based on size, usage frequency, and content type
- **File Organization**: Optimal directory structure and navigation patterns
- **Benefits**: Improved readability, maintainability, and version control

**Quick Reference**:
- Extract sections >30 lines (balanced), >20 lines (aggressive), or >50 lines (conservative)
- Interactive prompts for each candidate: [E]xtract, [K]eep, or [S]implify
- Creates auxiliary files in docs/ with bidirectional navigation links
- Preserves all information while improving CLAUDE.md navigability

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

Extraction behavior is controlled by configurable thresholds (aggressive/balanced/conservative/manual) and customizable directory/naming preferences. Use `--dry-run` to preview impact before applying changes.

**See**: [Extraction Strategies](shared/extraction-strategies.md#extraction-preferences) for details on:

- **Threshold Settings**: Aggressive (>20 lines), Balanced (>30 lines, default), Conservative (>50 lines), Manual (interactive)
- **Directory/Naming Preferences**: Target directory, file naming conventions, link styles
- **Applying Preferences**: How preferences apply in Standard vs Cleanup modes

**Quick Reference**:
```bash
/setup --cleanup                                    # Balanced (default)
/setup --cleanup --threshold aggressive             # Maximum extraction
/setup --cleanup --dry-run --threshold conservative # Preview minimal extraction
```

## Cleanup Mode Workflow

Cleanup Mode optimizes CLAUDE.md through a 6-step workflow: analyze for bloat, show extraction opportunities, interactive selection, extract sections, update CLAUDE.md with links, and validate results. Best for ongoing maintenance when CLAUDE.md exceeds 200 lines.

**See**: [Setup Command Modes](shared/setup-modes.md#cleanup-mode-workflow) for comprehensive workflow details:

- **Mode Selection Guide**: When to use Standard vs Cleanup mode
- **Cleanup Workflow**: 6-step process from analysis to validation
- **Common Workflows**: Initial setup, maintenance, optimization, complete lifecycle

**Quick Workflow**:
```
/setup --cleanup → Analyze (measure, identify candidates) → Show opportunities (impact %)
→ Interactive selection ([E]xtract/[K]eep/[S]implify) → Extract to docs/
→ Update CLAUDE.md with links → Validate (verify, report)
```

## Bloat Detection Algorithm

Automatic detection in Standard Mode uses combined logic: `bloat_detected = (total_lines > 200) OR (any section > 30 lines)`. When triggered, prompts user to optimize before continuing setup. Can be disabled via environment variable or command flag.

**See**: [Bloat Detection Algorithm](shared/bloat-detection.md) for comprehensive details on:

- **Detection Thresholds**: Total line count (>200) and section size (>30 lines) triggers
- **User Interaction**: [Y]es/[N]o/[C]ustomize prompt responses and workflow integration
- **Opt-Out Mechanisms**: Environment variables, command flags, and future configuration
- **Detection Examples**: Scenarios demonstrating when and how bloat is detected

**Quick Reference**:
- Triggers: CLAUDE.md >200 lines OR any section >30 lines
- Prompt: "CLAUDE.md is 248 lines. Optimize first? [Y/n/c]"
- Opt-out: `export SKIP_CLEANUP_PROMPT=1` or `/setup --no-cleanup-prompt`

## Extraction Preview (--dry-run)

Preview mode shows exactly what would be extracted without modifying files. Displays section name, line count, target file, rationale, and impact (% reduction) for each candidate. Helpful for planning and team review.

**See**: [Extraction Strategies](shared/extraction-strategies.md#extraction-preview-dry-run) for comprehensive details on:

- **Usage**: Requires `--cleanup` mode, errors without it
- **Preview Output**: Section details, rationale, impact calculations, content summaries
- **Workflow Integration**: Planning phase, team review, iterative refinement
- **Example Output**: Detailed preview format showing extraction candidates and total impact

**Quick Reference**:
```bash
/setup --cleanup --dry-run                      # Preview with balanced threshold
/setup --cleanup --dry-run --threshold aggressive # Preview maximum extraction
```

## Standards Analysis Workflow

Analysis Mode detects discrepancies by comparing three sources (CLAUDE.md, codebase patterns, config files) and generates interactive gap-filling reports. Report Application Mode parses completed reports and reconciles CLAUDE.md with user decisions.

**See**: [Standards Analysis and Report Application](shared/standards-analysis.md) for comprehensive details on:

- **Analysis Mode**: 3-source analysis, 5 discrepancy types, confidence scoring, report structure
- **Analysis Workflow**: 10-step process from discovery to validation
- **Example Analysis**: Indentation discrepancies, error handling gaps, missing sections
- **Report Application Mode**: Parsing algorithm, update strategy, edge cases, rollback procedures
- **Integration Examples**: Complete workflows, partial application, ongoing maintenance
- **Best Practices**: When to analyze, gap-filling strategy, rollback and recovery

**Quick Reference**:
```bash
/setup --analyze                           # Generate analysis report
# Edit specs/reports/NNN_*.md, fill [FILL IN: ...] sections
/setup --apply-report specs/reports/NNN_*.md  # Apply reconciliation
/validate-setup                            # Verify changes
```

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

### Quick Reference

| Goal | Command | Result |
|------|---------|--------|
| Setup with optimization | `/setup` → [Y]es prompt | CLAUDE.md + cleanup |
| Optimize existing | `/setup --cleanup` | Extracted sections |
| Preview changes | `/setup --cleanup --dry-run` | No-op preview |
| Check discrepancies | `/setup --analyze` | Analysis report |
| Apply reconciliation | `/setup --apply-report <path>` | Updated CLAUDE.md |
| Validate structure | `/validate-setup` | Validation report |

## See Also

**Related Commands**: [/cleanup](cleanup.md) (wrapper for `--cleanup`), [/validate-setup](validate-setup.md) (verify structure), [/implement](implement.md) (uses generated standards), [/test](test.md) (uses Testing Protocols), [/refactor](refactor.md) (validates against standards)

**Shared Documentation**: See [shared/setup-modes.md](shared/setup-modes.md), [shared/bloat-detection.md](shared/bloat-detection.md), [shared/extraction-strategies.md](shared/extraction-strategies.md), and [shared/standards-analysis.md](shared/standards-analysis.md) for comprehensive details.

**Resources**: Generated CLAUDE.md files are stored in project root. Extracted standards go to docs/. Analysis reports go to specs/reports/.

## Summary

The /setup command creates the foundation that other commands rely on by generating CLAUDE.md with parseable standards sections (Code Standards, Testing Protocols, Documentation Policy, Standards Discovery). It detects project type, analyzes existing conventions, and validates parseability to ensure seamless integration with /implement, /test, /document, /plan, and /refactor.

Let me analyze your project and help organize your CLAUDE.md efficiently.