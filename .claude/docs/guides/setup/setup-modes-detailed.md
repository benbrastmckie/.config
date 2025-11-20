# Setup Command Modes

This document provides comprehensive documentation for all command modes available in the /setup command, including detailed workflows and usage patterns.

**Referenced by**: [setup.md](../../../commands/setup.md)

**Contents**:
- Command Modes Overview
- Cleanup Mode Workflow
- Mode Selection Guide
- Common Workflows

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

---

## See Also

- [Setup Command Guide](../../commands/setup-command-guide.md) - Main setup documentation
- [Extraction Strategies](extraction-strategies.md) - CLAUDE.md optimization details
- [Standards Analysis](standards-analysis.md) - Analysis and report application
- [Bloat Detection](bloat-detection.md) - Automatic optimization detection
