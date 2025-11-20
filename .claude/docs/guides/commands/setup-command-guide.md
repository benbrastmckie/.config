# /setup Command and Utilities Guide

**Executable**: `.claude/commands/setup.md` - Lean execution script (354 lines)
**This Guide**: Comprehensive documentation, architecture, and usage examples

## Overview

The /setup command provides tools for creating and analyzing CLAUDE.md files with automatic mode detection for initialization and diagnostics.

**Command Modes** (3 modes, automatic detection):

### Standard Mode
Generate CLAUDE.md with auto-detected standards and testing protocols.

**Usage**: `/setup [directory]`

**Behavior**: Automatically switches to analysis mode if CLAUDE.md exists (unless --force used).

**Example**:
```bash
/setup              # Creates CLAUDE.md in project root
/setup /path/to/dir # Creates CLAUDE.md in specified directory
```

### Analysis Mode
Diagnose existing CLAUDE.md and create comprehensive analysis report.

**Trigger**: Automatic when CLAUDE.md exists in target directory.

**Validation**: Checks required sections and metadata format.

**Output**: Topic-based analysis report in `.claude/specs/NNN_topic/reports/`

**Example**:
```bash
/setup  # If CLAUDE.md exists, automatically analyzes it
```

### Force Mode
Overwrite existing CLAUDE.md without automatic mode detection.

**Usage**: `/setup --force`

**Use Case**: Regenerate CLAUDE.md from scratch when existing file should be replaced.

**Example**:
```bash
/setup --force  # Overwrites existing CLAUDE.md
```

## Related Commands

For CLAUDE.md optimization, cleanup, and enhancement operations, use `/optimize-claude`.

**Architecture**: This command follows the [Executable/Documentation Separation Pattern](../concepts/patterns/executable-documentation-separation.md). The executable file (setup.md) contains lean execution logic with bash blocks and verification checkpoints. This guide contains comprehensive architecture, usage examples, and troubleshooting.

## Core Utilities

### 1. Testing Detection (`detect-testing.sh`)

Score-based testing framework detection (0-6 points).

**Usage**:
```bash
.claude/lib/util/detect-testing.sh [directory]
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
$ .claude/lib/util/detect-testing.sh /home/benjamin/.config
SCORE:1
FRAMEWORKS:plenary bash-tests
```

### 2. Testing Protocol Generation (`generate-testing-protocols.sh`)

Generates adaptive testing protocols based on confidence score.

**Usage**:
```bash
.claude/lib/util/generate-testing-protocols.sh <score> <frameworks>
```

**Confidence Levels**:
- **High (≥4)**: Full protocols with framework-specific commands, TDD guidance
- **Medium (2-3)**: Brief protocols with expansion suggestions
- **Low (0-1)**: Minimal placeholder or recommendations

**Example**:
```bash
$ .claude/lib/util/generate-testing-protocols.sh 5 "pytest jest"
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

**Rationale**: Command files are AI execution scripts, not documentation. Over-extraction of command content violates [Command Architecture Standards - Standard 1 (Inline Execution)](../reference/architecture/overview.md#standard-1), which requires workflow logic, tool invocations, and decision points to remain inline for direct AI interpretation.

**Usage**:
```bash
.claude/lib/util/optimize-claude-md.sh [file] [options]

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
$ .claude/lib/util/optimize-claude-md.sh CLAUDE.md --dry-run --balanced

# Output shows:
# - Section analysis table (name, lines, status, recommendation)
# - Bloated sections count
# - Projected savings
# - Current vs target size
# - Reduction percentage
```

**Automatic Backup**: Creates timestamped backups in `.claude/backups/` before modifications.

## Usage Patterns

### Pattern 1: New Project Setup

```bash
# First run: Create CLAUDE.md with automatic standards detection
/setup

# Second run: Automatically analyzes the created CLAUDE.md
/setup
```

### Pattern 2: Analyze Existing CLAUDE.md

```bash
# Automatic analysis (no flag needed)
/setup

# Review the generated report
cat .claude/specs/NNN_*/reports/001_standards_analysis.md
```

### Pattern 3: Regenerate CLAUDE.md

```bash
# Force overwrite existing CLAUDE.md
/setup --force

# Verify new file created
cat CLAUDE.md
```

### Pattern 4: Subdirectory Setup

```bash
# From subdirectory - operates on project root by default
cd /project/src/components
/setup

# Creates /project/CLAUDE.md (not /project/src/components/CLAUDE.md)
```

### Pattern 5: Optimize Existing CLAUDE.md

```bash
# First analyze to identify issues
/setup

# Review report for optimization recommendations
cat .claude/specs/NNN_*/reports/001_standards_analysis.md

# Apply optimizations using /optimize-claude
/optimize-claude
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
.claude/lib/util/detect-testing.sh .
```

### Issue: README generation creates too many files

**Cause**: Project has many small directories

**Solution**: Use generate_readme() for specific directories only:

### Issue: Optimization utility shows no bloated sections

**Cause**: CLAUDE.md is already well-optimized

**Solution**: This is good! Use --aggressive profile if you still want extractions:
```bash
.claude/lib/util/optimize-claude-md.sh CLAUDE.md --aggressive
```

### Issue: Generated protocols don't match project needs

**Cause**: Framework detection missed custom setup

**Solution**: Manually edit generated protocols or improve detection:
```bash
# Add framework config files
touch pytest.ini  # or jest.config.js, etc.

