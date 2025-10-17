# /setup Command Improvement Recommendations: Lean CLAUDE.md Generation

## Metadata
- **Date**: 2025-10-16
- **Report Number**: 050
- **Scope**: Comprehensive analysis of /setup command improvements for lean CLAUDE.md generation, adaptive testing detection, systematic README automation, and multi-repository optimization
- **Primary Directory**: .claude/commands/
- **Files Analyzed**: 15+ files including setup.md, CLAUDE.md, test utilities, documentation standards
- **Research Duration**: 45 minutes (4 parallel research agents)

## Executive Summary

The current `/setup` command (648 lines) generates comprehensive CLAUDE.md files but suffers from bloat, manual configuration, and lack of adaptability across repositories. Research identified five critical improvement areas:

1. **Context Optimization**: Reduce CLAUDE.md to <500 lines via aggressive inline/reference separation following 2025 AI assistant best practices
2. **Adaptive Testing Detection**: Score-based framework detection (0-5 points) to conditionally generate testing protocols only when systematic testing detected
3. **Systematic README Automation**: Template-based skeleton generation with automated parent/child/sibling cross-linking
4. **Incremental Updates**: Targeted section regeneration vs full file replacement
5. **Multi-Repository Adaptation**: Hierarchical configs (root general + subdirectory-specific) with language-agnostic detection

**Key Findings**: Current implementation uses AI-driven generation (no executable scripts), hardcoded test protocols, manual threshold selection for cleanup mode, and config parsing limited to 3 file types. Industry best practices emphasize lean configs (<500 lines), context caching optimization (75% cost reduction), progressive disclosure (inline essentials, reference details), and RAG integration (70% prompt size reduction).

**Recommended Approach**: Implement 5-phase enhancement: (1) score-based testing detection utility, (2) README template scaffolding, (3) context optimization analyzer, (4) incremental section updater, (5) hierarchical config support. Expected outcome: 40-60% CLAUDE.md size reduction, 100% README coverage, zero manual configuration for common patterns.

## Background

### Current /setup Implementation

**Location**: `/home/benjamin/.config/.claude/commands/setup.md`

**Operational Modes** (5 total):
1. **Standard Mode**: Generates/updates CLAUDE.md with auto-bloat detection (>200 lines triggers cleanup prompt)
2. **Cleanup Mode** (`--cleanup`): Extracts verbose sections (>30 lines) to auxiliary files in `docs/`
3. **Validation Mode** (`--validate`): Verifies structure and linked file existence
4. **Analysis Mode** (`--analyze`): Detects discrepancies between CLAUDE.md, codebase patterns, config files
5. **Report Application** (`--apply-report`): Parses gap analysis reports to update CLAUDE.md

**CLAUDE.md Sections Generated**:
- Code Standards (language-specific indent, naming, error handling)
- Testing Protocols (commands, coverage requirements)
- Documentation Policy (README requirements, format standards)
- Directory Protocols (specs/ structure, artifact lifecycle)
- Development Philosophy (clean-break refactors, timeless documentation)
- Standards Discovery (upward search, subdirectory merging)
- Command Integration (metadata: `[Used by: commands]`)

**Detection Mechanisms**:
- **Project Type Inference**: File pattern matching (*.lua → Neovim, package.json → Node, *.py → Python)
- **Codebase Sampling**: First 40-47 files analyzed for indent style (>50% confidence), naming conventions (>70% confidence)
- **Config File Parsing**: .editorconfig, package.json, stylua.toml (hardcoded list)
- **Test Framework Detection**: Basic directory/file presence checks

**Reference File Handling**:
- Links to extracted `docs/` files
- Preserves cross-references during extraction
- Updates navigation breadcrumbs
- Interactive threshold selection (aggressive >20 lines, balanced >30 lines, conservative >50 lines)

**Key Limitations**:
1. **No Incremental Generation**: Full CLAUDE.md regeneration rather than targeted section updates
2. **AI Instruction-Based**: No executable setup scripts; relies entirely on AI interpreting command file instructions
3. **Manual Threshold Selection**: Interactive prompts required; no automatic profile detection
4. **Config Parsing Hardcoded**: Limited to 3 specific file types; not extensible to arbitrary config formats
5. **Bloated Output**: Current CLAUDE.md is 648 lines, demonstrating need for optimization
6. **Hardcoded Testing Protocols**: No adaptive generation based on detected test frameworks

### Problem Statement

**Multi-Repository Challenge**: Users apply `/setup` across diverse repositories (Neovim configs, web apps, CLI tools, documentation projects) requiring context-aware adaptation while maintaining common principles.

**Conflicting Requirements**:
- **Lean vs Comprehensive**: Need concise CLAUDE.md (<500 lines) but comprehensive project documentation
- **Adaptive vs Standardized**: Must adapt to project-specific patterns while enforcing common standards
- **Automated vs Configurable**: Reduce manual configuration but allow user customization
- **Testing Enforcement**: Promote TDD where appropriate without dogmatic enforcement in non-applicable contexts

**Documentation Gaps**:
- 62+ READMEs exist but backward links (child→parent) inconsistent
- No automated README generation for new directories
- Cross-reference integrity not validated
- Manual effort required for systematic documentation

**Context Window Concerns**:
- Large CLAUDE.md files consume significant context budget
- Duplicated content (inline + referenced) wastes tokens
- Inefficient for projects with extensive standards
- 2025 best practices emphasize context caching and lean configs

## Current State Analysis

### CLAUDE.md Structure Analysis

**Current File Size**: 648 lines (exceeds recommended 500-line limit)

