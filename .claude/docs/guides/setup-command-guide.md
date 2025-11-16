# /setup Command and Utilities Guide

**Executable**: `.claude/commands/setup.md` - Lean execution script (311 lines)
**This Guide**: Comprehensive documentation, architecture, and usage examples

## Overview

The /setup command ecosystem provides tools for creating and maintaining optimal CLAUDE.md files with intelligent context management.

**Command Modes** (6 modes, priority-based):
1. **Standard** (`/setup [dir]`) - Generate/update CLAUDE.md with standards detection
2. **Cleanup** (`/setup --cleanup [dir]`) - Extract bloated sections to auxiliary files
3. **Validation** (`/setup --validate [dir]`) - Verify CLAUDE.md structure and links
4. **Analysis** (`/setup --analyze [dir]`) - Detect discrepancies between docs and codebase
5. **Report Application** (`/setup --apply-report <path> [dir]`) - Apply filled analysis reports
6. **Enhancement** (`/setup --enhance-with-docs [dir]`) - Auto-discover docs and enhance CLAUDE.md

**Architecture**: This command follows the [Executable/Documentation Separation Pattern](../concepts/patterns/executable-documentation-separation.md). The executable file (setup.md) contains lean execution logic with bash blocks and verification checkpoints. This guide contains comprehensive architecture, usage examples, and troubleshooting.

## Core Utilities

### 1. Testing Detection (`detect-testing.sh`)

Score-based testing framework detection (0-6 points).

**Usage**:
```bash
.claude/lib/detect-testing.sh [directory]
```

