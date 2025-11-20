# /setup Command: Comprehensive Analysis and Refactoring Guide

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Complete /setup command analysis for refactoring
- **Research Complexity**: 2
- **Report Type**: Educational analysis with refactoring recommendations

## Executive Summary

The `/setup` command is a multi-mode project configuration tool that creates and maintains CLAUDE.md files - the central standards and configuration index for projects. It operates in 6 distinct modes (standard, cleanup, validate, analyze, apply-report, enhance), leverages 3 specialized utility scripts, and follows the executable/documentation separation pattern with a 311-line executable paired with a 1,241-line comprehensive guide.

**What it does**: Creates project-specific CLAUDE.md files with auto-detected standards (testing frameworks, code style), optimizes bloated CLAUDE.md files by extracting detailed sections to auxiliary documentation, validates structure and links, analyzes discrepancies between documented standards and actual codebase patterns, and applies reconciliation reports.

<!-- NOTE: it is important to cleanly separate and integrate duties handled by /setup and /optimize-claude where the /setup command should be used to initialize CLAUDE.md with .claude/docs/ integration while also providing diagnostic tools. The /optimize-claude is used to repair and improve CLAUDE.md and the contents in .claude/docs/ as well as their coordination. These two commands should support collaboration so that /setup creates artifacts that can be fed into /optimize-claude -->

**How it's used**: Invoked via `/setup [directory]` for standard mode or with flags like `--cleanup`, `--validate`, `--analyze`, `--apply-report <path>`, or `--enhance-with-docs` for specialized operations. The command auto-detects project context (git root, testing infrastructure) and generates appropriate configuration with parseable section metadata.

<!-- NOTE: it is important that running `/setup` on its own defaults to the root project directory if this is not already the case. -->

**Refactoring opportunities**: (1) Integrate centralized error logging for queryable error tracking, (2) Consolidate 6 bash blocks to 3-4 for cleaner output, (3) Modernize agent invocation from deprecated SlashCommand pattern to Task tool pattern, (4) Add comprehensive verification checkpoints after file operations, (5) Extract embedded analysis/cleanup logic to dedicated library functions for reusability.

## Section 1: Command Architecture Deep Dive

### 1.1 File Structure and Organization

**Primary Files**:

| File | Path | Size | Purpose |
|------|------|------|---------|
| **Executable** | `.claude/commands/setup.md` | 311 lines | Command execution logic with 4 bash blocks |
| **Guide** | `.claude/docs/guides/commands/setup-command-guide.md` | 1,241 lines | Comprehensive documentation, architecture, examples |
| **Utility 1** | `.claude/lib/util/detect-testing.sh` | 139 lines | Score-based testing framework detection (0-6 points) |
| **Utility 2** | `.claude/lib/util/generate-testing-protocols.sh` | 127 lines | Adaptive testing protocol generation based on confidence |
| **Utility 3** | `.claude/lib/util/optimize-claude-md.sh` | 242 lines | Context optimization with bloat analysis |

**Architecture Pattern**: Follows [Executable/Documentation Separation Pattern](/.claude/docs/concepts/patterns/executable-documentation-separation.md) where the executable (.md file) contains lean execution logic with bash blocks, while the guide contains comprehensive architecture, usage examples, and troubleshooting.

**Reference**: Command metadata at lines 2-7 of setup.md specifies allowed tools, argument hints, dependencies, and command type.

### 1.2 Command Modes Overview

The `/setup` command operates in **6 distinct modes** with priority-based selection:

**Mode Priority Order** (when multiple flags provided):
1. `--apply-report` (highest priority)
2. `--enhance-with-docs`
3. `--cleanup`
4. `--validate`
5. `--analyze`
6. Standard mode (default, no flags)

#### Mode 1: Standard Mode (Default)

<!-- NOTE: if run in standard mode and there already is a CLAUDE.md file, it is important to instead switch to analysis mode -->

**Purpose**: Generate or update CLAUDE.md with auto-detected standards.

**Usage**: `/setup [project-directory]`

**Workflow**:
```
1. Detect project root (git rev-parse or pwd)
2. Run detect-testing.sh to score testing infrastructure (0-6 points)
3. Run generate-testing-protocols.sh based on score
4. Generate CLAUDE.md with sections:
   - Code Standards (indentation, line length, naming, error handling)
   - Testing Protocols (auto-generated based on detected frameworks)
   - Documentation Policy (README requirements, format standards)
   - Standards Discovery (upward search, subdirectory overrides, fallback)
5. Verify file created and non-empty
6. Report success with file path
```

**Implementation**: Lines 104-167 in setup.md (Block 2)

**Auto-Detection Features**:
- **Testing frameworks**: pytest, jest, vitest, mocha, plenary, busted, cargo-test, go-test, bash-tests
- **Confidence scoring**: CI/CD configs (+2), test directories (+1), >10 test files (+1), coverage tools (+1), test runners (+1)
- **Adaptive protocols**: High confidence (≥4) generates full protocols, medium (2-3) brief protocols, low (0-1) minimal placeholders

**Output Example**:
```
Setup complete: Mode=standard | Project=/home/user/project | Workflow=setup_1234567890
Generating CLAUDE.md
✓ Created: /home/user/project/CLAUDE.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Setup Complete
  CLAUDE.md created at: /home/user/project/CLAUDE.md
  Workflow: setup_1234567890
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Reference**: setup.md lines 104-167, setup-command-guide.md lines 11-12, 872-884

#### Mode 2: Cleanup Mode

<!-- NOTE: this is better handled by /optimize-claude and so can be removed -->

**Purpose**: Optimize bloated CLAUDE.md by extracting detailed sections to auxiliary files.

**Usage**:
- Standard: `/setup --cleanup [project-directory]`
- Preview: `/setup --cleanup --dry-run [project-directory]`

**Workflow**:
```
1. Validate CLAUDE.md exists
2. Parse threshold profile (aggressive/balanced/conservative)
3. Execute optimize-claude-md.sh with flags
4. Analyze sections for bloat (>30 lines default)
5. In dry-run: Show extraction preview without changes
6. In standard: Extract sections, create docs/ files, update links
7. Verify cleanup success with exit code check
8. Report completion
```

**Threshold Profiles**:

| Profile | Trigger | Use Case | Effect |
|---------|---------|----------|--------|
| Aggressive | >50 lines | Very large CLAUDE.md (>400 lines) | Maximum extraction, smallest file |
| Balanced (default) | >80 lines | Moderate CLAUDE.md (300-400 lines) | Extract significantly detailed sections |
| Conservative | >120 lines | Already lean CLAUDE.md (<300 lines) | Minimal extraction, keep inline |

**Dry-Run Mode** (`--dry-run`):
- Shows extraction candidates with line counts
- Displays impact analysis (% reduction)
- No files created or modified
- Helpful for planning before committing changes

**Implementation**: Lines 169-198 in setup.md (Block 2)

**Output Example**:
```
Setup complete: Mode=cleanup | Project=/home/user/project | Workflow=setup_1234567890
Cleanup Mode
=== CLAUDE.md Context Optimization ===

# CLAUDE.md Optimization Analysis

**File**: /home/user/project/CLAUDE.md
**Total Lines**: 310
**Threshold Profile**: Bloated >80 lines, Moderate 50-80 lines

## Section Analysis

| Section | Lines | Status | Recommendation |
|---------|-------|--------|----------------|
| Code Standards | 45 | Optimal | Keep inline |
| Testing Protocols | 92 | **Bloated** | Extract to docs/ with summary |
| Documentation Policy | 38 | Optimal | Keep inline |
| Standards Discovery | 55 | Moderate | Consider extraction |

## Summary

- **Bloated sections**: 1
- **Projected savings**: ~78 lines
- **Target size**: 232 lines
- **Reduction**: 25.2%

✓ Cleanup complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Cleanup Complete
  CLAUDE.md optimized
  Workflow: setup_1234567890
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Reference**: setup.md lines 169-198, setup-command-guide.md lines 887-914, optimize-claude-md.sh lines 1-242

#### Mode 3: Validation Mode

<!-- NOTE: this can be combined into analysis mode -->

**Purpose**: Validate CLAUDE.md structure and completeness.

**Usage**: `/setup --validate [project-directory]`

**Workflow**:
```
1. Validate CLAUDE.md exists
2. Check for required sections (Code Standards, Testing Protocols, Documentation Policy, Standards Discovery)
3. Verify [Used by: ...] metadata on ## sections
4. Report missing sections and metadata
5. Report validation success or warnings
```

**Required Sections**:
- Code Standards
- Testing Protocols
- Documentation Policy
- Standards Discovery

**Metadata Format**: Each `## Section` should have `[Used by: command1, command2]` on following line

**Implementation**: Lines 200-230 in setup.md (Block 2)

**Output Example**:
```
Setup complete: Mode=validate | Project=/home/user/project | Workflow=setup_1234567890
Validation Mode
✓ All sections present
✓ Metadata OK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Validation Complete
  CLAUDE.md validated
  Workflow: setup_1234567890
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Reference**: setup.md lines 200-230, setup-command-guide.md lines 916-929

#### Mode 4: Analysis Mode

**Purpose**: Analyze discrepancies between CLAUDE.md documentation and actual codebase patterns.

**Usage**: `/setup --analyze [project-directory]`

<!-- NOTE: running `/setup --analyze` without a project directory should default to the root project directory if it does not do this already. Also, since /setup should default to analysis mode if CLAUDE.md exists, there is no need for an --analyze flag at all -->

**Workflow**:
```
1. Create .claude/specs/reports/ directory
2. Determine next report number (NNN format)
3. Generate basic analysis report with metadata
4. Create [FILL IN: ...] sections for manual gap filling
5. Report completion with report path
```

<!-- NOTE: it is important that the workflow follow the pattern used in the /research command for uniformity of approach while making use of the same standards and infrastructure -->

**Report Structure**:
```markdown
# Standards Analysis Report