**Content Breakdown**:
- **Project Standards Index**: 25 lines (4%)
- **Code Standards**: 45 lines (7%)
- **Testing Protocols**: 35 lines (5%) - Hardcoded, not adaptive
- **Documentation Policy**: 55 lines (8%)
- **Directory Protocols**: 185 lines (29%) - Most verbose section
- **Development Philosophy**: 95 lines (15%)
- **Development Workflow**: 75 lines (12%)
- **Project-Specific Commands**: 85 lines (13%)
- **Quick Reference**: 30 lines (5%)
- **Notes**: 18 lines (3%)

**Inline vs Referenced**:
- **Currently Inline** (should be referenced): Directory Protocols details (185 lines), Development Philosophy prose (95 lines), extensive command documentation (85 lines)
- **Currently Referenced**: nvim/CLAUDE.md, nvim/docs/CODE_STANDARDS.md, nvim/docs/DOCUMENTATION_STANDARDS.md
- **Optimization Opportunity**: Move 250+ lines to reference files → reduce to ~400 lines

### Testing Detection Current State

**Current Approach**: Hardcoded testing protocols in CLAUDE.md regardless of project type.

**Example Hardcoded Content** (lines 204-238):
```markdown
## Testing Protocols
[Used by: /test, /test-all, /implement]

### Claude Code Testing
- **Test Location**: `.claude/tests/`
- **Test Runner**: `./run_all_tests.sh`
- **Test Pattern**: `test_*.sh` (Bash test scripts)
...

### Neovim Testing
- **Test Commands**: `:TestNearest`, `:TestFile`, `:TestSuite`, `:TestLast`
- **Test Pattern**: `*_spec.lua`, `test_*.lua` files in `tests/` or adjacent to source
...

### Coverage Requirements
- Aim for >80% coverage on new code
- All public APIs must have tests
...
```

**Problems**:
1. **No Detection Logic**: Assumes testing always present and systematic
2. **Project-Specific**: Hardcoded for this specific config repo (bash tests + Neovim tests)
3. **Not Transferable**: Copy to web app repo would show irrelevant bash/Neovim commands
4. **Manual Updates**: User must edit CLAUDE.md for each new project type

**What's Needed**: Score-based detection system that generates testing section conditionally based on evidence.

### Documentation Coverage Analysis

**README.md Distribution**:
```
/home/benjamin/.config/          README.md ✓
├── .claude/                     README.md ✓
│   ├── commands/                README.md ✓
│   ├── lib/                     README.md ✓
│   ├── agents/                  README.md ✓
│   ├── templates/               README.md ✓
│   ├── docs/                    README.md ✓
│   └── tests/                   README.md ✓
├── nvim/                        README.md ✓
│   ├── lua/neotex/             README.md ✓
│   │   ├── core/               README.md ✓
│   │   ├── plugins/            README.md ✓
│   │   │   ├── ai/             README.md ✓
│   │   │   ├── coding/         README.md ✓
│   │   │   └── ui/             README.md ✓
│   ├── docs/                   README.md ✓
│   └── specs/                  README.md ✓
```

**Coverage Metrics**:
- Total directories: ~150
- Directories with README: 62+ (41% coverage)
- Directories without README: ~88 (59% - improvement opportunity)

**Cross-Linking Patterns**:

**Forward Links (Parent → Child)**: ✓ Well-established
```markdown
## Subdirectories
- [commands/](commands/README.md) - Slash command implementations
- [lib/](lib/README.md) - Shared utility libraries
- [agents/](agents/README.md) - Specialized AI agent roles
```

**Backward Links (Child → Parent)**: ⚠ Inconsistent
```markdown
# Some READMEs include:
[← Parent](.../README.md)

# Most READMEs lack backward navigation
```

**Horizontal Links (Sibling Cross-References)**: ⚠ Ad-hoc
```markdown
## Related Documentation
- [AI Plugins](../ai/README.md) - Related AI functionality
- [LSP Plugins](../lsp/README.md) - Language server integration
```

**Gap Analysis**:
- Backward links present in ~30% of READMEs
- Horizontal links present in ~15% of READMEs
- No automated validation of link integrity
- No standard placement for navigation sections

### Context Optimization Opportunities

**2025 AI Assistant Best Practices** (from web research):

**Context Caching Benefits**:
- 75% cost reduction for cached tokens
- Ideal for repeated CLAUDE.md content across sessions
- Requires structured, stable content blocks

**RAG Integration**:
- 70% reduction in prompt sizes for complex tasks
- Dynamically retrieves only relevant information
- Reduces need for comprehensive inline documentation

**Token Budget Guidance**:
- Classification tasks: 50-200 tokens
- Generation tasks: 500-1,500 tokens
- Reasoning tasks: 4,000-8,000 tokens
- **CLAUDE.md should target**: <2,000 tokens (~500 lines) for classification/generation workflows

**Inline vs Referenced Guidelines**:

**Should Be Inline** (critical context):
- Common slash commands and their usage
- Code style guidelines (indent, naming, error handling)
- Anti-patterns to eliminate
- Brief testing instructions
- Architecture pattern summaries

**Should Be Referenced** (detailed content):
- Detailed technical specifications
- Comprehensive API documentation
- Architecture diagrams and deep-dives
- Historical context and migration guides
- Extensive code examples

**Current CLAUDE.md Violations**:
- Directory Protocols (185 lines): Should be referenced
- Development Philosophy prose (95 lines): Should be summarized inline, detailed in reference
- Extensive command docs (85 lines): Should link to command README with 2-line summaries