**Scoring System**:
- CI/CD configs (+2): .github/workflows/*.yml, .gitlab-ci.yml, etc.
- Test directories (+1): tests/, test/, __tests__/, spec/
- Test files >10 (+1): Multiple test files detected
- Coverage tools (+1): .coveragerc, jest.config.js, coverage.xml
- Test runners (+1): run_tests.sh, Makefile with test:

**Frameworks Detected**: pytest, jest, vitest, mocha, plenary, busted, cargo-test, go-test, bash-tests

**Example**:
```bash
$ .claude/lib/detect-testing.sh /home/benjamin/.config
SCORE:1
FRAMEWORKS:plenary bash-tests
```

### 2. Testing Protocol Generation (`generate-testing-protocols.sh`)

Generates adaptive testing protocols based on confidence score.

**Usage**:
```bash
.claude/lib/generate-testing-protocols.sh <score> <frameworks>
```

**Confidence Levels**:
- **High (≥4)**: Full protocols with framework-specific commands, TDD guidance
- **Medium (2-3)**: Brief protocols with expansion suggestions
- **Low (0-1)**: Minimal placeholder or recommendations

**Example**:
```bash
$ .claude/lib/generate-testing-protocols.sh 5 "pytest jest"
# Generates comprehensive testing protocols
```

### 3. Context Optimization (`optimize-claude-md.sh`)

Analyzes CLAUDE.md for bloat and recommends extractions.

**IMPORTANT - Command File Optimization**:

This optimization utility is designed for **CLAUDE.md files only**, NOT for command files (`.claude/commands/*.md`). Command files follow different architectural standards where execution logic must remain inline for AI interpretation.

**DO NOT apply this utility to:**
- Command files (`.claude/commands/*.md`)
- Agent files (`.claude/agents/*.md`)
- Any file containing executable instructions for Claude

**Rationale**: Command files are AI execution scripts, not documentation. Over-extraction of command content violates [Command Architecture Standards - Standard 1 (Inline Execution)](../reference/command_architecture_standards.md#standard-1), which requires workflow logic, tool invocations, and decision points to remain inline for direct AI interpretation.

**Usage**:
```bash
.claude/lib/optimize-claude-md.sh [file] [options]

Options:
  --dry-run           Preview analysis without changes (default)
  --aggressive        Extract sections >50 lines
  --balanced          Extract sections >80 lines (default)
  --conservative      Extract sections >120 lines
  --rollback <backup> <target>  Restore from backup
```

**Example**:
```bash
# Analyze current CLAUDE.md
$ .claude/lib/optimize-claude-md.sh CLAUDE.md --dry-run --balanced

# Output shows:
# - Section analysis table (name, lines, status, recommendation)
# - Bloated sections count
# - Projected savings
# - Current vs target size
# - Reduction percentage
```

**Automatic Backup**: Creates timestamped backups in `.claude/backups/` before modifications.

### 4. README Scaffolding (`generate-readme.sh`)

Template-based README.md generation with navigation links.

**Usage**:
```bash
# Generate for single directory
.claude/lib/generate-readme.sh [directory]

# Find directories without README
.claude/lib/generate-readme.sh --find [root]

# Generate for all eligible directories
.claude/lib/generate-readme.sh --generate-all [root] [--force]
```

**Features**:
- Auto-detects parent README and generates parent links
- Lists files and subdirectories with descriptions
- Adds [FILL IN:] placeholders for manual content
- Preserves existing READMEs (--force to overwrite)
- Reports coverage: N/M directories (X%)

**Example**:
```bash
$ .claude/lib/generate-readme.sh --generate-all /project

Scanning /project for directories without README.md...
Found 12 directories without README.md

Generated README at /project/lib/README.md
Generated README at /project/docs/README.md
...

=== Summary ===
Generated: 12 READMEs
Skipped: 0 directories
Coverage: 45/50 directories (90.0%)
```

## Usage Patterns

### Pattern 1: New Project Setup

```bash
# 1. Detect testing infrastructure
.claude/lib/detect-testing.sh /project

# 2. Generate testing protocols based on score
.claude/lib/generate-testing-protocols.sh 4 "pytest" > testing.md

# 3. Create systematic documentation
.claude/lib/generate-readme.sh --generate-all /project

# 4. Use /setup for CLAUDE.md
/setup /project
```

### Pattern 2: Optimize Existing CLAUDE.md

```bash
# 1. Analyze for bloat
.claude/lib/optimize-claude-md.sh CLAUDE.md --dry-run

# 2. Review recommendations, then optimize
.claude/lib/optimize-claude-md.sh CLAUDE.md --balanced

# 3. Validate result
wc -l CLAUDE.md
cat CLAUDE.md  # Review inline summaries and links
```

### Pattern 3: Test Coverage Assessment

```bash
# 1. Detect current test infrastructure
.claude/lib/detect-testing.sh .

# 2. Add CI/CD or test files to improve score
# (e.g., add .github/workflows/test.yml)

# 3. Re-detect to see improved score
.claude/lib/detect-testing.sh .

# 4. Generate upgraded testing protocols
.claude/lib/generate-testing-protocols.sh 4 "pytest"
```

### Pattern 4: Documentation Coverage

```bash
# 1. Find gaps in documentation
.claude/lib/generate-readme.sh --find /project

# 2. Generate READMEs for gaps
.claude/lib/generate-readme.sh --generate-all /project

# 3. Fill [FILL IN:] placeholders manually
# Edit generated README.md files

# 4. Validate links and structure
grep -r "\[FILL IN:\]" /project  # Find remaining placeholders
```

## Threshold Profiles

### Aggressive (>50 lines)
**Use for**: Very large CLAUDE.md (>400 lines)
**Effect**: Maximum extraction, smallest main file
**Example**: Technical docs projects with extensive details

### Balanced (>80 lines) - Default
**Use for**: Moderate CLAUDE.md (300-400 lines)
**Effect**: Extract significantly detailed sections
**Example**: Most development projects

### Conservative (>120 lines)
**Use for**: Already lean CLAUDE.md (<300 lines)
**Effect**: Minimal extraction, keep content inline
**Example**: Small projects or minimalist configs

## Troubleshooting

### Issue: Testing score is 0 but tests exist

**Cause**: Tests not in standard locations (tests/, __tests__/, spec/)

**Solution**: Move tests to standard directory or add test runner script:
```bash
# Create test runner
echo '#!/bin/bash' > run_tests.sh
echo 'pytest tests/' >> run_tests.sh
chmod +x run_tests.sh

# Re-detect
.claude/lib/detect-testing.sh .
```

### Issue: README generation creates too many files

**Cause**: Project has many small directories

**Solution**: Use generate_readme() for specific directories only:
```bash
# Generate for specific dirs
.claude/lib/generate-readme.sh /project/src
.claude/lib/generate-readme.sh /project/docs
```

### Issue: Optimization utility shows no bloated sections

**Cause**: CLAUDE.md is already well-optimized

**Solution**: This is good! Use --aggressive profile if you still want extractions:
```bash
.claude/lib/optimize-claude-md.sh CLAUDE.md --aggressive
```

### Issue: Generated protocols don't match project needs

**Cause**: Framework detection missed custom setup

**Solution**: Manually edit generated protocols or improve detection:
```bash
# Add framework config files
touch pytest.ini  # or jest.config.js, etc.

# Re-detect
.claude/lib/detect-testing.sh .
```

## Best Practices

### CLAUDE.md Maintenance

1. **Start Lean**: Begin with 200-300 line CLAUDE.md
2. **Monitor Growth**: Run optimize-claude-md.sh periodically
3. **Extract Early**: Extract sections >80 lines before they become >150
4. **Link Richly**: Add inline summaries with links to extracted docs
5. **Section Markers**: Use `<!-- SECTION: name -->` markers for incremental updates

### Testing Documentation

1. **High Confidence (≥4)**: Document test commands, CI integration, coverage
2. **Medium Confidence (2-3)**: Document basic commands, note missing infrastructure
3. **Low Confidence (0-1)**: Add minimal placeholder, suggest improvements

### README Coverage

1. **Prioritize**: Start with src/, lib/, docs/ directories
2. **Fill Placeholders**: Replace [FILL IN:] with actual descriptions
3. **Link Richly**: Ensure parent and subdirectory links work
4. **Update Regularly**: Regenerate after major structural changes

## Integration with /setup

The /setup command provides comprehensive CLAUDE.md generation and includes cleanup mode. The utilities documented here work independently and can be used alongside /setup:

- **/setup**: Full CLAUDE.md generation with standards detection
- **/setup --cleanup**: Extract bloated sections (similar to optimize-claude-md.sh)
- **Utilities**: Focused tools for specific tasks (testing detection, optimization, READMEs)