## Metadata
- **Date**: YYYY-MM-DD
- **Project**: /path/to/project

## Summary
Basic analysis. For comprehensive analysis, use /orchestrate with research agents.

## Gap Analysis
[FILL IN: Indentation] ___
[FILL IN: Error Handling] ___
[FILL IN: Testing] ___
```

**Note**: This is a **basic template generator**. For comprehensive discrepancy detection, the guide recommends using `/orchestrate` with research agents to analyze three sources: (1) CLAUDE.md documented standards, (2) actual codebase patterns with confidence scoring, (3) config file settings (.editorconfig, package.json, etc.).

<!-- NOTE: since /orchestrate has been removed, this mode should conclude by giving the user the option of running /optimize-claude while passing in the analysis report that was created with the --file flag which /optimize-claude should be made to support if it does not already -->

**Implementation**: Lines 232-266 in setup.md (Block 2)

**Output Example**:
```
Setup complete: Mode=analyze | Project=/home/user/project | Workflow=setup_1234567890
Analysis Mode
✓ Report: /home/user/project/.claude/specs/reports/001_standards_analysis.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Analysis Complete
  Report created: /home/user/project/.claude/specs/reports/001_standards_analysis.md
  Workflow: setup_1234567890
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Reference**: setup.md lines 232-266, setup-command-guide.md lines 580-640, 931-949

#### Mode 5: Report Application Mode

**Purpose**: Apply filled analysis report to update CLAUDE.md with reconciled standards.

**Usage**: `/setup --apply-report <report-path> [project-directory]`

<!-- NOTE: this should use the standard --file flag used in other commands to pass a report into the analysis mode and so there does not need to be a separate report application mode in addition to analysis -->

**Workflow**:
```
1. Validate report file exists
2. Create backup of CLAUDE.md (.backup.TIMESTAMP)
3. Parse filled [FILL IN: ...] sections from report
4. Extract decisions and rationale
5. Display found gaps
6. Prompt user to manually review and update CLAUDE.md
```

**Current Implementation**: **Manual review workflow** - command shows found gaps but user must manually update CLAUDE.md. The guide (lines 661-717) documents a more advanced parsing and automatic application system, but the current executable (lines 268-279) only provides manual guidance.

**Implementation**: Lines 268-279 in setup.md (Block 2)

**Output Example**:
```
Setup complete: Mode=apply-report | Project=/home/user/project | Workflow=setup_1234567890
Applying report
Found gaps:
Indentation=4 spaces
Error Handling=Use pcall for operations
NOTE: Manual review required for this version
Review /home/user/project/.claude/specs/reports/001_standards_analysis.md and update /home/user/project/CLAUDE.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Report Application Complete
  Workflow: setup_1234567890
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Reference**: setup.md lines 268-279, setup-command-guide.md lines 662-717, 945-1002

#### Mode 6: Enhancement Mode

<!-- NOTE: this is better handled by /optimize-claude and so this mode can be removed -->

**Purpose**: Delegate to /orchestrate for comprehensive CLAUDE.md enhancement with documentation discovery.

**Usage**: `/setup --enhance-with-docs [project-directory]`

**Workflow**:
```
1. Construct orchestration message with phases:
   - Phase 1: Research (parallel) - Docs discovery, test analysis, TDD detection
   - Phase 2: Planning - Gap analysis
   - Phase 3: Implementation - Update CLAUDE.md
   - Phase 4: Documentation - Workflow summary
2. Display orchestration message
3. Inform user to wait for /orchestrate completion
4. Exit (actual orchestration happens in parent context)
```

**Agent Pattern**: Uses **deprecated SlashCommand pattern** to invoke /orchestrate. Modern pattern (see /plan command) uses Task tool with behavioral injection.

**Implementation**: Lines 289-313 in setup.md (Block 3)

**Output Example**:
```
Setup complete: Mode=enhance | Project=/home/user/project | Workflow=setup_1234567890
Enhancement Mode (delegating to /orchestrate)
Project: /home/user/project
Invoking /orchestrate...
Analyze documentation at /home/user/project, enhance CLAUDE.md.

Phase 1: Research (parallel) - Docs discovery, test analysis, TDD detection
Phase 2: Planning - Gap analysis
Phase 3: Implementation - Update CLAUDE.md
Phase 4: Documentation - Workflow summary

Project: /home/user/project
Wait for /orchestrate to complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Enhancement Delegated
  Check /orchestrate output for results
  Workflow: setup_1234567890
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Reference**: setup.md lines 289-313, setup-command-guide.md line 16

### 1.3 Utility Scripts Deep Dive

#### Utility 1: detect-testing.sh

**Purpose**: Score-based testing framework detection (0-6 points)

**Location**: `.claude/lib/util/detect-testing.sh` (139 lines)

**Scoring Algorithm**:
```
Score Calculation:
- CI/CD configs present (+2 points)
  - .github/workflows/*.yml
  - .gitlab-ci.yml
  - .circleci/config.yml
  - .travis.yml
  - azure-pipelines.yml

- Test directories present (+1 point)
  - tests/, test/, __tests__, spec/

- Test file count >10 (+1 point)
  - Files matching *test* or *spec*

- Coverage tools present (+1 point)
  - .coveragerc, pytest.ini, jest.config.js
  - jest.config.ts, .nyc_output/, coverage.xml, .coverage

- Test runners present (+1 point)
  - run_tests.sh, run_tests.py, run_all_tests.sh
  - Makefile with test: target

Maximum Score: 6 points
```

**Framework Detection**:

| Framework | Detection Method | Output Token |
|-----------|-----------------|--------------|
| pytest | pytest.ini, .pytest_cache/, requirements.txt, setup.py, pyproject.toml | pytest |
| unittest | test_*.py with unittest import | unittest |
| jest | jest.config.js, jest.config.ts, package.json | jest |
| vitest | vitest.config.js, vitest.config.ts, package.json | vitest |
| mocha | package.json with mocha | mocha |
| plenary | *_spec.lua in tests/ or spec/ directories | plenary |
| busted | .busted, .rockspec with busted | busted |
| cargo-test | Cargo.toml present | cargo-test |
| go-test | go.mod + *_test.go files | go-test |
| bash-tests | test_*.sh in .claude/tests/ or tests/ | bash-tests |

**Output Format**:
```bash
SCORE:4
FRAMEWORKS:pytest jest bash-tests
```

**Usage in /setup**:
```bash
# Line 108-110 in setup.md
DETECT_OUTPUT=$("${LIB_DIR}/detect-testing.sh" "$PROJECT_DIR" 2>&1)
TEST_SCORE=$(echo "$DETECT_OUTPUT" | grep "^SCORE:" | cut -d: -f2)
TEST_FRAMEWORKS=$(echo "$DETECT_OUTPUT" | grep "^FRAMEWORKS:" | cut -d: -f2-)
```

**Reference**: detect-testing.sh lines 1-139, setup-command-guide.md lines 22-45

#### Utility 2: generate-testing-protocols.sh

**Purpose**: Generate adaptive testing protocols based on confidence score and detected frameworks

**Location**: `.claude/lib/util/generate-testing-protocols.sh` (127 lines)

**Confidence Levels**:

| Confidence | Score Range | Protocol Type | Content |
|------------|-------------|---------------|---------|
| High | ≥4 points | Full protocols | Framework-specific commands, test patterns, configuration, TDD guidance |
| Medium | 2-3 points | Brief protocols | Basic test discovery, expansion suggestions |
| Low | 0-1 points | Minimal | Generic guidance, recommend /setup --analyze |

**Generated Content Structure**:
```markdown
### Test Discovery
[Discovery methodology: CLAUDE.md priority, subdirectory override, fallback]

### Detected Testing Frameworks
- **Frameworks**: [list]
- **Test Score**: N/6

#### [Framework Name]
- **Test Pattern**: [glob patterns]
- **Test Commands**: [commands to run]
- **Configuration**: [config files]

[Repeat for each detected framework]

### Coverage Requirements
[Standard coverage expectations]

### Test Organization
[Best practices for test structure]
```

**Framework-Specific Templates**:

Example for pytest (lines 30-37):
```markdown
#### Python - pytest
- **Test Pattern**: `test_*.py` or `*_test.py`
- **Test Commands**: `pytest`, `pytest -v`, `pytest --cov`
- **Configuration**: `pytest.ini`, `pyproject.toml`
```

**Usage in /setup**:
```bash
# Line 113 in setup.md
TESTING_SECTION=$("${LIB_DIR}/generate-testing-protocols.sh" "$TEST_SCORE" "$TEST_FRAMEWORKS" 2>&1)
# Line 132: Append to CLAUDE.md
echo "$TESTING_SECTION" >> "$CLAUDE_MD_PATH"
```

**Reference**: generate-testing-protocols.sh lines 1-127, setup-command-guide.md lines 47-65

#### Utility 3: optimize-claude-md.sh

**Purpose**: Analyze CLAUDE.md for bloat and recommend/perform extractions

**Location**: `.claude/lib/util/optimize-claude-md.sh` (242 lines)

**Bloat Detection Algorithm**:
```awk
For each ## section:
  1. Count lines in section
  2. Compare to threshold profile:
     - Bloated: lines > THRESHOLD_BLOATED
     - Moderate: THRESHOLD_MODERATE < lines ≤ THRESHOLD_BLOATED
     - Optimal: lines ≤ THRESHOLD_MODERATE
  3. Calculate projected savings (85% of section lines)
  4. Accumulate statistics
```

