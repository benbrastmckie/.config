# Validation Patterns and Testing Requirements Research Report

## Metadata
- **Date**: 2025-11-12
- **Agent**: research-specialist
- **Topic**: Validation patterns and testing requirements for link validation implementation
- **Report Type**: codebase analysis
- **Complexity Level**: 2
- **Context**: Research for Plan 085 - Broken Links Fix and Validation System

## Executive Summary

The codebase uses a mature bash-based testing infrastructure with 60+ test files following a consistent pattern of helper functions (pass/fail/info/skip) and result aggregation. Link validation can integrate seamlessly using the existing test runner framework with markdown-link-check as the external validation tool. The plan correctly identifies integration points: bash test scripts for validation, markdown-link-check configuration, and the run_all_tests.sh aggregator.

## Findings

### 1. Existing Test Infrastructure (.claude/tests/)

**Test Framework**: Bash-based testing with standardized helper functions
- **Location**: `/home/benjamin/.config/.claude/tests/`
- **Test Runner**: `/home/benjamin/.config/.claude/tests/run_all_tests.sh` (lines 1-100)
- **Pattern**: All test files follow naming convention `test_*.sh` and `validate_*.sh`
- **Count**: 60+ active test files

**Helper Function Pattern** (from test_parsing_utilities.sh:42-57):
```bash
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  ((TESTS_PASSED++)) || true
  ((TESTS_RUN++)) || true
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  echo "  Reason: $2"
  ((TESTS_FAILED++)) || true
  ((TESTS_RUN++)) || true
}

info() {
  echo -e "${YELLOW}ℹ INFO${NC}: $1"
}
```

**Result Aggregation** (run_all_tests.sh:33-40):
- Discovers test files via `find "$TEST_DIR" -name "test_*.sh"`
- Discovers validation files via `find "$TEST_DIR" -name "validate_*.sh"`
- Combines both into unified test suite
- Tracks TOTAL_TESTS, PASSED_TESTS, FAILED_TESTS, SKIPPED_SUITES

**Key Features**:
- Color-coded output (RED, GREEN, YELLOW, BLUE, NC)
- Skip mechanism via `.skip` files (run_all_tests.sh:52-59)
- Verbose mode support
- Output aggregation and summary reporting

### 2. Validation Utilities in Library

**Existing Validation Functions** (.claude/lib/):
- `validate_generated_plan()` - template-integration.sh:54
- `validate_artifact_references()` - artifact-registry.sh:168
- `validate_commit_message()` - git-commit-utils.sh:119
- `validate_metadata_extraction()` - validate-context-reduction.sh:115
- `verify_file_created()` - verification-helpers.sh:73

**Verification Pattern** (verification-helpers.sh:73):
```bash
verify_file_created() {
  local file_path="$1"
  local description="${2:-file}"

  if [[ ! -f "$file_path" ]]; then
    echo "ERROR: $description not found at: $file_path" >&2
    return 1
  fi

  if [[ ! -s "$file_path" ]]; then
    echo "ERROR: $description is empty: $file_path" >&2
    return 1
  fi

  return 0
}
```

**Testing Detection Library** (.claude/lib/detect-testing.sh:1-139):
- Score-based framework detection (0-6 points)
- Detects CI/CD configs (+2 points)
- Detects test directories (+1 point)
- Detects test runners (+1 point)
- Supports bash-tests framework detection (lines 119-124)

### 3. Link Validation Integration Points

**From Plan 085 Analysis** (.claude/specs/plans/085_broken_links_fix_and_validation.md):

**Phase 4: Link Validation Tooling** (lines 666-1052)
- Tool: markdown-link-check (Node.js based)
- Config: `.claude/config/markdown-link-check.json`
- Scripts:
  - `.claude/scripts/validate-links.sh` (full validation)
  - `.claude/scripts/validate-links-quick.sh` (recent files only)

**Validation Script Pattern** (lines 758-847):
```bash
#!/bin/bash
# Validate markdown links in active documentation
set -e

CONFIG_FILE=".claude/config/markdown-link-check.json"
OUTPUT_DIR=".claude/tmp/link-validation"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/validation_${TIMESTAMP}.log"

# Color codes (RED, GREEN, YELLOW, NC)
# Directory list (active docs only)
# Loop through files
# Run npx markdown-link-check with config
# Aggregate results and exit with appropriate code
```

**Integration with Test Runner**:
- Run_all_tests.sh already discovers `validate_*.sh` files (line 37)
- Link validation scripts can follow existing naming convention
- Exit codes (0 = pass, 1 = fail) integrate automatically

### 4. Test Coverage for Link Validation

**Recommended Test Files**:

**A. test_link_validation_basics.sh**
- Test markdown-link-check installation and availability
- Test config file parsing (JSON validation)
- Test relative path resolution
- Test anchor link validation
- Test template placeholder ignoring