**Optimization Potential**:
```
Current:  648 lines (~2,600 tokens)
Target:   400 lines (~1,600 tokens)
Savings:  248 lines (~1,000 tokens) = 38% reduction
```

## Key Findings

### Finding 1: Score-Based Testing Detection is Feasible

**Detection Indicators** (weighted scoring system):

| Indicator | Weight | Detection Method | Example |
|-----------|--------|------------------|---------|
| CI/CD configs | 2 | `.github/workflows/*.yml`, `.gitlab-ci.yml` | `test.yml` with `pytest` job |
| Test directories | 1 | `find . -type d -name "tests"` | `tests/`, `__tests__/`, `spec/` |
| Test files (10+) | 1 | `find . -name "*test*" -o -name "*spec*"` | `test_auth.py`, `api.test.js` |
| Coverage tools | 1 | `.coveragerc`, `jest.config.js`, `coverage.xml` | `pytest-cov` in `requirements.txt` |
| Test runners | 1 | Executable test scripts | `run_tests.sh`, `Makefile` with `test:` |

**Scoring Thresholds**:
- **High Confidence (≥4 points)**: Generate full testing protocols + TDD guidance
- **Medium Confidence (2-3 points)**: Generate brief protocols + "expand as needed" suggestion
- **Low Confidence (0-1 points)**: Omit testing section or add minimal placeholder

**Framework Detection** (language-specific):

```bash
# Python
grep -r "import pytest" . || grep -r "import unittest" . → pytest/unittest
pyproject.toml with [tool.pytest.ini_options] → pytest
requirements.txt with "pytest" → pytest

# JavaScript/TypeScript
package.json with "jest" or "vitest" or "mocha" → framework
*.test.js or *.spec.js → likely jest/vitest
jest.config.js or vitest.config.ts → explicit framework

# Lua (Neovim)
*_spec.lua → plenary.nvim or busted
tests/ with lua files → likely Neovim testing

# Rust
Cargo.toml with [dev-dependencies] → cargo test
tests/ directory → standard Rust testing

# Go
*_test.go → standard Go testing
```

**Adaptive Generation Examples**:

**High Confidence** (Python project with pytest, CI, coverage):
```markdown
## Testing Protocols
[Used by: /test, /test-all, /implement]

### Test Framework
- **Framework**: pytest
- **Test Location**: `tests/`
- **Test Pattern**: `test_*.py`, `*_test.py`
- **Test Command**: `pytest`
- **Coverage**: `pytest --cov=src --cov-report=html`

### TDD Workflow
This project uses Test-Driven Development:
1. Write failing test first
2. Implement minimum code to pass
3. Refactor while keeping tests green
4. Maintain >80% coverage on new code

### CI Integration
Tests run automatically on push via `.github/workflows/test.yml`
```

**Medium Confidence** (JavaScript project with some test files, no CI):
```markdown
## Testing Protocols
[Used by: /test, /test-all, /implement]

### Test Setup
- **Test Files**: `*.test.js` files found in project
- **Framework**: Not detected (configure as needed)
- **Suggested Command**: `npm test`

Tests are present but not systematically configured. Consider:
- Adding jest or vitest configuration
- Setting up CI/CD for automatic testing
- Establishing coverage thresholds
```

**Low Confidence** (Documentation project, no tests):
```markdown
## Testing Protocols
[Used by: /test, /test-all, /implement]

No systematic testing detected. If testing is needed for this project, add:
- Test framework appropriate for project type
- Test directory structure
- CI/CD configuration for automated testing
```

### Finding 2: README Automation Requires Three-Level Linking

**Template Structure**:

```markdown
# [Directory Name]

## Purpose
[FILL IN: Brief description of this directory's role]

## Contents

[AUTO-GENERATE: List of files with descriptions]
- `file1.ext` - [FILL IN: Purpose]
- `file2.ext` - [FILL IN: Purpose]

## Modules

[AUTO-GENERATE: Subdirectories if any]
- [subdir1/](subdir1/README.md) - [FILL IN: Purpose]

## Usage

[CONDITIONAL: Include if code files present]
[FILL IN: Usage examples]

## Navigation

[AUTO-GENERATE: Parent link]
← [Parent Directory](../README.md)

[AUTO-GENERATE: Subdirectory links]
→ [Subdirectory 1](subdir1/README.md)
→ [Subdirectory 2](subdir2/README.md)

[MANUAL: Related documentation]
### Related Documentation
- [Related Dir](../related/README.md) - Cross-reference description
```

**Automation Logic**:

```bash
# Pseudocode for README generation
generate_readme() {
  local dir="$1"
  local readme="$dir/README.md"

  # Extract directory name
  dir_name=$(basename "$dir")

  # Find parent directory
  parent_dir=$(dirname "$dir")
  parent_readme="$parent_dir/README.md"

  # Find subdirectories with significance (exclude hidden, node_modules, etc.)
  subdirs=$(find "$dir" -maxdepth 1 -type d ! -name ".*" ! -name "node_modules" ! -name "dist")

  # Find files
  files=$(find "$dir" -maxdepth 1 -type f ! -name ".*" ! -name "README.md")

  # Generate template
  cat > "$readme" <<EOF
# $dir_name

## Purpose
[FILL IN: Brief description of this directory's role]

## Contents
$(for file in $files; do
  echo "- \`$(basename $file)\` - [FILL IN: Purpose]"
done)

## Modules
$(for subdir in $subdirs; do
  echo "- [$(basename $subdir)/]($(basename $subdir)/README.md) - [FILL IN: Purpose]"
done)

## Navigation

← [Parent Directory]($parent_readme)

$(for subdir in $subdirs; do
  echo "→ [$(basename $subdir)]($(basename $subdir)/README.md)"
done)
EOF
}
```