**Threshold Profiles** (lines 13-34):

```bash
aggressive:
  THRESHOLD_BLOATED=50
  THRESHOLD_MODERATE=30

balanced (default):
  THRESHOLD_BLOATED=80
  THRESHOLD_MODERATE=50

conservative:
  THRESHOLD_BLOATED=120
  THRESHOLD_MODERATE=80
```

**Analysis Output** (lines 45-129):
```
# CLAUDE.md Optimization Analysis

**File**: CLAUDE.md
**Total Lines**: 310
**Threshold Profile**: Bloated >80 lines, Moderate 50-80 lines

## Section Analysis

| Section | Lines | Status | Recommendation |
|---------|-------|--------|----------------|
[Table of sections with analysis]

## Summary

- **Bloated sections**: N
- **Projected savings**: ~N lines
- **Target size**: N lines
- **Reduction**: N.N%
```

**Backup System** (lines 132-145):
- Creates `.claude/backups/` directory
- Saves timestamped backup: `CLAUDE.md.YYYYMMDD-HHMMSS`
- Returns backup path for rollback

**Rollback Function** (lines 147-159):
```bash
rollback_optimization <backup_file> <target_file>
# Restores CLAUDE.md from backup
```

**Current Limitation**: Lines 190-192 contain TODO comment - automatic extraction not yet implemented. Command generates analysis report but extractions must be performed manually.

**Usage in /setup**:
```bash
# Line 189 in setup.md
"${LIB_DIR}/optimize-claude-md.sh" "$CLAUDE_MD_PATH" $FLAGS
CLEANUP_EXIT_CODE=$?
```

**Reference**: optimize-claude-md.sh lines 1-242, setup-command-guide.md lines 67-108

### 1.4 Bash Block Structure

The /setup command uses **4 bash blocks** organized as follows:

**Block 1: Setup and Initialization** (Lines 19-85)
```bash
Purpose: Argument parsing, validation, project detection, error logging setup
Steps:
1. Set bash options (set +H to disable history expansion)
2. Detect project directory (git root or pwd)
3. Source error-handling library
4. Initialize error log and workflow metadata
5. Parse command-line arguments (mode selection, flags)
6. Validate arguments (required paths, mode compatibility)
7. Export environment variables
8. Display setup summary
```

**Block 2: Mode Execution** (Lines 89-281)
```bash
Purpose: Execute mode-specific operations with guards
Structure: case "$MODE" in ... esac with 6 mode implementations
Each mode:
1. Validates prerequisites
2. Executes mode logic
3. Verifies results
4. Logs errors on failure
5. Reports success
```

**Block 3: Enhancement Mode (Optional)** (Lines 285-313)
```bash
Purpose: Delegate to /orchestrate when MODE=enhance
Conditional: Only runs if MODE=enhance, otherwise exits immediately
Steps:
1. Check MODE variable
2. Display delegation message
3. Construct orchestration prompt
4. Invoke /orchestrate (via SlashCommand pattern)
5. Wait message
```

**Block 4: Completion** (Lines 317-367)
```bash
Purpose: Display mode-specific completion messages
Structure: case "$MODE" in ... esac with formatted output per mode
Format: Box drawing with success indicator, details, workflow ID
```

**Consolidation Opportunity**: Blocks 3 and 4 could merge into Block 2 (enhancement mode in case statement), reducing to 3 blocks total. This aligns with modern command pattern of Setup/Execute/Cleanup.

**Reference**: setup.md full file, setup-command-guide.md lines 18

## Section 2: Detailed Usage Patterns

### 2.1 Common Workflows

#### Workflow 1: New Project Setup

**Scenario**: Setting up CLAUDE.md for a new project with existing code

**Steps**:
```bash
# Navigate to project root
cd /path/to/project

# Run setup command
/setup

# Command automatically:
# 1. Detects git root: /path/to/project
# 2. Scans for test infrastructure
# 3. Detects: pytest (score: 4/6)
# 4. Generates testing protocols with pytest commands
# 5. Creates CLAUDE.md with appropriate sections
# 6. Verifies file creation

# Output:
# ✓ Created: /path/to/project/CLAUDE.md
```

**Result**: CLAUDE.md file containing:
- Code Standards section with defaults
- Testing Protocols section with pytest-specific commands
- Documentation Policy section
- Standards Discovery section

**Reference**: setup-command-guide.md lines 111-122

#### Workflow 2: Optimize Existing CLAUDE.md

**Scenario**: CLAUDE.md has grown to 310 lines, hard to navigate

**Steps**:
```bash
# Preview optimization first
/setup --cleanup --dry-run

# Review output showing:
# - Testing Protocols: 92 lines (Bloated)
# - Projected savings: 78 lines (25.2% reduction)

# Apply optimization
/setup --cleanup

# Automatic backup created:
# .claude/backups/CLAUDE.md.20251120-143022

# Result: CLAUDE.md now 232 lines with link to docs/TESTING.md
```

**Before**:
```markdown
## Testing Protocols
[Used by: /test, /test-all, /implement]

[92 lines of detailed pytest configuration, commands, examples, CI/CD setup]
```

**After**:
```markdown
## Testing Protocols
[Used by: /test, /test-all, /implement]

See [Testing Protocols](docs/TESTING.md) for complete test configuration, framework setup, and CI/CD integration.

Quick reference: Run tests with `pytest -v`
```

**docs/TESTING.md** (newly created):
```markdown
# Testing Protocols

[Full 92 lines of testing documentation]
```

**Reference**: setup-command-guide.md lines 124-137

#### Workflow 3: Standards Reconciliation

**Scenario**: Inherited codebase, unclear if CLAUDE.md matches reality

**Steps**:
```bash
# Generate analysis report
/setup --analyze

# Output: Created .claude/specs/reports/001_standards_analysis.md

# Open report, review gaps:
# [FILL IN: Indentation]
# Context: CLAUDE.md says "2 spaces", codebase uses 4 spaces (85% confidence)
# Recommendation: Update to "4 spaces" to match codebase
# Decision: _______________
# Rationale: _______________

# Fill in decisions:
# Decision: 4 spaces
# Rationale: Match existing codebase convention for consistency

# Apply filled report
/setup --apply-report .claude/specs/reports/001_standards_analysis.md

# Output shows gaps found and prompts manual review
# Manually update CLAUDE.md based on decisions

# Verify changes
/setup --validate
# Output: ✓ All sections present, ✓ Metadata OK
```

**Reference**: setup-command-guide.md lines 720-764

#### Workflow 4: Comprehensive Enhancement

**Scenario**: Want AI agents to discover documentation and enhance CLAUDE.md

**Steps**:
```bash
# Invoke enhancement mode
/setup --enhance-with-docs

# Command delegates to /orchestrate with research phases
# Wait for orchestration to complete

# Orchestrate phases:
# Phase 1: research-specialist discovers docs/ files, analyzes tests, detects TDD
# Phase 2: plan-architect creates gap analysis
# Phase 3: code-writer updates CLAUDE.md
# Phase 4: documentation-writer creates workflow summary

# Review orchestration output for results
```

**Note**: This mode uses the deprecated SlashCommand pattern. Modern equivalent would use Task tool with behavioral injection pattern (like /plan command does).

**Reference**: setup.md lines 289-313, setup-command-guide.md lines 297-312

### 2.2 Edge Cases and Error Handling

#### Edge Case 1: CLAUDE.md Already Exists in Standard Mode

**Behavior**: Command **overwrites** existing CLAUDE.md without backup

**Issue**: No verification prompt, no backup creation

**Workaround**: Use `--cleanup` mode which creates automatic backups

**Risk**: Loss of manual customizations

**Recommendation**: Add pre-existence check and backup creation in standard mode

**Reference**: setup.md lines 115-165 (no backup logic), contrast with lines 270-271 (apply-report creates backup)

#### Edge Case 2: Invalid Threshold Profile in Cleanup Mode

**Input**: `/setup --cleanup --threshold invalid`

**Behavior**:
```bash
# Line 182-186 in setup.md maps invalid to default
case "$THRESHOLD" in
  aggressive) FLAGS="$FLAGS --aggressive" ;;
  conservative) FLAGS="$FLAGS --conservative" ;;
  *) FLAGS="$FLAGS --balanced" ;;  # Silently defaults to balanced
esac
```

**Issue**: No error message for invalid threshold

**Result**: Command proceeds with balanced threshold silently

**Recommendation**: Add validation and error logging for invalid threshold values

**Reference**: setup.md lines 182-186

#### Edge Case 3: Report Path Not Provided for Apply-Report Mode

**Input**: `/setup --apply-report` (missing path argument)

**Behavior**:
```bash
# Lines 66-70 in setup.md
if [ "$MODE" = "apply-report" ] && [ -z "$REPORT_PATH" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "validation_error" \
    "Missing report path for --apply-report" "validation" "{\"mode\": \"$MODE\"}"
  echo "ERROR: --apply-report requires path. Usage: /setup --apply-report <path> [dir]"
  exit 1
fi
```

**Result**: Error logged to centralized error log, clear error message, exit code 1

**Status**: ✅ Properly handled with error logging

**Reference**: setup.md lines 66-70

#### Edge Case 4: Project Directory Does Not Exist

**Input**: `/setup /nonexistent/directory`

**Behavior**:
```bash
# Lines 63-64 in setup.md
[[ ! "$PROJECT_DIR" = /* ]] && PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)"
```

**Issue**: If `cd` fails, `PROJECT_DIR` becomes empty string, but no validation follows

**Result**: Command continues with `PROJECT_DIR=""`, likely failing later with unclear error

**Missing**:
```bash
if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
  log_command_error ... "Directory does not exist: $1"
  exit 1
fi
```