**B. test_link_validation_integration.sh**
- Test validation script on sample files
- Test error aggregation and reporting
- Test skip patterns (specs/, archive/)
- Test output format and exit codes
- Integration with run_all_tests.sh

**C. validate_link_conventions.sh** (convention compliance checker)
- Scan for absolute paths in active docs
- Scan for broken relative paths
- Verify all README links work
- Check for common anti-patterns

### 5. Validation Script Architecture

**Script Structure** (from plan analysis):

```
validate-links.sh
├── Configuration Loading
│   ├── Config file path
│   └── Directory list (active docs)
├── File Discovery
│   ├── Find all .md files
│   └── Skip specs/ and archive/
├── Link Checking Loop
│   ├── Run markdown-link-check per file
│   ├── Capture output to log
│   └── Track pass/fail counts
├── Result Aggregation
│   ├── Total files checked
│   ├── Files with errors
│   └── Summary statistics
└── Exit Code (0=pass, 1=fail)
```

**Configuration Pattern** (lines 708-753):
```json
{
  "ignorePatterns": [
    {"pattern": "^http"},        // External URLs
    {"pattern": "\\{[^}]+\\}"},  // Template variables
    {"pattern": "NNN_"},         // Placeholders
    {"pattern": "/specs/"},      // Historical docs
    {"pattern": "/archive/"}     // Archived content
  ],
  "timeout": "10s",
  "retryOn429": true,
  "aliveStatusCodes": [200, 206]
}
```

### 6. Testing Best Practices from Codebase

**From test_convert_docs_validation.sh** (lines 1-100):
- Use temporary test directories (`/tmp/test-$$`)
- Setup/cleanup functions for test isolation
- Test counters: TESTS_RUN, TESTS_PASSED, TESTS_FAILED
- Descriptive test function names: `test_validate_magic_numbers()`
- Individual test execution via `run_test()` helper

**From run_all_tests.sh**:
- Aggregate results across all test files
- Support verbose and quiet modes
- Color-coded output for readability
- Summary statistics at end
- Exit code 0 only if all tests pass

**Error Handling Pattern**:
```bash
if command_to_test; then
  pass "Test description"
else
  fail "Test description" "Reason for failure"
fi
```

### 7. Node.js/npm Integration

**Current Status**:
- No package.json in project root (not Node.js project)
- markdown-link-check requires Node.js installation
- Plan recommends: `npm install -g markdown-link-check` or local install

**Integration Pattern** (from plan lines 672-703):
```bash
# Check npm availability
which npm || echo "ERROR: npm not found"

# Install globally
npm install -g markdown-link-check

# OR install locally (preferred for reproducibility)
npm init -y  # if no package.json
npm install --save-dev markdown-link-check
npx markdown-link-check --version
```

**Alternative Consideration**: Could use `lychee` (Rust-based, faster) but markdown-link-check is more configurable

## Recommendations

### 1. Create Three Test Files for Link Validation

**A. test_link_validation_tools.sh** - Tool availability and basic functionality
- Verify Node.js and npm installed
- Verify markdown-link-check available (global or local)
- Test JSON config parsing
- Test basic link checking on sample files
- Estimated: 10 test cases

**B. test_link_validation_patterns.sh** - Pattern matching and skip logic
- Test relative path resolution
- Test absolute path detection
- Test template placeholder ignoring (NNN_, {var}, $VAR)
- Test specs/ and archive/ directory skipping
- Test anchor link validation
- Estimated: 15 test cases

**C. test_link_validation_integration.sh** - End-to-end validation workflow
- Test validate-links.sh script execution
- Test validate-links-quick.sh script execution
- Test error aggregation and reporting
- Test exit code behavior (0 vs 1)
- Test integration with run_all_tests.sh
- Estimated: 8 test cases

### 2. Use Existing Test Infrastructure Patterns

**Helper Functions** - Copy from test_parsing_utilities.sh:
```bash
pass() { echo -e "${GREEN}✓ PASS${NC}: $1"; ((TESTS_PASSED++)); ((TESTS_RUN++)); }
fail() { echo -e "${RED}✗ FAIL${NC}: $1\n  Reason: $2"; ((TESTS_FAILED++)); ((TESTS_RUN++)); }
info() { echo -e "${YELLOW}ℹ INFO${NC}: $1"; }
skip() { echo -e "${YELLOW}⊘ SKIP${NC}: $1"; ((TESTS_RUN++)); }
```

**Test Structure**:
```bash
#!/usr/bin/env bash
set -euo pipefail

# Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="/tmp/link_validation_test_$$"

# Colors and counters
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
TESTS_RUN=0; TESTS_PASSED=0; TESTS_FAILED=0

# Test functions
test_function_1() { ... }
test_function_2() { ... }

# Execution
setup_test_env
test_function_1
test_function_2
cleanup_test_env

# Summary
echo "Tests: $TESTS_RUN | Passed: $TESTS_PASSED | Failed: $TESTS_FAILED"
[[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
```