**Integration with /setup**:

```markdown
## /setup --generate-readmes

Scan project for directories lacking README.md:
1. Find directories without README.md
2. For each directory:
   - Generate skeleton README with template
   - Auto-populate navigation links
   - Mark content sections with [FILL IN:] placeholders
   - Preserve existing READMEs (no overwrite)
3. Report:
   - READMEs created: N
   - Directories covered: N/M (N%)
   - User action required: Fill [FILL IN:] sections
```

### Finding 3: Hierarchical Configs Enable Multi-Repository Usage

**Problem**: Single CLAUDE.md doesn't adapt well across repository types (Neovim config vs web app vs CLI tool).

**Solution**: Hierarchical configuration with root-level general standards + subdirectory-specific overrides.

**Structure**:

```
my-monorepo/
├── CLAUDE.md                    # General standards (lean, 200-300 lines)
│   └── References:
│       - docs/architecture.md
│       - docs/development-workflow.md
│       - docs/testing-strategy.md
├── docs/
│   ├── architecture.md           # Detailed architecture
│   ├── development-workflow.md   # Workflow details
│   └── testing-strategy.md       # Testing details
├── frontend/
│   └── .claude.md                # Frontend-specific (TypeScript, React)
│       ├── Style: Prettier, ESLint
│       ├── Testing: Vitest, React Testing Library
│       └── References:
│           - ../docs/frontend-architecture.md
├── backend/
│   └── .claude.md                # Backend-specific (Python, FastAPI)
│       ├── Style: Black, Ruff
│       ├── Testing: Pytest, 80% coverage
│       └── References:
│           - ../docs/api-design.md
└── docs/
    ├── frontend-architecture.md
    └── api-design.md
```

**Root CLAUDE.md** (lean, 250 lines):
```markdown
# Project Configuration Index

## Project Overview
- **Name**: MyMonorepo
- **Type**: Full-stack web application
- **Architecture**: Microservices with React frontend, FastAPI backend

## Standards Discovery

Commands should discover standards by:
1. Searching upward from current directory for CLAUDE.md
2. Checking for subdirectory `.claude.md` files
3. Merging: subdirectory standards extend/override root standards

## Core Standards

### Code Style
- Follow language-specific standards in subdirectory configs
- See: [Code Standards](docs/code-standards.md)

### Testing
- All code requires tests (see subdirectory configs for framework-specific)
- Coverage: >80% new code, >60% baseline
- See: [Testing Strategy](docs/testing-strategy.md)

### Documentation
- Every directory requires README.md
- See: [Documentation Standards](docs/documentation-standards.md)

## Subdirectory Configurations
- [frontend/.claude.md](frontend/.claude.md) - TypeScript/React standards
- [backend/.claude.md](backend/.claude.md) - Python/FastAPI standards

## Development Workflow
See: [Development Workflow](docs/development-workflow.md)
```

**Subdirectory .claude.md** (frontend, 150 lines):
```markdown
# Frontend Configuration

**Extends**: [Root CLAUDE.md](../CLAUDE.md)

## Language-Specific Standards

### TypeScript
- Indent: 2 spaces
- Naming: camelCase for variables/functions, PascalCase for components
- Error Handling: try-catch with typed errors

### React
- Functional components with hooks
- Props: TypeScript interfaces
- State: Zustand for global, useState for local

## Testing Protocols

### Framework
- **Framework**: Vitest + React Testing Library
- **Test Location**: `__tests__/` or `*.test.tsx` adjacent to source
- **Test Command**: `npm test`
- **Coverage**: `npm run test:coverage`

### Testing Patterns
- Unit tests for utilities and hooks
- Component tests for UI components
- Integration tests for feature flows

## Architecture
See: [Frontend Architecture](../docs/frontend-architecture.md)
```

**Standards Discovery Algorithm**:

```bash
# Pseudocode for discovering standards
discover_standards() {
  local current_dir="$1"
  local standards=()

  # 1. Search upward for CLAUDE.md (root standards)
  local search_dir="$current_dir"
  while [[ "$search_dir" != "/" ]]; do
    if [[ -f "$search_dir/CLAUDE.md" ]]; then
      standards+=("$search_dir/CLAUDE.md")
      break
    fi
    search_dir=$(dirname "$search_dir")
  done

  # 2. Search for subdirectory-specific .claude.md
  search_dir="$current_dir"
  while [[ "$search_dir" != "/" ]]; do
    if [[ -f "$search_dir/.claude.md" ]]; then
      standards+=("$search_dir/.claude.md")
    fi
    search_dir=$(dirname "$search_dir")
  done

  # 3. Merge standards (subdirectory overrides root)
  # Return most specific → most general order
  printf '%s\n' "${standards[@]}"
}
```

**Benefits**:
1. **Lean Root Config**: 200-300 lines covering general standards
2. **Context-Specific**: Each subdirectory gets relevant standards only
3. **DRY Principle**: Common standards in root, exceptions in subdirectories
4. **Scalable**: Add new subdirectories without bloating root config
5. **Multi-Repository**: Same pattern works across different project types

### Finding 4: Incremental Updates Reduce Regeneration Overhead

**Current Problem**: `/setup` regenerates entire CLAUDE.md even for small changes.

**Proposed Solution**: Section-based incremental updates.

**CLAUDE.md Section Markers**:

```markdown
# Project Configuration Index

<!-- SECTION: project_overview -->
## Project Overview
...
<!-- END_SECTION: project_overview -->

<!-- SECTION: code_standards -->
## Code Standards
...
<!-- END_SECTION: code_standards -->

<!-- SECTION: testing_protocols -->
## Testing Protocols
...
<!-- END_SECTION: testing_protocols -->

<!-- SECTION: documentation_policy -->
## Documentation Policy
...
<!-- END_SECTION: documentation_policy -->
```

**Incremental Update Commands**:

```bash
# Update only testing protocols
/setup --update-section testing_protocols

# Update multiple sections
/setup --update-sections code_standards,testing_protocols

# Regenerate all sections (full update)
/setup --regenerate
```

**Implementation**:

```bash
# Pseudocode for incremental update
update_section() {
  local section_name="$1"
  local claude_md="CLAUDE.md"

  # 1. Detect project characteristics for this section
  case "$section_name" in
    "testing_protocols")
      score=$(detect_testing_score)
      new_content=$(generate_testing_protocols "$score")
      ;;
    "code_standards")
      lang=$(detect_primary_language)
      new_content=$(generate_code_standards "$lang")
      ;;
  esac

  # 2. Find section boundaries
  start_marker="<!-- SECTION: $section_name -->"
  end_marker="<!-- END_SECTION: $section_name -->"

  # 3. Replace section content
  awk -v start="$start_marker" -v end="$end_marker" -v content="$new_content" '
    $0 ~ start { print; print content; in_section=1; next }
    $0 ~ end { in_section=0 }
    !in_section
  ' "$claude_md" > "$claude_md.tmp"

  mv "$claude_md.tmp" "$claude_md"
}
```

**Benefits**:
- Faster execution (update only changed sections)
- Preserves manual customizations in other sections
- Clearer git diffs (only updated sections change)
- Enables periodic "refresh" of specific sections

### Finding 5: Context Optimization Requires Analyzer Tool

**Goal**: Automatically identify CLAUDE.md bloat and suggest optimizations.

**/setup --optimize** (new mode):

```bash
/setup --optimize [--dry-run]
```

**Optimization Analysis**:

```markdown
# Context Optimization Report

## Current Stats
- **Total Lines**: 648
- **Total Tokens**: ~2,600 (estimate)
- **Target**: <500 lines, <2,000 tokens

## Sections Analysis

| Section | Lines | Status | Recommendation |
|---------|-------|--------|----------------|
| Project Overview | 25 | ✓ Optimal | Keep inline |
| Code Standards | 45 | ⚠ Moderate | Keep inline (essential) |
| Testing Protocols | 35 | ⚠ Moderate | Keep inline (frequently used) |
| Documentation Policy | 55 | ⚠ Moderate | Summarize inline, details → docs/ |
| Directory Protocols | 185 | ✗ Bloated | Extract to docs/directory-protocols.md |
| Development Philosophy | 95 | ✗ Bloated | Extract to docs/development-philosophy.md |
| Development Workflow | 75 | ⚠ Moderate | Summarize inline, details → docs/ |
| Project Commands | 85 | ⚠ Moderate | 2-line summaries, details → commands/README.md |
| Quick Reference | 30 | ✓ Optimal | Keep inline |
| Notes | 18 | ✓ Optimal | Keep inline |

## Optimization Opportunities

### High Priority (200+ lines reduction)
1. **Extract Directory Protocols** (185 lines → 20 lines)
   - Move to: `docs/directory-protocols.md`
   - Inline summary: "See [Directory Protocols](docs/directory-protocols.md) for specs/ structure"

2. **Extract Development Philosophy** (95 lines → 15 lines)
   - Move to: `docs/development-philosophy.md`
   - Inline summary: "See [Development Philosophy](docs/development-philosophy.md) for clean-break refactors, timeless documentation"

### Medium Priority (80 lines reduction)
3. **Summarize Development Workflow** (75 lines → 25 lines)
   - Move details to: `docs/development-workflow.md`
   - Keep inline: Workflow phase names, link to details

4. **Summarize Project Commands** (85 lines → 30 lines)
   - Keep inline: Command name + 1-line description
   - Details in: `.claude/commands/README.md`

### Low Priority (30 lines reduction)
5. **Condense Documentation Policy** (55 lines → 35 lines)
   - Move examples to: `docs/documentation-standards.md`
   - Keep inline: Core requirements only

## Projected Results

**After Optimization**:
- Total Lines: 648 → 380 (41% reduction)
- Total Tokens: ~2,600 → ~1,520 (42% reduction)
- Context Budget: Well within optimal range

**Actions** (run with /setup --optimize):
- Create `docs/directory-protocols.md`
- Create `docs/development-philosophy.md`
- Update `docs/development-workflow.md`
- Extract inline content to reference files
- Replace with concise summaries + links
```

**Implementation Pattern**:

```bash
# Pseudocode for context optimizer
analyze_claude_md() {
  local claude_md="CLAUDE.md"

  # 1. Parse sections and count lines
  sections=$(awk '/^## / {print $0}' "$claude_md")

  for section in $sections; do
    # Extract section content
    start_line=$(grep -n "^## $section" "$claude_md" | cut -d: -f1)
    next_section=$(grep -n "^## " "$claude_md" | awk -v start="$start_line" '$1 > start {print $1; exit}')
    section_lines=$((next_section - start_line))

    # Classify: optimal (<50 lines), moderate (50-80), bloated (>80)
    if [[ $section_lines -gt 80 ]]; then
      recommend_extract "$section" "$section_lines"
    elif [[ $section_lines -gt 50 ]]; then
      recommend_summarize "$section" "$section_lines"
    else
      recommend_keep "$section" "$section_lines"
    fi
  done

  # 2. Generate optimization report
  generate_report

  # 3. If not --dry-run, perform extractions
  if [[ "$dry_run" != "true" ]]; then
    perform_optimizations
  fi
}
```