Use /setup for initial setup and major updates. Use utilities for targeted maintenance and analysis.

## See Also

- [CLAUDE.md](../../../CLAUDE.md) - Project standards file
- [Command Architecture Standards](../reference/command_architecture_standards.md) - Command design patterns
- [Development Workflow](../concepts/development-workflow.md) - Spec updater integration

---
## Additional Setup Sections


### Extraction Strategies

# Extraction Strategies

This document describes the smart extraction system used by /setup to optimize CLAUDE.md by moving detailed content to auxiliary files.

**Referenced by**: [setup.md](../../commands/setup.md)

**Contents**:
- Smart Section Extraction
- Extraction Preferences
- Extraction Preview (Dry-Run Mode)

---

## Smart Section Extraction

[Used by: Standard Mode (optional), Cleanup Mode (always)]

This extraction process optimizes CLAUDE.md by moving detailed content to auxiliary files while keeping essential information inline.

### Extraction Mapping

For sections that would benefit from extraction, content is moved to dedicated files:

| Section Type | Suggested File | Extraction Trigger |
|-------------|---------------|-------------------|
| Testing Standards | `docs/TESTING.md` | >20 lines of test details |
| Code Style Guide | `docs/CODE_STYLE.md` | Detailed formatting rules |
| Documentation Guide | `docs/DOCUMENTATION.md` | Template examples |
| Command Reference | `docs/COMMANDS.md` | >10 commands |
| Architecture | `docs/ARCHITECTURE.md` | Complex diagrams |

### Interactive Extraction Process

For each extractable section, the command asks:

```
Found: Testing Standards (45 lines) in CLAUDE.md

Would you like to:
[E]xtract to docs/TESTING.md and link it
[K]eep in CLAUDE.md as-is
[S]implify in place without extraction
```

If you choose extraction:
1. Create the auxiliary file with the content
2. Replace the section in CLAUDE.md with a concise summary and link
3. Add navigation links between files

### Decision Criteria