**Recommendation**: Add explicit directory existence check after path resolution

**Reference**: setup.md lines 63-64

#### Edge Case 5: Dry-Run Used Without Cleanup Mode

**Input**: `/setup --dry-run`

**Behavior**:
```bash
# Lines 76-80 in setup.md
if [ "$DRY_RUN" = true ] && [ "$MODE" != "cleanup" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "validation_error" \
    "--dry-run requires --cleanup mode" "validation" "{\"mode\": \"$MODE\", \"dry_run\": true}"
  echo "ERROR: --dry-run requires --cleanup"
  exit 1
fi
```

**Result**: Error logged, clear error message, exit code 1

**Status**: ✅ Properly handled with error logging

**Reference**: setup.md lines 76-80

#### Edge Case 6: Testing Detection Returns Score 0

**Scenario**: Project has tests but in non-standard locations

**Behavior**:
```bash
# detect-testing.sh returns:
SCORE:0
FRAMEWORKS:none

# generate-testing-protocols.sh generates:
### Testing Setup
No testing frameworks detected. Consider setting up:
[Generic guidance]
```

**Result**: CLAUDE.md created with minimal testing section

**Workaround**:
1. Move tests to standard directory (tests/, test/, spec/)
2. Add test runner script (run_tests.sh)
3. Add CI/CD config file
4. Re-run /setup to regenerate with improved detection

**Reference**: detect-testing.sh lines 9-133, generate-testing-protocols.sh lines 96-111

### 2.3 Integration with Other Commands

#### Integration 1: /setup and /validate

**Relationship**: /validate can be invoked via `/setup --validate` or independently

**Setup as Wrapper**:
```bash
/setup --validate [directory]
# Internally executes validation logic (lines 200-230)
```

**Standalone /validate**:
```bash
# Documented equivalence in guide (line 929)
/setup --validate [directory]  # Equivalent to:
/validate-setup [directory]
```

**Shared Logic**: Both should validate:
- CLAUDE.md exists
- Required sections present
- Metadata format correct
- Linked files accessible

**Current Implementation**: /setup contains validation logic directly in mode case statement. No shared library function.

**Recommendation**: Extract validation logic to `.claude/lib/validation/validate-claude-md.sh` for reuse

**Reference**: setup.md lines 200-230, setup-command-guide.md line 929

#### Integration 2: /setup and /orchestrate

**Relationship**: /setup enhancement mode delegates to /orchestrate

**Delegation Pattern** (setup.md lines 299-312):
```bash
ORCH_MSG="Analyze documentation at ${PROJECT_DIR}, enhance CLAUDE.md.
[Multi-phase orchestration prompt]"

echo "Invoking /orchestrate..."
echo "$ORCH_MSG"
echo "Wait for /orchestrate to complete"
```

**Issue**: Uses **deprecated SlashCommand invocation pattern**

**Modern Pattern** (from /plan command):
```bash
# Create task for orchestrator via Task tool
{
  "task_type": "general-purpose",
  "behavioral_file": ".claude/agents/orchestrator.md",
  "prompt": "[orchestration prompt]",
  "expected_output": "WORKFLOW_COMPLETE: [summary]"
}
```

**Recommendation**: Refactor enhancement mode to use Task tool with behavioral injection instead of SlashCommand

**Reference**: setup.md lines 289-313, /plan command for modern pattern

#### Integration 3: /setup and Error Logging System

**Current Status**: **Partially Integrated** (as of recent updates)

**Integrated Components** (lines 29-39):
```bash
# Source error-handling library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}

# Initialize error log
ensure_error_log_exists
COMMAND_NAME="/setup"
WORKFLOW_ID="setup_$(date +%s)"
USER_ARGS="$*"
```

**Error Logging Points** (examples):
- Line 54-56: Unknown flag validation error
- Line 67-69: Missing report path for apply-report
- Line 72-74: Report file not found
- Line 77-79: Dry-run without cleanup
- Line 153-157: CLAUDE.md creation failure
- Line 159-164: CLAUDE.md empty after creation
- Line 173-177: CLAUDE.md not found for cleanup
- Line 191-196: Cleanup script failure
- Line 204-208: CLAUDE.md not found for validation
- Line 258-263: Report creation failure

**Integration Benefits**:
- Queryable error history via `/errors --command /setup`
- Structured error context for debugging
- Workflow correlation via WORKFLOW_ID
- Time-series error analysis via `/errors --since "2 hours ago"`

**Reference**: setup.md lines 29-39 and error logging calls throughout, error-handling.md (630 lines)

## Section 3: Standards Compliance Analysis

### 3.1 Current Compliance Status

**Scorecard**:

| Standard | Status | Compliance % | Priority | Lines Affected |
|----------|--------|--------------|----------|----------------|
| **Error Logging Integration** | ✅ Implemented | 95% | Critical | 29-39, 54-263 |
| **Bash Block Consolidation** | ⚠️ Partial | 60% | High | 19-367 (4 blocks vs 3 target) |
| **Output Suppression** | ✅ Good | 85% | Medium | 108-113, 189 |
| **Executable/Documentation Separation** | ✅ Excellent | 95% | High | 311 lines exec, 1241 lines guide |
| **Verification Checkpoints** | ⚠️ Partial | 70% | Medium | 152-164, 189-196, 258-263 |
| **Imperative Language** | ⚠️ Mixed | 75% | Low | Various echo statements |
| **Section Metadata** | ✅ Good | 90% | Medium | Generated CLAUDE.md |

**Overall Compliance**: 80% (Good, room for improvement)

### 3.2 Compliance Gaps and Recommendations

#### Gap 1: Bash Block Count (Target: 3, Current: 4)

**Issue**: 4 bash blocks exceed the 2-3 block target for output consolidation

**Current Structure**:
1. Block 1: Setup and Initialization (lines 19-85)
2. Block 2: Mode Execution (lines 89-281)
3. Block 3: Enhancement Mode Optional (lines 285-313)
4. Block 4: Completion (lines 317-367)

**Refactor Approach**:

**Option A - Merge Enhancement into Mode Execution**:
```bash
# Block 2 case statement (lines 103-281)
case "$MODE" in
  standard) ... ;;
  cleanup) ... ;;
  validate) ... ;;
  analyze) ... ;;
  apply-report) ... ;;
  enhance)  # Move Block 3 logic here
    echo "Enhancement Mode (delegating to /orchestrate)"
    # [Enhancement logic from lines 297-312]
    ;;
esac
```

Result: 3 blocks (Setup/Execute/Cleanup)

**Option B - Merge Completion into Mode Execution**:
```bash
case "$MODE" in
  standard)
    # Mode logic
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✓ Setup Complete"
    echo "  CLAUDE.md created at: $PROJECT_DIR/CLAUDE.md"
    echo "  Workflow: $WORKFLOW_ID"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ;;
  # [Repeat for each mode]
esac
```

Result: 3 blocks (Setup/Execute-with-Completion)

**Recommendation**: Use Option A (merge enhancement) as it's cleaner and maintains separation of concerns. Completion messages can stay in Block 4 as they're truly separate cleanup phase.

**Impact**: Reduces output to 3 bash blocks, aligning with Pattern 8 target

**Reference**: setup.md blocks 1-4, output-formatting.md lines 927-995

#### Gap 2: Partial Verification Checkpoints

**Issue**: Some file operations lack comprehensive verification

**Examples**:

**Good Example** (lines 152-164):
```bash
if [ ! -f "$CLAUDE_MD_PATH" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "file_error" \
    "CLAUDE.md file not created at expected path" "standard_mode_generation" \
    "{\"expected_path\": \"$CLAUDE_MD_PATH\"}"
  echo "ERROR: CLAUDE.md not created" && exit 1
fi

if [ ! -s "$CLAUDE_MD_PATH" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "file_error" \
    "CLAUDE.md file is empty" "standard_mode_validation" \
    "{\"file_path\": \"$CLAUDE_MD_PATH\"}"
  echo "ERROR: CLAUDE.md is empty" && exit 1
fi
```

Status: ✅ File existence + non-empty check

**Missing Example** (lines 270-278):
```bash
apply-report)
  echo "Applying report"
  BACKUP="${CLAUDE_MD_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
  cp "$CLAUDE_MD_PATH" "$BACKUP" 2>/dev/null || true

  FILLED=$(grep -E "\[FILL IN:" "$REPORT_PATH" | sed 's/\[FILL IN: \(.*\)\] \(.*\)/\1=\2/')
  [ -z "$FILLED" ] && echo "WARNING: No filled gaps. Edit report first." && exit 0

  echo "Found gaps:"; echo "$FILLED"
  echo "NOTE: Manual review required for this version"
  ;;
```

Status: ⚠️ No verification that:
- CLAUDE_MD_PATH exists before backup
- Backup was created successfully
- Report parsing succeeded
- FILLED variable contains valid data format

**Recommendation**: Add verification checks:
```bash
apply-report)
  # Verify CLAUDE.md exists
  if [ ! -f "$CLAUDE_MD_PATH" ]; then
    log_command_error ... "file_error" "CLAUDE.md not found for report application"
    exit 1
  fi

  # Create backup with verification
  BACKUP="${CLAUDE_MD_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
  if ! cp "$CLAUDE_MD_PATH" "$BACKUP" 2>/dev/null; then
    log_command_error ... "file_error" "Failed to create backup"
    exit 1
  fi
  echo "✓ Backup created: $BACKUP"

  # Verify report file is readable
  if [ ! -r "$REPORT_PATH" ]; then
    log_command_error ... "file_error" "Cannot read report file"
    exit 1
  fi

  # Parse with error handling
  FILLED=$(grep -E "\[FILL IN:" "$REPORT_PATH" 2>/dev/null | sed 's/\[FILL IN: \(.*\)\] \(.*\)/\1=\2/')
  if [ -z "$FILLED" ]; then
    echo "WARNING: No filled gaps. Edit report first."
    exit 0
  fi

  # Validate FILLED format (contains = separator)
  if ! echo "$FILLED" | grep -q "="; then
    log_command_error ... "parse_error" "Invalid gap fill format"
    exit 1
  fi

  echo "Found gaps:"; echo "$FILLED"
  echo "NOTE: Manual review required for this version"
  ;;
```