## Recommendations

### Recommendation 1: Implement Score-Based Testing Detection

**Priority**: High
**Effort**: Medium (8-12 hours)
**Impact**: Eliminates inappropriate TDD enforcement, adapts to repository context

**Implementation Steps**:

1. **Create Testing Detection Utility** (`.claude/lib/detect-testing.sh`):
   ```bash
   #!/bin/bash
   # Returns testing score (0-6) and detected framework

   detect_testing_score() {
     local project_dir="${1:-.}"
     local score=0
     local frameworks=()

     # Check for CI/CD configs (weight: 2)
     if find "$project_dir" -path "*/.github/workflows/*.yml" -o -name ".gitlab-ci.yml" | grep -q .; then
       score=$((score + 2))
     fi

     # Check for test directories (weight: 1)
     if find "$project_dir" -type d \( -name "tests" -o -name "test" -o -name "__tests__" -o -name "spec" \) | grep -q .; then
       score=$((score + 1))
     fi

     # Check for test files (weight: 1 if >10 files)
     test_file_count=$(find "$project_dir" \( -name "*test*" -o -name "*spec*" \) -type f | wc -l)
     if [[ $test_file_count -gt 10 ]]; then
       score=$((score + 1))
     fi

     # Check for coverage tools (weight: 1)
     if find "$project_dir" -name ".coveragerc" -o -name "pytest.ini" -o -name "jest.config.js" | grep -q .; then
       score=$((score + 1))
     fi

     # Check for test runners (weight: 1)
     if find "$project_dir" -name "run_tests.sh" -o -name "run_tests.py" | grep -q .; then
       score=$((score + 1))
     fi

     # Detect framework
     if grep -rq "import pytest" "$project_dir" 2>/dev/null || [ -f "$project_dir/pytest.ini" ]; then
       frameworks+=("pytest")
     fi
     if grep -q '"jest"' "$project_dir/package.json" 2>/dev/null || [ -f "$project_dir/jest.config.js" ]; then
       frameworks+=("jest")
     fi
     if find "$project_dir" -name "*_spec.lua" | grep -q .; then
       frameworks+=("plenary")
     fi
     if [ -f "$project_dir/Cargo.toml" ] && grep -q "\[dev-dependencies\]" "$project_dir/Cargo.toml"; then
       frameworks+=("cargo-test")
     fi

     echo "SCORE:$score"
     echo "FRAMEWORKS:${frameworks[*]}"
   }
   ```

2. **Create Testing Protocol Generator** (`.claude/lib/generate-testing-protocols.sh`):
   ```bash
   generate_testing_protocols() {
     local score="$1"
     local frameworks="$2"

     if [[ $score -ge 4 ]]; then
       generate_full_protocols "$frameworks"
     elif [[ $score -ge 2 ]]; then
       generate_brief_protocols "$frameworks"
     else
       generate_minimal_protocols
     fi
   }
   ```

3. **Integrate with /setup**:
   - Add detection step in /setup analysis phase
   - Conditionally generate Testing Protocols section
   - Include detected frameworks in generated protocols

**Expected Output Examples**: See Finding 1 for full/medium/low confidence examples.

### Recommendation 2: Add Automated README Scaffolding

**Priority**: High
**Effort**: Medium (6-10 hours)
**Impact**: Systematic documentation coverage, eliminates manual README creation

**Implementation Steps**:

1. **Create README Generator** (`.claude/lib/generate-readme.sh`):
   - Template-based generation (see Finding 2 template)
   - Auto-detect parent/child relationships
   - Generate navigation links
   - Preserve existing READMEs

2. **Add /setup Flag**:
   ```bash
   /setup --generate-readmes [--force]

   Options:
     --generate-readmes  Create README.md for directories lacking one
     --force             Overwrite existing READMEs (use with caution)
   ```

3. **Integration Points**:
   - Scan project for directories without README
   - Generate skeleton with [FILL IN:] placeholders
   - Auto-populate file/subdirectory lists
   - Generate navigation sections
   - Report coverage metrics

**Directory Exclusions**:
- Hidden directories (.*) except .claude
- `node_modules/`, `dist/`, `build/`, `target/`
- `__pycache__/`, `.pytest_cache/`
- Minimal directories (<2 files and no subdirectories)

**Post-Generation Workflow**:
```bash
/setup --generate-readmes
# Output:
# Generated 23 README.md files
# Coverage: 85/150 directories (57% → 98%)
#
# Next steps:
# 1. Review generated READMEs
# 2. Fill [FILL IN: ...] placeholders
# 3. Customize navigation links as needed
# 4. Run /document to validate cross-references
```

### Recommendation 3: Implement Context Optimization Analyzer

**Priority**: High
**Effort**: Medium (8-12 hours)
**Impact**: 40-60% CLAUDE.md size reduction, improved context efficiency

**Implementation Steps**:

1. **Create Optimization Analyzer** (`.claude/lib/optimize-claude-md.sh`):
   ```bash
   analyze_bloat() {
     # Parse CLAUDE.md sections
     # Count lines per section
     # Classify: optimal (<50), moderate (50-80), bloated (>80)
     # Identify extraction candidates
     # Generate optimization report
   }

   perform_optimization() {
     # Extract bloated sections to docs/
     # Replace with concise summaries + links
     # Update cross-references
     # Validate link integrity
   }
   ```