**Recommend extraction when**:
- Section is >30 lines of detailed content
- Content is reference material (not daily use)
- Multiple examples or templates present
- Complex configuration rarely changed

**Keep inline when**:
- Quick reference commands (<10 lines)
- Critical navigation/index information
- Specs protocol (core to Claude)
- Daily-use information

### File Organization

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

### Benefits

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

---

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
See [Testing Standards](../../../TESTING.md) for test configuration, commands, and CI/CD.

# Minimal
See [Testing Standards](../../../TESTING.md).

# With quick reference (default)
Quick reference: Run tests with `npm test`
See [Testing Standards](../../../TESTING.md) for complete documentation.
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

---

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

### Example Preview Output

```
=== Extraction Preview ===

CLAUDE.md: 310 lines

Extraction Candidates (--threshold balanced, >30 lines):

1. Testing Standards (52 lines) → docs/TESTING.md
   Rationale: Detailed test configuration exceeds threshold
   Impact: -52 lines (16.8% reduction)
   Content: Test commands, framework setup, CI/CD integration

2. Code Style Guide (38 lines) → docs/CODE_STYLE.md
   Rationale: Formatting rules and examples exceed threshold
   Impact: -38 lines (12.3% reduction)
   Content: Indentation, naming, error handling patterns

3. Architecture Diagram (44 lines) → docs/ARCHITECTURE.md
   Rationale: Complex ASCII diagrams exceed threshold
   Impact: -44 lines (14.2% reduction)
   Content: System architecture, data flow, component relationships

Total Impact: 310 → 176 lines (43.2% reduction)

No files will be modified (dry-run mode)
```

### Workflow Integration

**Planning Phase**:
1. Run dry-run to preview changes
2. Review extraction candidates and impact
3. Adjust threshold if needed
4. Run actual cleanup when satisfied

**Team Review**:
1. Generate preview output: `/setup --cleanup --dry-run > extraction-plan.txt`
2. Share with team for feedback
3. Adjust preferences based on feedback
4. Apply cleanup: `/setup --cleanup`

**Iterative Refinement**:
```bash
# Try different thresholds
/setup --cleanup --dry-run --threshold aggressive    # See maximum extraction
/setup --cleanup --dry-run --threshold balanced      # See default extraction
/setup --cleanup --dry-run --threshold conservative  # See minimal extraction

# Choose preferred threshold and apply
/setup --cleanup --threshold balanced
```

---

## Optimal CLAUDE.md Structure

### Goal: Command-Parseable Standards File

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

### Structure Benefits

**For Commands**:
- Parseable sections with `[Used by: ...]` metadata
- Consistent field format: `**Field**: value`
- Predictable section organization

**For Humans**:
- Quick navigation with clear hierarchy
- Essential information readily visible
- Detailed docs linked when needed
- Manageable file size for easy scanning

**For Maintenance**:
- Clear separation of concerns
- Smaller diffs in version control
- Easier to update specific topics
- Reduced merge conflicts

### Standards Analysis

# Standards Analysis and Report Application

This document provides comprehensive documentation for the standards analysis and report application features in the /setup command.

**Referenced by**: [setup.md](../../commands/setup.md)

**Contents**:
- Analysis Mode Workflow
- Report Application Mode
- Integration Examples

---

## Analysis Mode (--analyze)

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

---

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

---

## Integration Examples

### Complete Analysis-to-Application Workflow

```
Step 1: Initial Analysis
────────────────────────
/setup --analyze /path/to/project

Output: specs/reports/042_standards_analysis_report.md
Content: 5 discrepancies detected, 12 gaps identified


Step 2: Review and Fill Report
───────────────────────────────
Open: specs/reports/042_standards_analysis_report.md

Find sections like:
  [FILL IN: Indentation]
  Context: CLAUDE.md says "2 spaces", codebase uses 4 spaces (85% confidence)
  Recommendation: Update to "4 spaces" to match codebase
  Decision: _______________
  Rationale: _______________

Fill with:
  Decision: 4 spaces
  Rationale: Match existing codebase convention


Step 3: Apply Reconciliation
─────────────────────────────
/setup --apply-report specs/reports/042_standards_analysis_report.md

Output:
  Backup created: CLAUDE.md.backup.20250115_143022
  Updated 3 fields, added 2 sections
  Validation passed


Step 4: Verify Changes
──────────────────────
/setup --validate

Output: All sections valid, all links verified
```