# Re-detect
.claude/lib/util/detect-testing.sh .
```

### Issue: CLAUDE.md validation fails with missing sections

**Cause**: Required sections not present or incorrectly formatted

**Solution**: Check for required `[Used by: ...]` metadata:
```bash
# Validate structure
/setup --validate

# Review validation report for specific missing sections
# Add missing sections using analysis mode
/setup --analyze
```

### Issue: CLAUDE.md validation shows missing sections

**Cause**: Required sections not present in CLAUDE.md

**Solution**: Review analysis report and add missing sections:
```bash
# Run analysis to identify issues
/setup

# Review report
cat .claude/specs/NNN_*/reports/001_standards_analysis.md

# Edit CLAUDE.md to add missing sections
# Then re-analyze to verify
/setup
```

### Issue: Analysis mode not triggering automatically

**Cause**: CLAUDE.md file doesn't exist in target directory

**Solution**: Verify file exists or create it first:
```bash
# Check if file exists
ls -la CLAUDE.md

# If missing, create it first
/setup --force

# Then analyze
/setup
```

### Issue: Want to optimize CLAUDE.md but /setup only analyzes

**Cause**: /setup handles initialization and diagnostics only

**Solution**: Use /optimize-claude for cleanup and enhancement:
```bash
# First analyze to identify issues
/setup

# Then optimize
/optimize-claude
```

### Issue: Enhancement mode fails to discover documentation

**Cause**: Documentation not in standard locations or no .claude/docs/ directory

**Solution**: Ensure documentation is discoverable:
```bash
# Check if docs exist
ls -la .claude/docs/

# Create if missing
mkdir -p .claude/docs/

# Run enhancement
/setup --enhance-with-docs
```

### Issue: Multiple CLAUDE.md files found in project

**Cause**: CLAUDE.md in multiple directories (main + subdirectories)

**Solution**: Use specific directory argument:
```bash
# Target specific directory
/setup /path/to/main/project

# For subdirectory-specific standards
/setup /path/to/subdirectory
```

### Issue: Permission errors during file creation

**Cause**: Insufficient permissions for target directory

**Solution**: Check directory permissions:
```bash
# Check permissions
ls -ld .claude/docs/

# Fix if needed
chmod u+w .claude/docs/

# Re-run setup
/setup
```

## Best Practices

### CLAUDE.md Workflow

1. **Initial Setup**: Run /setup to create CLAUDE.md with auto-detected standards
2. **Analysis**: Run /setup again to validate structure and identify issues
3. **Optimization**: Use /optimize-claude for cleanup and enhancement
4. **Maintenance**: Periodically re-analyze to catch configuration drift

### Testing Documentation

1. **High Confidence (≥4)**: Document test commands, CI integration, coverage
2. **Medium Confidence (2-3)**: Document basic commands, note missing infrastructure
3. **Low Confidence (0-1)**: Add minimal placeholder, suggest improvements

### Command Separation

**Use /setup for**:
- Creating initial CLAUDE.md files
- Validating CLAUDE.md structure
- Analyzing standards completeness

**Use /optimize-claude for**:
- Cleanup and section extraction
- Enhancement with documentation discovery
- Applying optimization recommendations

## Utility Integration

The core utilities (detect-testing.sh, generate-testing-protocols.sh, optimize-claude-md.sh) work independently and are used by /setup internally:

- **detect-testing.sh**: Testing framework detection (used by /setup standard mode)
- **generate-testing-protocols.sh**: Protocol generation (used by /setup standard mode)
- **optimize-claude-md.sh**: CLAUDE.md optimization (used by /optimize-claude)

Use /setup for initialization and diagnostics. Use /optimize-claude for maintenance and improvements.

## Advanced Topics

### Extraction Strategies

Learn about the smart extraction system for optimizing CLAUDE.md by moving detailed content to auxiliary files. Covers extraction mapping, interactive processes, threshold settings, and dry-run previews.

See [Extraction Strategies](../setup/extraction-strategies.md) for complete documentation including:
- Smart section extraction with interactive selection
- Threshold settings (aggressive/balanced/conservative)
- Dry-run preview mode
- Optimal CLAUDE.md structure

### Standards Analysis

Comprehensive guide to analyzing CLAUDE.md against codebase patterns and configuration files. Includes 5 discrepancy types, gap-filling workflows, and automated report application.

See [Standards Analysis](../setup/standards-analysis.md) for complete documentation including:
- Analysis mode workflow (3-source comparison)
- Report application mode (automated reconciliation)
- Integration examples and best practices

### Setup Command Modes

Detailed documentation for all 6 command modes: Standard, Cleanup, Validation, Analysis, Report Application, and Enhancement. Includes workflow diagrams and selection guides.

See [Setup Modes](../setup/setup-modes-detailed.md) for complete documentation including:
- Mode-by-mode feature comparison
- Cleanup workflow diagram
- Mode selection decision tree
- Common workflow patterns

### Bloat Detection

Automatic optimization detection system that prompts for cleanup when CLAUDE.md exceeds size thresholds. Covers detection logic, user interaction, and threshold rationale.

See [Bloat Detection](../setup/bloat-detection.md) for complete documentation including:
- Detection thresholds (200 lines, 30 lines/section)
- User prompt responses (Y/n/c)
- Opt-out mechanisms
- Integration with cleanup mode

## See Also

- [CLAUDE.md](../../../CLAUDE.md) - Project standards file
- [Command Architecture Standards](../reference/architecture/overview.md) - Command design patterns
- [Development Workflow](../concepts/development-workflow.md) - Spec updater integration
