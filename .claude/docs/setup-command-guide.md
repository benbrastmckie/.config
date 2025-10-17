# /setup Command and Utilities Guide

## Overview

The /setup command ecosystem provides tools for creating and maintaining optimal CLAUDE.md files with intelligent context management.

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

## Examples

See `.claude/examples/setup/` for complete examples:
- `example_01_optimization.md` - Optimizing bloated CLAUDE.md
- `example_02_testing_detection.md` - Generating testing protocols
- `example_03_readme_coverage.md` - Systematic documentation

## See Also

- [CLAUDE.md](../CLAUDE.md) - Project standards file
- [Command Architecture Standards](command_architecture_standards.md) - Command design patterns
- [Development Workflow](development-workflow.md) - Spec updater integration
