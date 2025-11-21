# Test Suite Documentation

This directory contains the comprehensive test suite for the Claude Code agential system, organized into 7 categories for improved discoverability and maintainability.

## Directory Structure

```
tests/
├── unit/               # Library function unit tests (7 files)
├── integration/        # Workflow and command integration tests (10 files)
├── state/              # Checkpoint and persistence tests (9 files)
├── progressive/        # Plan expansion/collapse tests (8 files)
├── topic-naming/       # Topic directory and slug generation tests (11 files)
├── classification/     # Workflow type detection tests (4 files)
├── features/           # Feature-specific tests (40 files in 5 subcategories)
│   ├── convert-docs/   # Document conversion tests (5 files)
│   ├── commands/       # Command-specific tests (4 files)
│   ├── compliance/     # Standards compliance tests (9 files)
│   ├── location/       # Location detection tests (2 files)
│   └── specialized/    # Specialized feature tests (20 files)
├── utilities/          # Test runners, linters, benchmarks (8 files)
│   ├── benchmarks/     # Performance benchmarks
│   └── manual/         # Manual testing tools
└── fixtures/           # Test fixtures and mock data (12 subdirectories)
```

## Test Categories

### Unit Tests (`unit/`)
Library function unit testing for core functionality:
- `test_parsing_utilities.sh` - Plan parsing functions
- `test_error_logging.sh` - Centralized error logging system
- `test_git_commit_utils.sh` - Git commit utilities
- `test_llm_classifier.sh` - LLM-based classification
- `test_array_serialization.sh` - Array data structure operations
- `test_cross_block_function_availability.sh` - Function scoping
- `test_test_executor_behavioral_compliance.sh` - Test executor agent validation

### Integration Tests (`integration/`)
End-to-end workflow and command testing:
- Workflow initialization and scope detection
- Command integration and orchestration
- Recovery and repair workflows
- Location detection integration
- Revision automode testing

### State Tests (`state/`)
Checkpoint and state persistence testing:
- Checkpoint parallel operations
- State machine persistence
- Build state transitions
- Smart checkpoint resume
- State file path consistency

### Progressive Tests (`progressive/`)
Plan structure expansion and collapse:
- Progressive expansion/collapse
- Parallel expansion/collapse
- Plan updates and hierarchy management
- Progress markers and roundtrip operations

### Topic Naming Tests (`topic-naming/`)
Topic directory and slug generation:
- Topic naming algorithms
- Slug validation and sanitization
- Directory naming integration
- Semantic slug commands
- Atomic topic allocation

### Classification Tests (`classification/`)
Workflow type detection and scoping:
- Scope detection (A/B testing)
- Workflow detection
- Offline classification
- LLM classifier integration