### 3. Integrate with run_all_tests.sh Automatically

**No Modifications Needed** - run_all_tests.sh already:
- Discovers test_*.sh files automatically
- Discovers validate_*.sh files automatically
- Aggregates results automatically
- Provides skip mechanism via .skip files

**To Skip a Test Temporarily**:
```bash
echo "Reason for skipping" > .claude/tests/test_link_validation_tools.sh.skip
```

### 4. Add Link Validation to Testing Protocol in CLAUDE.md

**Recommended Addition** (to Testing Protocols section):
```markdown
### Link Validation Testing
- **Test Location**: `.claude/tests/test_link_validation_*.sh`
- **Validation Scripts**:
  - `.claude/scripts/validate-links.sh` - Full validation
  - `.claude/scripts/validate-links-quick.sh` - Recent files (last N days)
- **Tool**: markdown-link-check (Node.js)
- **Config**: `.claude/config/markdown-link-check.json`
- **Coverage Target**: 100% of active documentation links valid
- **Test Categories**:
  - `test_link_validation_tools.sh` - Tool availability (5 tests)
  - `test_link_validation_patterns.sh` - Pattern matching (15 tests)
  - `test_link_validation_integration.sh` - E2E workflow (8 tests)
```

### 5. Create Validation Wrapper for Pre-commit Hook

**Recommended Pattern** (from plan lines 976-1027):
```bash
#!/bin/bash
# Pre-commit hook: Validate links in staged markdown files

# Get staged markdown files
staged_md_files=$(git diff --cached --name-only --diff-filter=ACMR | grep '\.md$' || true)

if [[ -z "$staged_md_files" ]]; then
  exit 0  # No markdown files staged
fi

# Skip specs and archive
active_files=""
for file in $staged_md_files; do
  if [[ ! "$file" =~ /specs/ ]] && [[ ! "$file" =~ /archive/ ]]; then
    active_files="$active_files $file"
  fi
done

if [[ -z "$active_files" ]]; then
  exit 0
fi

# Validate each file
errors=0
for file in $active_files; do
  if ! npx markdown-link-check "$file" --config .claude/config/markdown-link-check.json --quiet; then
    ((errors++))
  fi
done

if [[ $errors -gt 0 ]]; then
  echo "Pre-commit validation failed: $errors file(s) have broken links"
  echo "Fix links or use 'git commit --no-verify' to skip"
  exit 1
fi

exit 0
```

### 6. Testing Validation Script Output Parsing

**Test validate-links.sh Output Format**:
```bash
test_validation_output_format() {
  local output
  output=$(./.claude/scripts/validate-links.sh 2>&1)

  # Check for required sections
  if echo "$output" | grep -q "Markdown Link Validation"; then
    pass "Validation header present"
  else
    fail "Missing validation header" "$output"
  fi

  if echo "$output" | grep -q "Summary"; then
    pass "Summary section present"
  else
    fail "Missing summary section" "$output"
  fi

  # Check exit code behavior
  if ./.claude/scripts/validate-links.sh; then
    pass "Validation returns 0 on success"
  else
    fail "Validation should return 0 when all links valid" "Exit code: $?"
  fi
}
```

## References

### Test Infrastructure Files
- `/home/benjamin/.config/.claude/tests/run_all_tests.sh` (lines 1-100) - Main test runner
- `/home/benjamin/.config/.claude/tests/test_parsing_utilities.sh` (lines 42-57) - Helper function pattern
- `/home/benjamin/.config/.claude/tests/test_convert_docs_validation.sh` (lines 1-100) - Validation test example
- `/home/benjamin/.config/.claude/lib/detect-testing.sh` (lines 1-139) - Framework detection
- `/home/benjamin/.config/.claude/lib/verification-helpers.sh` (line 73) - verify_file_created()

### Validation Utilities
- `/home/benjamin/.config/.claude/lib/template-integration.sh` (line 54) - validate_generated_plan()
- `/home/benjamin/.config/.claude/lib/artifact-registry.sh` (line 168) - validate_artifact_references()
- `/home/benjamin/.config/.claude/lib/git-commit-utils.sh` (line 119) - validate_commit_message()
- `/home/benjamin/.config/.claude/lib/validate-context-reduction.sh` (lines 115-349) - Multiple validation functions

### Plan References
- `/home/benjamin/.config/.claude/specs/plans/085_broken_links_fix_and_validation.md` (lines 666-1052) - Phase 4: Link Validation Tooling
- Lines 708-753: Configuration pattern
- Lines 758-847: Validation script structure
- Lines 976-1027: Pre-commit hook pattern

### Testing Documentation
- CLAUDE.md Testing Protocols section - Current test requirements and patterns
- `.claude/tests/` directory - 60+ test files following consistent patterns