### Partial Report Application

If you fill only some gaps:

```bash
/setup --analyze
# Fill only critical gaps in report, leave medium priority blank
/setup --apply-report specs/reports/042_*.md
# Output: Applied 3/12 gaps, skipped 9 blank gaps
```

**Benefit**: Incremental reconciliation - address critical issues first, defer lower-priority gaps

### Report Regeneration After Code Changes

```bash
# Initial analysis
/setup --analyze
# Fill report, apply changes
/setup --apply-report specs/reports/042_*.md

# ... 3 months later, code evolves ...

# Re-analyze to detect new drift
/setup --analyze
# New report: specs/reports/043_*.md
# Shows new discrepancies since last analysis
```

**Benefit**: Ongoing standards maintenance - catch drift as code evolves

---

## Best Practices

### When to Use Analysis Mode

**Good Use Cases**:
- Inheriting unfamiliar codebase
- CLAUDE.md out of sync with code
- Merging divergent team standards
- Preparing for refactoring
- Audit compliance verification

**Not Needed When**:
- Fresh project with no code yet
- CLAUDE.md created and maintained actively
- Standards already well-aligned

### Gap Filling Strategy

**Priority Order**:
1. **Critical discrepancies** (Type 1): CLAUDE.md contradicts code - high confusion risk
2. **High discrepancies** (Type 2, 3): Missing docs or config mismatches - medium risk
3. **Medium gaps** (Type 4, 5): Missing/incomplete sections - low risk, defer if time-limited

**Decision Guidelines**:
- **Code majority wins**: If 80%+ of codebase uses one pattern, document it
- **Config alignment**: Match CLAUDE.md to config files (`.editorconfig`, etc.)
- **Team consensus**: For subjective choices (naming, style), consult team
- **Leave blank**: For uncertain decisions, defer rather than guess

### Rollback and Recovery

**Before Applying**:
```bash
# Always preview impact first
cat specs/reports/042_*.md | grep "Decision:"  # Check what you filled
```

**After Applying**:
```bash
# If unhappy with results
cp CLAUDE.md.backup.20250115_143022 CLAUDE.md

# Or selectively undo specific changes
git diff CLAUDE.md                   # Review changes
git checkout -- CLAUDE.md            # Revert if using git
```

**Best Practice**: Commit CLAUDE.md before applying reports for easy rollback:
```bash
git add CLAUDE.md && git commit -m "Pre-analysis baseline"
/setup --apply-report specs/reports/042_*.md
# Review changes
git diff                              # See exactly what changed
git reset --hard HEAD                 # Revert if needed
```

### Setup Modes

# Setup Command Modes

This document provides comprehensive documentation for all command modes available in the /setup command, including detailed workflows and usage patterns.

**Referenced by**: [setup.md](../../commands/setup.md)

**Contents**:
- Command Modes Overview
- Cleanup Mode Workflow
- Mode Selection Guide

---

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

---

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

---

## Mode Selection Guide

### Quick Decision Tree

```
Need to...                           Use...
─────────────────────────────────────────────────────────────
Create CLAUDE.md for new project    /setup
Update existing standards            /setup
Preview optimization changes         /setup --cleanup --dry-run
Optimize large CLAUDE.md             /setup --cleanup
Check for discrepancies              /setup --analyze
Apply analysis corrections           /setup --apply-report <path>
Verify structure and links           /setup --validate
```

### Mode Priority

When multiple flags are provided, modes are applied in this order:
1. `--apply-report` (highest priority)
2. `--cleanup`
3. `--validate`
4. `--analyze`
5. Standard mode (default)

### Common Workflows

#### Initial Project Setup
```bash
/setup                               # Create CLAUDE.md
/setup --validate                    # Verify structure
```

#### Maintenance Workflow
```bash
/setup --analyze                     # Check discrepancies
# Fill [FILL IN: ...] sections in generated report
/setup --apply-report specs/reports/NNN_*.md
/setup --validate                    # Verify updates
```