### Features Tests (`features/`)
Feature-specific testing organized by domain:
- **convert-docs/**: Document conversion concurrency, edge cases, validation
- **commands/**: Command references, remediation, standards compliance
- **compliance/**: Bash error handling, history expansion, agent validation
- **location/**: Project directory detection, empty directory detection
- **specialized/**: Error recovery, library management, template system, parallel agents

### Utilities (`utilities/`)
Non-test utilities for development:
- `lint_bash_conditionals.sh` - Bash conditional linting
- `lint_error_suppression.sh` - Error suppression pattern validation
- `bench_workflow_classification.sh` - Classification performance benchmarks
- `manual_e2e_hybrid_classification.sh` - Manual end-to-end testing
- Validation scripts for command standards and artifact organization

## Running Tests

### Run All Tests
```bash
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh
```

### Run Tests by Category
```bash
# Run only unit tests
./run_all_tests.sh --category unit

# Run only integration tests
./run_all_tests.sh --category integration

# Run only state tests
./run_all_tests.sh --category state
```

### List All Tests
```bash
./run_all_tests.sh --list
```

### Run Individual Test
```bash
cd unit
./test_parsing_utilities.sh
```

## Test Statistics

- **Total Active Tests**: 89 files (down from 92 after removing 6 obsolete tests)
- **Test Categories**: 7 main categories + 5 features subcategories
- **Documentation Files**: 14 READMEs (1 main + 7 categories + 5 features + 1 fixtures)
- **Test Pass Rate**: ~78.6% (86/97 suites passing - baseline from 2025-11-20)
- **Total Individual Test Cases**: 451 tests

## Archived Tests

Obsolete tests have been archived to `.claude/archive/tests/cleanup-2025-11-20/`:
- 6 obsolete tests removed (debug artifacts, completed migrations, superseded versions)
- Archive includes manifest with removal rationale
- Git history preserved via `git mv` operations

## Test Isolation

All tests use `CLAUDE_SPECS_ROOT` override to prevent pollution of production `.claude/specs/` directory. Tests create temporary directories for spec operations.

**Example Pattern**:
```bash
CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"
export CLAUDE_SPECS_ROOT
```

See `.claude/docs/reference/standards/test-isolation.md` for complete isolation standards.

## Adding New Tests

### Choosing the Right Category

- **Unit**: Testing a single library function in isolation
- **Integration**: Testing command workflows or multi-component interactions
- **State**: Testing checkpoint, persistence, or state management
- **Progressive**: Testing plan structure expansion/collapse
- **Topic-naming**: Testing topic directory or slug generation
- **Classification**: Testing workflow type detection
- **Features**: Testing a specific feature (choose appropriate subcategory)

### Test File Template

```bash
#!/usr/bin/env bash
# test_my_feature.sh - Description of what this tests

set -euo pipefail

# Get script directory (adjust ../ depth based on category level)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"  # For subdirs like unit/
# PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"  # For features/ subdirs

# Source required libraries
source "$PROJECT_ROOT/.claude/lib/plan/plan-core-bundle.sh"

# Test isolation
CLAUDE_SPECS_ROOT="/tmp/test_my_feature_$$"
export CLAUDE_SPECS_ROOT
mkdir -p "$CLAUDE_SPECS_ROOT"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0

# Test functions here
test_my_feature() {
  # Test implementation
  echo "Testing my feature..."
}

# Run tests
test_my_feature

# Cleanup
rm -rf "$CLAUDE_SPECS_ROOT"

# Report
echo "Tests passed: $TESTS_PASSED/$TESTS_RUN"
```

## Test Coverage

See `COVERAGE_REPORT.md` for detailed library coverage analysis:
- 46 library files in `.claude/lib/`
- 7 unit tests (15% library coverage)
- Coverage gaps identified for future test development

## Navigation

- [Testing Protocols](./../docs/reference/standards/testing-protocols.md)
- [Test Isolation Standards](./../docs/reference/standards/test-isolation.md)
- [Coverage Report](./COVERAGE_REPORT.md)
- [Archive Directory](./../archive/tests/cleanup-2025-11-20/README.md)
- [Fixtures Documentation](./fixtures/README.md)

## Recent Changes

**2025-11-20 Reorganization**:
- Reorganized from flat structure (92 files) to 7-category hierarchy
- Removed 6 obsolete tests (archived with rationale)
- Enhanced test runner with recursive subdirectory support
- Fixed build.md test discovery path
- Updated 7 test files for correct relative paths after relocation
- Pass rate improved to 78.6% (up from planned 64%)
- Total reduction: 3 files (92 → 89), focusing on organization over consolidation

**Test Discovery Enhancement**:
- `run_all_tests.sh` now recursively searches subdirectories
- Excludes fixtures/, logs/, validation_results/, tmp/, scripts/
- Supports `--category` flag for selective execution
- Supports `--list` flag to display all tests

**Build Command Integration**:
- Fixed `.claude/run_all_tests.sh` → `.claude/tests/run_all_tests.sh`
- Enables automatic test discovery in `/build` workflow