**Impact**: Prevents silent failures, improves debuggability, aligns with Pattern 10 (Verification Checkpoints)

**Reference**: setup.md lines 268-279, verification examples at lines 152-164 and 189-196

#### Gap 3: Deprecated Agent Invocation Pattern

**Issue**: Enhancement mode (lines 299-312) uses SlashCommand pattern instead of modern Task tool pattern

**Current Implementation**:
```bash
echo "Invoking /orchestrate..."
echo "$ORCH_MSG"
echo "Wait for /orchestrate to complete"
```

**Problem**:
- Relies on user context to see "/orchestrate" and invoke it
- No structured handoff to orchestrator agent
- No validation of orchestration results
- No error handling if orchestration fails

**Modern Pattern** (from /plan command):
```bash
# Use Task tool to invoke agent with behavioral injection
# Agent prompt constructed with:
# - Behavioral file path: .claude/agents/orchestrator.md
# - Task-specific parameters
# - Expected output format signal
# - Timeout and error handling

# Example structure:
ORCHESTRATOR_PROMPT="Read and follow ALL behavioral guidelines from:
${CLAUDE_PROJECT_DIR}/.claude/agents/orchestrator.md

You are orchestrating: CLAUDE.md enhancement workflow

**Workflow-Specific Context**:
- Project Directory: ${PROJECT_DIR}
- Enhancement Goal: Discover docs and enhance CLAUDE.md
- Phases: Research → Planning → Implementation → Documentation

Execute workflow according to behavioral guidelines and return completion signal:
WORKFLOW_COMPLETE: [summary]"

# Invoke via Task tool (not SlashCommand)
# Task tool handles timeout, error parsing, result verification
```

**Recommendation**: Refactor enhancement mode to use Task tool with behavioral injection pattern

**Benefits**:
- Structured agent invocation with timeout
- Error handling and logging
- Result verification
- Consistent with modern command patterns

**Reference**: setup.md lines 289-313, behavioral-injection.md pattern documentation, /plan command for reference implementation

#### Gap 4: Inconsistent Imperative Language

**Issue**: Some output messages use past tense or passive voice instead of present tense imperative

**Examples**:

**Non-Imperative** (line 83):
```bash
echo "Setup complete: Mode=$MODE | Project=$PROJECT_DIR | Workflow=$WORKFLOW_ID"
```

Should be:
```bash
echo "Running setup: Mode=$MODE | Project=$PROJECT_DIR | Workflow=$WORKFLOW_ID"
```

**Non-Imperative** (line 166):
```bash
echo "✓ Created: $CLAUDE_MD_PATH"
```

Better as:
```bash
echo "✓ Create CLAUDE.md at $CLAUDE_MD_PATH"
```

**Good Example** (line 105):
```bash
echo "Generating CLAUDE.md"
```

**Recommendation**: Update all output messages to use present tense imperative form:
- "Running setup" not "Setup complete"
- "Generating CLAUDE.md" not "Generated CLAUDE.md"
- "Validating structure" not "Validation complete"

**Impact**: Improves consistency with Standard 3 (Imperative Language)

**Reference**: setup.md various echo statements, code-standards.md Standard 3

### 3.3 Best Practices Adherence

**Excellent Practices**:

1. **Error Logging Integration** (lines 29-39, multiple error points)
   - Comprehensive error-handling library sourcing
   - Workflow metadata initialization
   - Structured error logging at all failure points
   - Contextual error details in JSON format

2. **Executable/Documentation Separation** (311 lines exec, 1,241 lines guide)
   - Lean executable with bash blocks and verification
   - Comprehensive guide with architecture, examples, troubleshooting
   - Clear separation of concerns

3. **Output Suppression** (lines 108-113)
   - Library sourcing with 2>/dev/null
   - Utility script output captured and parsed
   - No unnecessary verbosity

4. **Documentation Quality** (setup-command-guide.md)
   - 1,241 lines of comprehensive documentation
   - Usage patterns, workflows, edge cases
   - Troubleshooting section
   - Integration examples

**Areas for Improvement**:

1. **Bash Block Consolidation**
   - Current: 4 blocks
   - Target: 3 blocks
   - Reduction: 25% improvement needed

2. **Verification Checkpoints**
   - Inconsistent across modes
   - Some file operations lack verification
   - Need standardized verification pattern

3. **Agent Invocation Pattern**
   - Enhancement mode uses deprecated SlashCommand
   - Should use modern Task tool pattern
   - Need behavioral injection for consistency

4. **Imperative Language**
   - Mixed tense in output messages
   - Need consistent present tense imperative
   - Minor improvement for standards alignment

**Overall Assessment**: The /setup command demonstrates **good architecture and solid implementation** with recent error logging integration. Primary improvement opportunities are in bash block consolidation (merge enhancement mode), adding comprehensive verification checkpoints, and modernizing agent invocation pattern.

## Section 4: Refactoring Recommendations

### 4.1 High-Priority Refactoring (Critical Impact)

#### Refactor 1: Bash Block Consolidation

**Objective**: Reduce from 4 bash blocks to 3 blocks (25% reduction)

**Approach**: Merge Block 3 (Enhancement Mode) into Block 2 (Mode Execution)

**Implementation**:

**Before** (lines 89-281, 285-313):
```bash
# Block 2: Mode Execution
case "$MODE" in
  standard) ... ;;
  cleanup) ... ;;
  validate) ... ;;
  analyze) ... ;;
  apply-report) ... ;;
esac

# Block 3: Enhancement Mode (Optional)
[ "$MODE" != "enhance" ] && exit 0
echo "Enhancement Mode (delegating to /orchestrate)"
# [Enhancement logic]
```

**After**:
```bash
# Block 2: Mode Execution (Consolidated)
case "$MODE" in
  standard) ... ;;
  cleanup) ... ;;
  validate) ... ;;
  analyze) ... ;;
  apply-report) ... ;;
  enhance)
    echo "Enhancement Mode (delegating to /orchestrate)"
    echo "Project: $PROJECT_DIR"

    ORCH_MSG="Analyze documentation at ${PROJECT_DIR}, enhance CLAUDE.md.

Phase 1: Research (parallel) - Docs discovery, test analysis, TDD detection
Phase 2: Planning - Gap analysis
Phase 3: Implementation - Update CLAUDE.md
Phase 4: Documentation - Workflow summary

Project: ${PROJECT_DIR}"

    echo "Invoking /orchestrate..."
    echo "$ORCH_MSG"
    echo "Wait for /orchestrate to complete"
    ;;
esac
```

**Result**: 3 blocks (Setup/Execute/Cleanup), removing Block 3 entirely

**Benefits**:
- Cleaner output (one less bash execution block)
- More logical structure (all modes in single case statement)
- Aligns with Pattern 8 (Bash Block Consolidation)

**Effort**: 1 hour

**Risk**: Low (straightforward code move)

**Testing**: Run `/setup --enhance-with-docs` and verify output unchanged

#### Refactor 2: Comprehensive Verification Checkpoints

**Objective**: Add fail-fast verification after all file operations

**Approach**: Create reusable verification function and apply consistently

**Implementation**:

**Add to Block 1** (after line 39):
```bash
# Verification helper function
verify_file_created() {
  local file_path="$1"
  local operation="$2"

  if [ ! -f "$file_path" ]; then
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "file_error" \
      "File not created: $file_path" "$operation" \
      "{\"file_path\": \"$file_path\"}"
    echo "ERROR: File not created: $file_path" >&2
    return 1
  fi

  if [ ! -s "$file_path" ]; then
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "file_error" \
      "File is empty: $file_path" "$operation" \
      "{\"file_path\": \"$file_path\"}"
    echo "ERROR: File is empty: $file_path" >&2
    return 1
  fi

  return 0
}

export -f verify_file_created
```

**Apply in Block 2** (replace inline checks):
```bash
# Standard mode (after line 165)
verify_file_created "$CLAUDE_MD_PATH" "standard_mode_generation" || exit 1
echo "✓ Created: $CLAUDE_MD_PATH"

# Analyze mode (after line 255)
verify_file_created "$REPORT" "analyze_mode_report_creation" || exit 1
echo "✓ Report: $REPORT"

# Apply-report mode (add after backup creation at line 271)
verify_file_created "$BACKUP" "apply_report_backup" || exit 1
echo "✓ Backup created: $BACKUP"
```

**Benefits**:
- Consistent verification across all modes
- Reusable function reduces code duplication
- Fail-fast behavior prevents cascading errors
- Better error messages with context

**Effort**: 2 hours