#### Optimization Workflow
```bash
/setup --cleanup --dry-run           # Preview changes
/setup --cleanup                     # Apply if satisfied
```

#### Complete Lifecycle
```bash
/setup                               # Initial setup (accept cleanup if prompted)
# ... develop ...
/setup --analyze                     # Check for drift
/setup --apply-report <path>         # Reconcile
/setup --cleanup --dry-run           # Check if re-optimization needed
/setup --cleanup                     # Apply if beneficial
```

### Bloat Detection

# Bloat Detection Algorithm

This document describes the automatic bloat detection system used in Standard Mode to identify when CLAUDE.md optimization is beneficial.

**Referenced by**: [setup.md](../../commands/setup.md)

**Contents**:
- Detection Thresholds
- User Interaction
- Opt-Out Mechanisms

---

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

---

## Detection Examples

### Example 1: Total Line Count Trigger

**Scenario**: CLAUDE.md is 248 lines, all sections <30 lines

**Detection**: Total lines (248) > threshold (200)

**Prompt**: "CLAUDE.md is 248 lines. Optimize first? [Y/n/c]"

**Recommendation**: [Y]es - Even with smaller sections, the file is becoming unwieldy

### Example 2: Section Size Trigger

**Scenario**: CLAUDE.md is 180 lines, but Testing Standards section is 52 lines

**Detection**: Section size (52) > threshold (30)

**Prompt**: "CLAUDE.md is 180 lines with 1 oversized section. Optimize first? [Y/n/c]"

**Recommendation**: [Y]es - Extract the detailed Testing Standards to docs/TESTING.md

### Example 3: Combined Triggers

**Scenario**: CLAUDE.md is 310 lines with 3 sections >30 lines

**Detection**: Both total lines and section sizes exceed thresholds

**Prompt**: "CLAUDE.md is 310 lines with 3 oversized sections. Optimize first? [Y/n/c]"

**Recommendation**: [Y]es or [C]ustomize - Multiple optimization opportunities

### Example 4: No Bloat

**Scenario**: CLAUDE.md is 150 lines, all sections <30 lines

**Detection**: No bloat detected

**Behavior**: Standard mode proceeds without cleanup prompt

---

## Integration with Cleanup Mode

### Automatic Transition

When user responds [Y]es to bloat prompt:

1. **Setup pauses**: Current setup operation suspended
2. **Cleanup runs**: Full cleanup workflow executes (see [setup-modes.md](setup-modes.md#cleanup-workflow))
3. **Setup resumes**: Original setup goal continues with optimized CLAUDE.md
4. **Results shown**: Both cleanup impact and setup completion reported

### Manual Cleanup Later

When user responds [N]o to bloat prompt:

1. **Setup continues**: No cleanup performed
2. **User informed**: "You can optimize later with /setup --cleanup"
3. **No impact**: Standard setup completes normally

### Customize Option

When user responds [C]ustomize to bloat prompt:

1. **List sections**: Display all sections >30 lines with line counts
2. **Interactive selection**: User chooses which to extract
3. **Partial cleanup**: Extract only selected sections
4. **Setup continues**: Resume with partially optimized CLAUDE.md

---

## Threshold Rationale

### Why 200 Lines?

Based on research and practical experience:
- **Readability**: Files >200 lines require scrolling in most editors
- **Cognitive load**: Quick scanning becomes difficult beyond this size
- **Industry standard**: Many style guides recommend similar thresholds
- **Claude efficiency**: Smaller context files are easier to parse

### Why 30 Lines Per Section?

Balanced threshold for section-level bloat:
- **Screen height**: Most sections >30 lines don't fit on one screen
- **Extraction value**: Sections <30 lines rarely benefit from extraction
- **Context preservation**: Small sections are better kept inline
- **Quick reference**: Detailed documentation should be separate

### Customization (Future)

Planned configuration options:
```yaml
# .claude/config/bloat-detection.yml
thresholds:
  total_lines: 200        # Current default
  section_lines: 30       # Current default
  auto_prompt: true       # Show prompt automatically
```