2. **Add /setup Flag**:
   ```bash
   /setup --optimize [--dry-run] [--aggressive|--balanced|--conservative]

   Options:
     --optimize      Analyze and optimize CLAUDE.md for context efficiency
     --dry-run       Show optimization plan without applying changes
     --aggressive    Extract sections >50 lines
     --balanced      Extract sections >80 lines (default)
     --conservative  Extract sections >120 lines
   ```

3. **Section Extraction Logic**:
   - Identify bloated sections
   - Create reference files in `docs/`
   - Generate inline summaries (10-20% of original length)
   - Add cross-reference links
   - Preserve section markers for incremental updates

**Example Optimization** (Directory Protocols section):

**Before** (185 lines inline):
```markdown
## Directory Protocols

### Specifications Structure (`specs/`)
[Used by: /report, /plan, /implement, /list-plans, /list-reports, /list-summaries]

The specifications directory uses a uniform topic-based structure where all artifacts for a feature are organized together:

**Structure**: `specs/{NNN_topic}/{artifact_type}/NNN_artifact_name.md`

**Topic Directories** (`{NNN_topic}`):
- Three-digit numbered directories (001, 002, 003...)
- Each topic contains all artifacts for a feature or area
- Topic name describes the feature (e.g., `042_authentication`, `001_cleanup`)

[... 165 more lines ...]
```

**After** (20 lines inline, 165 lines in docs/directory-protocols.md):
```markdown
## Directory Protocols

### Specifications Structure
[Used by: /report, /plan, /implement, /list]

Specifications use topic-based organization: `specs/{NNN_topic}/{artifact_type}/NNN_artifact.md`

**Key Concepts**:
- Topic directories (001, 002, ...) group related artifacts
- Artifact types: plans/, reports/, summaries/, debug/ (committed)
- Numbered artifacts within each type
- Progressive plan expansion (Level 0 → 1 → 2)
- Phase dependencies enable parallel execution

See [Directory Protocols](docs/directory-protocols.md) for complete structure, lifecycle details, and examples.
```

### Recommendation 4: Add Hierarchical Config Support

**Priority**: Medium
**Effort**: Medium (6-8 hours)
**Impact**: Enables multi-repository usage, reduces root config bloat

**Implementation Steps**:

1. **Update Standards Discovery**:
   - Modify `/setup` to support `.claude.md` subdirectory configs
   - Generate root `CLAUDE.md` with general standards (200-300 lines)
   - Generate subdirectory `.claude.md` with specific overrides (100-200 lines)

2. **Create Config Discovery Utility** (`.claude/lib/discover-standards.sh`):
   ```bash
   discover_standards() {
     local current_dir="$1"

     # Search upward for CLAUDE.md
     # Search for subdirectory .claude.md
     # Return ordered list (most specific → most general)
   }
   ```

3. **Add /setup Workflow**:
   ```bash
   /setup                              # Generate/update root CLAUDE.md
   /setup --subdirectory frontend      # Generate frontend/.claude.md
   /setup --subdirectory backend       # Generate backend/.claude.md
   ```

4. **Subdirectory Config Template**:
   ```markdown
   # [Subdirectory] Configuration

   **Extends**: [Root CLAUDE.md](../CLAUDE.md)

   ## Language-Specific Standards
   [Detected language standards]

   ## Testing Protocols
   [Detected test framework for this subdirectory]

   ## Architecture
   See: [Detailed Architecture](../docs/[subdirectory]-architecture.md)
   ```

**Benefits for Multi-Repository Usage**:
- Neovim config repo: Root CLAUDE.md with Lua standards
- Web app repo: Root CLAUDE.md (general) + frontend/.claude.md (TS/React) + backend/.claude.md (Python/FastAPI)
- CLI tool repo: Root CLAUDE.md with language-specific standards
- Documentation repo: Minimal CLAUDE.md with documentation-only protocols

### Recommendation 5: Implement Incremental Section Updates

**Priority**: Low
**Effort**: Low (4-6 hours)
**Impact**: Faster updates, clearer git diffs, preserves customizations

**Implementation Steps**:

1. **Add Section Markers**:
   - Update CLAUDE.md template to include HTML comments
   - Markers: `<!-- SECTION: name -->` and `<!-- END_SECTION: name -->`

2. **Create Section Updater** (`.claude/lib/update-section.sh`):
   ```bash
   update_section() {
     local section_name="$1"
     # Detect project characteristics for section
     # Generate new section content
     # Replace content between markers
   }
   ```

3. **Add /setup Flags**:
   ```bash
   /setup --update-section testing_protocols
   /setup --update-sections code_standards,testing_protocols
   /setup --regenerate  # Full update (existing behavior)
   ```

4. **Use Cases**:
   - Project adds CI/CD → `/setup --update-section testing_protocols` regenerates with higher confidence
   - New testing framework → `/setup --update-section testing_protocols`
   - Language standards change → `/setup --update-section code_standards`
   - Manual customization in other sections preserved

### Recommendation 6: Create /setup Usage Guide

**Priority**: Low
**Effort**: Low (2-3 hours)
**Impact**: Improves discoverability and adoption

**Create**: `.claude/docs/setup-command-guide.md`

**Content**:
- Overview of /setup modes (standard, cleanup, validation, analysis, report-application, optimize, generate-readmes)
- Usage examples for different repository types
- Testing detection heuristics explanation
- Context optimization strategies
- Hierarchical config patterns
- Incremental update workflows
- Troubleshooting common issues