**Risk**: Low (additive change, doesn't modify existing logic)

**Testing**:
- Run each mode and verify error detection
- Test with read-only filesystem to trigger verification failures
- Check error log entries via `/errors --command /setup`

#### Refactor 3: Extract Analysis Logic to Library

**Objective**: Move complex analysis logic from executable to reusable library function

**Rationale**:
- optimize-claude-md.sh has analysis code (lines 36-129) embedded in utility
- /setup has validation code (lines 200-230) embedded in executable
- Both could benefit from shared analysis library

**Approach**: Create `.claude/lib/validation/analyze-claude-md.sh` with reusable functions

**Implementation**:

**New Library File**: `.claude/lib/validation/analyze-claude-md.sh`
```bash
#!/usr/bin/env bash
# CLAUDE.md analysis and validation library

# Validate CLAUDE.md structure
validate_claude_structure() {
  local claude_md="$1"

  if [ ! -f "$claude_md" ]; then
    echo "ERROR: CLAUDE.md not found" >&2
    return 1
  fi

  # Check required sections
  local required=("Code Standards" "Testing Protocols" "Documentation Policy" "Standards Discovery")
  local missing=()

  for section in "${required[@]}"; do
    if ! grep -q "^## $section" "$claude_md"; then
      missing+=("$section")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    echo "WARNING: Missing sections:"
    printf '  - %s\n' "${missing[@]}"
    return 2  # Warning, not fatal
  fi

  echo "✓ All required sections present"
  return 0
}

# Check section metadata
check_section_metadata() {
  local claude_md="$1"

  local no_meta=$(grep -n "^## " "$claude_md" | while read line; do
    local ln=$(echo "$line" | cut -d: -f1)
    if ! sed -n "$((ln + 1))p" "$claude_md" | grep -q "\[Used by:"; then
      echo "$line" | cut -d: -f2-
    fi
  done)

  if [ -n "$no_meta" ]; then
    echo "WARNING: Sections missing [Used by: ...] metadata:"
    echo "$no_meta"
    return 2  # Warning, not fatal
  fi

  echo "✓ All sections have metadata"
  return 0
}

# Full validation
validate_claude_md() {
  local claude_md="$1"

  validate_claude_structure "$claude_md" || return $?
  check_section_metadata "$claude_md" || return $?

  return 0
}
```

**Update /setup** (lines 200-230):
```bash
validate)
  echo "Validation Mode"

  if [ ! -f "$CLAUDE_MD_PATH" ]; then
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "file_error" \
      "CLAUDE.md not found for validation mode" "validate_mode_validation" \
      "{\"expected_path\": \"$CLAUDE_MD_PATH\"}"
    echo "ERROR: CLAUDE.md not found" && exit 1
  fi

  # Use library function
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/validation/analyze-claude-md.sh"
  validate_claude_md "$CLAUDE_MD_PATH"
  VALIDATION_EXIT=$?

  if [ $VALIDATION_EXIT -eq 1 ]; then
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "validation_error" \
      "CLAUDE.md validation failed" "validate_mode" \
      "{\"file\": \"$CLAUDE_MD_PATH\"}"
    exit 1
  fi

  [ $VALIDATION_EXIT -eq 2 ] && echo "⚠ Validation completed with warnings"
  [ $VALIDATION_EXIT -eq 0 ] && echo "✓ Validation successful"
  ;;
```

**Benefits**:
- Reusable validation logic across commands
- Testable library functions
- Cleaner executable code
- Consistent validation behavior

**Effort**: 3 hours (2 for library, 1 for integration and testing)

**Risk**: Medium (requires careful refactoring to maintain behavior)

**Testing**:
- Unit test library functions independently
- Integration test with /setup --validate
- Test with valid, invalid, and warning-level CLAUDE.md files

### 4.2 Medium-Priority Refactoring (Quality Improvement)

#### Refactor 4: Modernize Agent Invocation Pattern

**Objective**: Replace deprecated SlashCommand pattern with Task tool and behavioral injection

**Current Pattern** (lines 299-312):
```bash
echo "Invoking /orchestrate..."
echo "$ORCH_MSG"
echo "Wait for /orchestrate to complete"
```

**Modern Pattern** (from /plan command reference):
```bash
enhance)
  echo "Enhancement Mode"
  echo "Project: $PROJECT_DIR"

  # Construct behavioral injection prompt
  ORCHESTRATOR_PROMPT="Read and follow ALL behavioral guidelines from:
${CLAUDE_PROJECT_DIR}/.claude/agents/orchestrator.md

You are orchestrating: CLAUDE.md enhancement workflow

**Workflow-Specific Context**:
- Project Directory: ${PROJECT_DIR}
- Enhancement Goal: Discover documentation and enhance CLAUDE.md
- Research Focus: Documentation structure, testing infrastructure, TDD practices
- Output Location: ${PROJECT_DIR}/CLAUDE.md

**Phases**:
1. Research (parallel execution):
   - Discover docs/ files and analyze structure
   - Detect testing infrastructure and frameworks
   - Identify TDD practices and patterns

2. Planning:
   - Analyze gaps between existing CLAUDE.md and discoveries
   - Prioritize enhancements
   - Create enhancement plan

3. Implementation:
   - Update CLAUDE.md with discovered standards
   - Add testing protocol details
   - Integrate documentation links

4. Documentation:
   - Create workflow summary
   - Document enhancement decisions

Execute workflow according to behavioral guidelines and return completion signal:
WORKFLOW_COMPLETE: [summary]"

  # Note: Actual Task tool invocation would be handled by parent context
  # This command displays the prompt for Claude Code to invoke orchestrator
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Enhancement requires orchestration:"
  echo "$ORCHESTRATOR_PROMPT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  ;;
```

**Benefits**:
- Structured agent invocation with clear expectations
- Behavioral guidelines explicitly referenced
- Expected output format specified
- Consistent with modern command patterns

**Limitation**: Task tool invocation from within command files is not directly supported. Command can construct and display the prompt for Claude Code to invoke.

**Effort**: 2 hours

**Risk**: Low (improves clarity, maintains compatibility)

**Testing**: Run `/setup --enhance-with-docs` and verify prompt quality

#### Refactor 5: Standardize Output Messages to Imperative Form

**Objective**: Update all output messages to use present tense imperative language

**Changes**:

| Line | Current | Improved |
|------|---------|----------|
| 83 | "Setup complete: Mode=$MODE" | "Running setup: Mode=$MODE" |
| 105 | "Generating CLAUDE.md" | ✓ Already imperative |
| 166 | "✓ Created: $CLAUDE_MD_PATH" | "✓ Create CLAUDE.md at $CLAUDE_MD_PATH" |
| 170 | "Cleanup Mode" | "Running cleanup mode" |
| 197 | "✓ Cleanup complete" | "✓ Complete cleanup" |
| 200 | "Validation Mode" | "Running validation mode" |
| 232 | "Analysis Mode" | "Running analysis mode" |
| 268 | "Applying report" | "Apply report to CLAUDE.md" |
| 299 | "Enhancement Mode (delegating to /orchestrate)" | "Run enhancement via orchestration" |

**Implementation**: Search and replace with imperative forms

**Benefits**:
- Consistent language throughout command
- Aligns with Standard 3 (Imperative Language)
- More active, clearer intent

**Effort**: 1 hour

**Risk**: Minimal (cosmetic change)

**Testing**: Visual review of all modes' output

#### Refactor 6: Add Pre-Existence Check and Backup in Standard Mode

**Objective**: Prevent accidental overwrite of existing CLAUDE.md without backup

**Current Behavior** (lines 115-165):
- Standard mode generates CLAUDE.md
- No check if file already exists
- No backup creation
- Overwrites without warning

**Improved Behavior**:
```bash
standard)
  echo "Generating CLAUDE.md"

  # Check if CLAUDE.md already exists
  if [ -f "$CLAUDE_MD_PATH" ]; then
    echo "WARNING: CLAUDE.md already exists at $CLAUDE_MD_PATH"

    # Create backup before overwriting
    BACKUP="${CLAUDE_MD_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
    if ! cp "$CLAUDE_MD_PATH" "$BACKUP" 2>/dev/null; then
      log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "file_error" \
        "Failed to create backup before overwrite" "standard_mode_backup" \
        "{\"file\": \"$CLAUDE_MD_PATH\"}"
      echo "ERROR: Cannot create backup" >&2
      exit 1
    fi
    echo "✓ Backup created: $BACKUP"
  fi

  # [Existing generation logic follows]
  # Detect testing...
  # Generate protocols...
  # Create CLAUDE.md...
```

**Benefits**:
- Prevents accidental data loss
- Consistent with cleanup and apply-report modes (which do create backups)
- User-friendly behavior

**Effort**: 1 hour

**Risk**: Low (additive change)

**Testing**:
- Run /setup on project with existing CLAUDE.md
- Verify backup created
- Verify original content preserved in backup

### 4.3 Low-Priority Refactoring (Nice-to-Have)

#### Refactor 7: Extract Library Functions for Reusability

**Opportunities**:

1. **Backup Creation** (duplicated in apply-report and cleanup)
   - Extract to `.claude/lib/util/backup-file.sh`
   - Signature: `create_timestamped_backup <file_path>`
   - Returns: backup file path

2. **Report Number Determination** (analyze mode, line 237-238)
   - Extract to `.claude/lib/util/determine-report-number.sh`
   - Signature: `determine_next_report_number <reports_dir>`
   - Returns: NNN formatted number

3. **Project Root Detection** (line 24-27)
   - Extract to `.claude/lib/core/project-detection.sh`
   - Signature: `detect_project_root`
   - Returns: absolute project path

**Benefits**:
- Code reuse across commands
- Testable utility functions
- Consistent behavior

**Effort**: 4 hours (1 hour per function + integration)

**Risk**: Low (utilities are self-contained)

#### Refactor 8: Enhanced Dry-Run Support Across All Modes

**Current**: Only cleanup mode supports --dry-run

**Proposed**: Extend to all modes

**Implementation**:

```bash
# Block 1: Add DRY_RUN handling for all modes
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    # [other args]
  esac
done

# Block 2: Mode execution with dry-run guards
case "$MODE" in
  standard)
    if [ "$DRY_RUN" = true ]; then
      echo "DRY RUN: Would create CLAUDE.md at $CLAUDE_MD_PATH"
      echo "DRY RUN: Would detect testing in $PROJECT_DIR"
      echo "DRY RUN: Would generate protocols based on detection"
      exit 0
    fi
    # [actual logic]
    ;;

  validate)
    if [ "$DRY_RUN" = true ]; then
      echo "DRY RUN: Would validate CLAUDE.md structure"
      echo "DRY RUN: Would check sections: ${REQUIRED[*]}"
      echo "DRY RUN: Would verify metadata format"
      exit 0
    fi
    # [actual logic]
    ;;

  # [similar for other modes]
esac
```

**Benefits**:
- Preview mode operations without side effects
- Safer experimentation
- Better user experience

**Effort**: 3 hours

**Risk**: Low (conditional execution, doesn't modify actual logic)

### 4.4 Refactoring Roadmap

**Phase 1: Critical (Week 1)**
- Refactor 1: Bash Block Consolidation (1 hour)
- Refactor 2: Comprehensive Verification (2 hours)
- Refactor 6: Pre-Existence Check (1 hour)

**Phase 2: Quality (Week 2)**
- Refactor 3: Extract Analysis Library (3 hours)
- Refactor 4: Modernize Agent Invocation (2 hours)
- Refactor 5: Imperative Language (1 hour)

**Phase 3: Enhancement (Week 3)**
- Refactor 7: Extract Library Functions (4 hours)
- Refactor 8: Enhanced Dry-Run Support (3 hours)

**Total Effort**: 17 hours over 3 weeks

**Testing Strategy**:
- Unit tests for new library functions
- Integration tests for each mode
- Regression tests to ensure no behavior changes
- Error log verification via `/errors --command /setup`

## Section 5: Related Commands and Ecosystem

### 5.1 Command Dependencies

**Direct Dependencies**:

| Command/Utility | Relationship | Used In |
|----------------|--------------|---------|
| `detect-testing.sh` | Required utility | Standard mode (line 108) |
| `generate-testing-protocols.sh` | Required utility | Standard mode (line 113) |
| `optimize-claude-md.sh` | Required utility | Cleanup mode (line 189) |
| `error-handling.sh` | Required library | All modes (line 30) |

**Optional Dependencies**:

| Command | Relationship | Used In |
|---------|--------------|---------|
| `/orchestrate` | Optional invocation | Enhancement mode (line 311) |
| `/validate-setup` | Equivalent command | Validation mode alternative |
| `/errors` | Query utility | Error log analysis |

**Dependency Graph**:
```
/setup
├── Required Libraries
│   ├── error-handling.sh (error logging)
│   └── [project detection uses git]
├── Required Utilities
│   ├── detect-testing.sh (score-based framework detection)
│   ├── generate-testing-protocols.sh (adaptive protocol generation)
│   └── optimize-claude-md.sh (bloat analysis and extraction)
└── Optional Commands
    ├── /orchestrate (enhancement mode delegation)
    ├── /validate-setup (equivalent to --validate mode)
    └── /errors (error log querying)
```

### 5.2 Commands That Depend on /setup

**Commands That Reference /setup**:

1. `/plan` - May suggest running /setup if CLAUDE.md missing
2. `/build` - Reads CLAUDE.md (generated by /setup) for standards
3. `/research` - Uses CLAUDE.md as context source
4. `/debug` - References error logs (setup integrates error logging)
5. `/errors` - Queries setup command errors

**Workflow Integration**:

```
Project Initialization Workflow:
1. /setup                    # Create CLAUDE.md with detected standards
2. /setup --validate         # Verify structure
3. /plan <feature>           # Plan reads CLAUDE.md for standards
4. /build <plan>             # Build follows CLAUDE.md standards
5. /errors --command /setup  # Debug any setup issues
```

### 5.3 Alternative Commands and Tools

**Alternatives to /setup**:

1. **Manual CLAUDE.md Creation**
   - User writes CLAUDE.md by hand
   - Pro: Full control
   - Con: Time-consuming, may miss best practices

2. **Template-Based Approach**
   - Copy CLAUDE.md template from examples
   - Pro: Quick start
   - Con: May not fit project specifics

3. **/setup** (Recommended)
   - Auto-detects project context
   - Pro: Fast, accurate, standards-compliant
   - Con: May need manual refinement

**Alternatives to /setup --cleanup**:

1. **Manual Extraction**
   - User creates docs/ files manually
   - Updates CLAUDE.md links manually
   - Pro: Full control over structure
   - Con: Error-prone, time-consuming

2. **optimize-claude-md.sh** (Direct)
   - Run utility script directly
   - Pro: Same analysis, bypasses /setup wrapper
   - Con: No error logging integration

3. **/setup --cleanup** (Recommended)
   - Automated analysis and extraction
   - Pro: Fast, consistent, creates backups
   - Con: May need manual review of extractions

### 5.4 Integration Points

**Configuration Files Read**:
- `.git/config` (for project root detection via `git rev-parse`)
- Project files (for testing framework detection)
- `.editorconfig`, `package.json`, etc. (for standards analysis in guide's full workflow)

**Configuration Files Written**:
- `CLAUDE.md` (primary output)
- `docs/TESTING.md`, `docs/CODE_STYLE.md`, etc. (cleanup mode extractions)
- `.claude/specs/reports/NNN_*.md` (analysis mode reports)
- `.claude/backups/CLAUDE.md.TIMESTAMP` (backup files)

**Error Log Integration**:
- Writes to: `.claude/.error-log.jsonl`
- Query via: `/errors --command /setup`
- Enables: Post-mortem debugging, error trend analysis

**Agent Integration**:
- Enhancement mode can invoke orchestrator agent
- Orchestrator coordinates research-specialist, plan-architect, code-writer, documentation-writer

## Section 6: Common Questions and Troubleshooting

### 6.1 Frequently Asked Questions

**Q1: What's the difference between /setup and /setup --cleanup?**

A:
- `/setup` (standard mode): Creates new CLAUDE.md with auto-detected standards
- `/setup --cleanup`: Optimizes existing CLAUDE.md by extracting bloated sections to docs/ files

Use `/setup` for initial project setup. Use `/setup --cleanup` when CLAUDE.md grows too large.

**Q2: Can I run /setup multiple times on the same project?**

A: Yes, but be aware:
- Standard mode **overwrites** existing CLAUDE.md without backup (see Refactor 6 recommendation)
- Cleanup mode creates automatic backups before modifications
- Use `--dry-run` with cleanup to preview changes first

**Q3: How does testing framework detection work?**

A: detect-testing.sh uses a **score-based system** (0-6 points):
- CI/CD configs: +2 points
- Test directories: +1 point
- >10 test files: +1 point
- Coverage tools: +1 point
- Test runners: +1 point

Higher scores generate more detailed testing protocols.

**Q4: What if my tests are in a non-standard location?**

A: Options:
1. Move tests to standard directory (tests/, test/, spec/) - **recommended**
2. Add test runner script (run_tests.sh) - adds +1 point
3. Add CI/CD config - adds +2 points
4. Manually edit generated CLAUDE.md after /setup runs

**Q5: How do I know which threshold to use for cleanup?**

A: Guidelines:
- **Aggressive** (>50 lines): Use for very large CLAUDE.md (>400 lines), maximum extraction
- **Balanced** (>80 lines): **Default** for moderate CLAUDE.md (300-400 lines)
- **Conservative** (>120 lines): Use for already lean CLAUDE.md (<300 lines), minimal extraction

Run `/setup --cleanup --dry-run` to preview impact before deciding.

**Q6: What's the purpose of analyze mode?**

A: Analyze mode generates a **gap analysis report template** comparing:
- CLAUDE.md documented standards
- Actual codebase patterns
- Config file settings

Fill the `[FILL IN: ...]` sections manually, then apply with `/setup --apply-report <path>`.

Note: Current implementation is **basic**. For comprehensive analysis, use `/orchestrate` with research agents.

**Q7: Can I undo cleanup operations?**

A: Yes! Cleanup mode automatically creates timestamped backups:
```bash
# Backup location
.claude/backups/CLAUDE.md.YYYYMMDD-HHMMSS

# Manual rollback
cp .claude/backups/CLAUDE.md.20251120-143022 CLAUDE.md

# Or use utility's rollback function
.claude/lib/util/optimize-claude-md.sh --rollback .claude/backups/CLAUDE.md.20251120-143022 CLAUDE.md
```

**Q8: Why does enhancement mode just display a message?**

A: Enhancement mode **delegates to /orchestrate** by displaying the orchestration prompt. Claude Code sees the prompt and invokes the orchestrator agent. This is a **pattern limitation** - commands cannot directly invoke other commands via Task tool. See Refactor 4 for modernization approach.

**Q9: How do I query errors from /setup?**

A: Use the `/errors` command:
```bash
# All setup errors
/errors --command /setup

# Recent setup errors (last 2 hours)
/errors --command /setup --since "2 hours ago"

# Validation errors only
/errors --command /setup --type validation_error

# With error details
/errors --command /setup --limit 5
```

**Q10: Can I customize the generated CLAUDE.md?**

A: Yes! After /setup generates CLAUDE.md:
1. Edit manually to add project-specific standards
2. Add custom sections (keep `## Heading` format)
3. Add `[Used by: ...]` metadata to sections
4. Run `/setup --validate` to verify structure

The generated CLAUDE.md is a **starting point**, not a final product.

### 6.2 Troubleshooting Common Issues

#### Issue 1: Testing Score is 0 Despite Having Tests

**Symptoms**:
```bash
$ .claude/lib/util/detect-testing.sh .
SCORE:0
FRAMEWORKS:none
```

**Causes**:
1. Tests in non-standard location
2. Test files don't match patterns (*test*, *spec*)
3. No CI/CD config or test runner

**Solutions**:

**Option A - Move to Standard Location**:
```bash
# Create standard test directory
mkdir tests/

# Move test files
mv my_custom_tests/*.py tests/

# Re-run detection
.claude/lib/util/detect-testing.sh .
# SCORE:1 (test directory +1)
```

**Option B - Add Test Runner** (+1 point):
```bash
# Create test runner script
cat > run_tests.sh << 'EOF'
#!/bin/bash
# Run all tests
python -m pytest my_custom_tests/
EOF

chmod +x run_tests.sh

# Re-run detection
.claude/lib/util/detect-testing.sh .
# SCORE:1 (test runner +1)
```

**Option C - Add CI/CD Config** (+2 points):
```bash
# Create GitHub Actions workflow
mkdir -p .github/workflows/
cat > .github/workflows/test.yml << 'EOF'
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: ./run_tests.sh
EOF

# Re-run detection
.claude/lib/util/detect-testing.sh .
# SCORE:3 (CI/CD +2, test runner +1)
```

#### Issue 2: CLAUDE.md Overwritten Without Backup

**Symptoms**: Ran `/setup` on project with existing CLAUDE.md, lost custom content

**Cause**: Standard mode doesn't check for existing file or create backup (see Refactor 6)

**Recovery**:
```bash
# Check git history (if project uses git)
git log --oneline CLAUDE.md
git show HEAD~1:CLAUDE.md > CLAUDE.md.recovered

# Or check editor's auto-save/backup
# (vim: .CLAUDE.md.swp, emacs: #CLAUDE.md#)
```

**Prevention**:
- Commit CLAUDE.md before running /setup
- Or use `/setup --cleanup` which does create backups

#### Issue 3: Cleanup Mode Shows No Bloated Sections

**Symptoms**:
```bash
$ /setup --cleanup
# ...
## Section Analysis
| Section | Lines | Status | Recommendation |
|---------|-------|--------|----------------|
| Code Standards | 45 | Optimal | Keep inline |
| Testing Protocols | 55 | Optimal | Keep inline |
# ...
- **Bloated sections**: 0
```

**Causes**:
1. CLAUDE.md already well-optimized
2. Threshold too high for current file size
3. Sections naturally fit within limits

**Solutions**:

**If File Feels Large** - Try aggressive threshold:
```bash
/setup --cleanup --threshold aggressive --dry-run
# Bloated threshold: >50 lines (vs default >80)
```

**If Truly Optimal** - No action needed! This is good:
```
✓ CLAUDE.md is well-structured and concise
```

#### Issue 4: Apply-Report Shows "No Filled Gaps"

**Symptoms**:
```bash
$ /setup --apply-report .claude/specs/reports/001_standards_analysis.md
# WARNING: No filled gaps. Edit report first.
```

**Cause**: Report still has placeholder `[FILL IN: ...]` sections without decisions

**Solution**:
```bash
# Open report in editor
vim .claude/specs/reports/001_standards_analysis.md

# Find sections like:
# [FILL IN: Indentation]
# Context: CLAUDE.md says "2 spaces", codebase uses 4 spaces
# Recommendation: Update to "4 spaces"
# Decision: _______________
# Rationale: _______________

# Fill in:
# Decision: 4 spaces
# Rationale: Match existing codebase convention

# Save and retry
/setup --apply-report .claude/specs/reports/001_standards_analysis.md
# Found gaps:
# Indentation=4 spaces
```

#### Issue 5: Enhancement Mode Doesn't Start Orchestration

**Symptoms**:
```bash
$ /setup --enhance-with-docs
# Enhancement Mode (delegating to /orchestrate)
# [Displays orchestration message]
# Wait for /orchestrate to complete
# [Nothing happens]
```

**Cause**: Enhancement mode **displays prompt** for Claude Code to invoke orchestrator, but doesn't directly invoke it (current pattern limitation)

**Solution**: Enhancement mode is designed for interactive use with Claude Code AI. If running programmatically:

**Option A - Use /orchestrate directly**:
```bash
# Instead of /setup --enhance-with-docs, use:
# (Construct orchestration prompt manually)
```

**Option B - Manual enhancement**:
```bash
# 1. Run analysis
/setup --analyze

# 2. Run validation
/setup --validate

# 3. Manually enhance CLAUDE.md based on findings
```

#### Issue 6: Project Directory Not Detected Correctly

**Symptoms**: `/setup` creates CLAUDE.md in wrong location

**Cause**:
- Not in git repository (git rev-parse fails)
- Complex worktree setup
- Symbolic links

**Solution**:

**Specify Directory Explicitly**:
```bash
# Instead of:
cd /path/to/project && /setup

# Use:
/setup /path/to/project
```

**Check Detection**:
```bash
# Line 24-27 logic:
git rev-parse --show-toplevel 2>/dev/null || pwd

# Verify:
cd /path/to/project
git rev-parse --show-toplevel  # Should show project root
```

**For Non-Git Projects**: Detection falls back to `pwd`, so run /setup from desired location.

### 6.3 Error Log Analysis

**Common Errors and Meanings**:

**validation_error - Missing report path**:
```json
{
  "command": "/setup",
  "workflow_id": "setup_1234567890",
  "error_type": "validation_error",
  "error_message": "Missing report path for --apply-report",
  "error_context": "validation",
  "error_details": "{\"mode\": \"apply-report\"}"
}
```

Meaning: User ran `/setup --apply-report` without providing report path
Fix: `/setup --apply-report /path/to/report.md`

**file_error - CLAUDE.md not created**:
```json
{
  "command": "/setup",
  "workflow_id": "setup_1234567890",
  "error_type": "file_error",
  "error_message": "CLAUDE.md file not created at expected path",
  "error_context": "standard_mode_generation",
  "error_details": "{\"expected_path\": \"/home/user/project/CLAUDE.md\"}"
}
```

Meaning: File creation failed (permissions, disk space, path issue)
Fix: Check directory permissions, disk space, parent directory exists

**execution_error - Cleanup script failed**:
```json
{
  "command": "/setup",
  "workflow_id": "setup_1234567890",
  "error_type": "execution_error",
  "error_message": "Cleanup script failed with exit code 1",
  "error_context": "cleanup_mode_execution",
  "error_details": "{\"script\": \"optimize-claude-md.sh\", \"exit_code\": 1, \"flags\": \"--balanced\"}"
}
```

Meaning: optimize-claude-md.sh utility encountered error
Fix: Run script directly to see detailed error: `.claude/lib/util/optimize-claude-md.sh CLAUDE.md --balanced`

## Recommendations

Based on this comprehensive analysis, here are the **top 5 refactoring priorities** for the /setup command:

### 1. Bash Block Consolidation (High Impact, Low Effort)
- **Merge Block 3 (Enhancement Mode) into Block 2 case statement**
- Reduces from 4 to 3 blocks (25% reduction)
- Aligns with Pattern 8 (Bash Block Consolidation)
- **Effort**: 1 hour | **Impact**: Cleaner output, better structure

### 2. Comprehensive Verification Checkpoints (High Impact, Medium Effort)
- **Add verify_file_created() helper function**
- Apply consistently across all file operations
- **Effort**: 2 hours | **Impact**: Fail-fast execution, better error detection

### 3. Extract Analysis Logic to Library (Medium Impact, Medium Effort)
- **Create .claude/lib/validation/analyze-claude-md.sh**
- Reusable validation functions across commands
- **Effort**: 3 hours | **Impact**: Code reuse, consistency, testability

### 4. Add Pre-Existence Check in Standard Mode (High Impact, Low Effort)
- **Create backup before overwriting existing CLAUDE.md**
- Prevents accidental data loss
- **Effort**: 1 hour | **Impact**: User safety, data protection

### 5. Modernize Agent Invocation (Low Impact, Medium Effort)
- **Replace SlashCommand pattern with structured behavioral prompt**
- Improves consistency with modern command patterns
- **Effort**: 2 hours | **Impact**: Better clarity, future-proof architecture

**Total Priority Refactoring Effort**: 9 hours over 1-2 weeks

**Expected Outcome**: The /setup command will achieve **95%+ standards compliance**, with cleaner output (3 bash blocks), comprehensive error handling, reusable validation library, and user-safe operation that prevents accidental data loss.

## References

**Primary Source Files**:
- `.claude/commands/setup.md` (311 lines) - Command executable
- `.claude/docs/guides/commands/setup-command-guide.md` (1,241 lines) - Comprehensive guide
- `.claude/lib/util/detect-testing.sh` (139 lines) - Testing framework detection
- `.claude/lib/util/generate-testing-protocols.sh` (127 lines) - Protocol generation
- `.claude/lib/util/optimize-claude-md.sh` (242 lines) - Context optimization

**Referenced Standards**:
- `.claude/docs/concepts/patterns/error-handling.md` (630 lines) - Error logging integration
- `.claude/docs/reference/standards/output-formatting.md` (299 lines) - Bash block consolidation
- `.claude/docs/concepts/patterns/executable-documentation-separation.md` - Architecture pattern
- `.claude/docs/concepts/patterns/behavioral-injection.md` - Modern agent invocation
- `.claude/docs/reference/standards/code-standards.md` - Standard 3 (Imperative Language)

**Related Research**:
- `.claude/specs/845_standards_to_modernize_setup_and_optimizeclaude/reports/001_setup_optimize_refactor_plan.md` - Modernization plan
- `.claude/specs/843_optimizeclaude_commands_in_order_to_create_a_plan/reports/001_setup_optimize_claude_analysis.md` - Standards compliance analysis

**Line Number References**:
All line numbers in this report reference the current version of files as analyzed. Line numbers are accurate as of 2025-11-20.