**Link from CLAUDE.md**:
```markdown
## Project-Specific Commands

### /setup - Configure or update CLAUDE.md
- Standard mode: `/setup`
- Cleanup mode: `/setup --cleanup`
- Optimize: `/setup --optimize`
- Generate READMEs: `/setup --generate-readmes`

See [Setup Command Guide](docs/setup-command-guide.md) for detailed usage.
```

## Implementation Roadmap

### Phase 1: Core Detection and Generation (High Priority)

**Duration**: 2-3 weeks

**Deliverables**:
1. ✅ Testing detection utility (`.claude/lib/detect-testing.sh`)
2. ✅ Testing protocol generator (`.claude/lib/generate-testing-protocols.sh`)
3. ✅ README scaffolding generator (`.claude/lib/generate-readme.sh`)
4. ✅ Context optimization analyzer (`.claude/lib/optimize-claude-md.sh`)
5. ✅ Integrate with /setup command

**Success Criteria**:
- `/setup` adaptively generates testing protocols based on evidence
- `/setup --generate-readmes` creates systematic README coverage
- `/setup --optimize` reduces CLAUDE.md by 40-60%
- Zero manual configuration for common patterns

### Phase 2: Hierarchical Configs (Medium Priority)

**Duration**: 1-2 weeks

**Deliverables**:
1. ✅ Config discovery utility (`.claude/lib/discover-standards.sh`)
2. ✅ Subdirectory config generator
3. ✅ Update /setup for hierarchical support
4. ✅ Documentation and examples

**Success Criteria**:
- `/setup --subdirectory [name]` generates focused configs
- Standards discovery algorithm works across monorepos
- Root CLAUDE.md reduced to 200-300 lines for multi-component projects

### Phase 3: Incremental Updates and Documentation (Low Priority)

**Duration**: 1 week

**Deliverables**:
1. ✅ Section marker system
2. ✅ Section updater utility (`.claude/lib/update-section.sh`)
3. ✅ /setup usage guide
4. ✅ Integration tests

**Success Criteria**:
- `/setup --update-section [name]` updates specific sections
- Manual customizations preserved across updates
- Comprehensive usage documentation available

## Testing Strategy

### Unit Tests (`.claude/tests/`)

1. **test_detect_testing.sh**:
   - Test score calculation for various repo types
   - Verify framework detection (pytest, jest, plenary, cargo test)
   - Edge cases: no tests, partial tests, comprehensive tests

2. **test_generate_readme.sh**:
   - Test template generation
   - Verify navigation link generation
   - Test file/subdirectory listing
   - Ensure no overwrite of existing READMEs

3. **test_optimize_claude_md.sh**:
   - Test section analysis and classification
   - Verify extraction logic
   - Test summary generation
   - Validate cross-reference updates

### Integration Tests

1. **test_setup_adaptive_testing.sh**:
   - Create test repositories (Python+pytest, JS+jest, Lua, no-tests)
   - Run `/setup` on each
   - Verify appropriate testing protocols generated

2. **test_setup_readme_generation.sh**:
   - Create directory structure without READMEs
   - Run `/setup --generate-readmes`
   - Verify README creation, navigation links, coverage metrics

3. **test_setup_optimization.sh**:
   - Create bloated CLAUDE.md
   - Run `/setup --optimize --dry-run`
   - Verify optimization report accuracy
   - Run `/setup --optimize`
   - Verify extraction and summarization

### Test Coverage Target

- **Unit Tests**: >80% coverage of new utilities
- **Integration Tests**: All /setup modes tested end-to-end
- **Edge Cases**: Documented and tested

## References

### Files Analyzed

**Command Files**:
- `/home/benjamin/.config/.claude/commands/setup.md` - Current /setup implementation
- `/home/benjamin/.config/.claude/commands/test.md` - Test command integration

**Configuration**:
- `/home/benjamin/.config/CLAUDE.md` - Current configuration (648 lines)

**Documentation**:
- `/home/benjamin/.config/nvim/docs/DOCUMENTATION_STANDARDS.md` - Doc standards
- `/home/benjamin/.config/nvim/docs/CODE_STANDARDS.md` - Code standards

**Utilities**:
- `/home/benjamin/.config/.claude/lib/error-handling.sh` - Error utilities
- `/home/benjamin/.config/.claude/lib/artifact-operations.sh` - Artifact utilities
- `/home/benjamin/.config/.claude/lib/detect-project-dir.sh` - Project detection

**Test Infrastructure**:
- `/home/benjamin/.config/.claude/tests/run_all_tests.sh` - Test runner
- `/home/benjamin/.config/.claude/tests/test_*.sh` - Existing test scripts

### External Research

**Web Search Queries**:
- "CLAUDE.md best practices 2025"
- "AI coding assistant configuration files lean documentation"
- "context window optimization AI assistants"

**Key Sources**:
- Draft.dev: AI assistant configuration patterns
- GitHub Blog: Context optimization for AI coding assistants
- Write the Docs: Documentation best practices for AI tools

**Industry Standards**:
- Context caching: 75% cost reduction
- RAG integration: 70% prompt size reduction
- Lean configs: <500 lines optimal
- Token budgeting: Classification (50-200), Generation (500-1500), Reasoning (4000-8000)

### Related Documentation

- [Command Architecture Standards](.claude/docs/command_architecture_standards.md)
- [Phase Dependencies Documentation](.claude/docs/phase_dependencies.md)
- [Adaptive Planning Configuration](CLAUDE.md#adaptive-planning-configuration)
- [Directory Protocols](CLAUDE.md#directory-protocols)

---

**Report Status**: Complete
**Next Steps**: Review recommendations, prioritize implementation phases, create implementation plan using `/plan`
