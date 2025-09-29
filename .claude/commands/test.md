---
allowed-tools: Bash, Read, Grep, Glob
argument-hint: <feature/module/file> [test-type]
description: Run project-specific tests based on CLAUDE.md testing protocols
command-type: primary
dependent-commands: debug, test-all, document
---

# Run Project Tests

I'll run the appropriate tests for the specified feature, module, or file using the project's testing protocols defined in CLAUDE.md.

## Target and Test Type
- **Target**: $1 (feature name, module path, or file path)
- **Test Type**: $2 (optional: unit, integration, all, nearest, file, suite)

## Process

### 1. Discover Testing Protocols
I'll check for testing protocols in order of priority:
1. **CLAUDE.md** in the project root or parent directories
2. **Project configuration files** (package.json, Makefile, pyproject.toml, etc.)
3. **Test directories** and existing test patterns
4. **Language-specific conventions**

### 2. Identify Test Scope
Based on the target provided, I'll determine:
- **File-specific**: Test a single file
- **Module**: Test all files in a module/directory
- **Feature**: Test related files across modules
- **Suite**: Run the full test suite

### 3. Select Test Commands
From CLAUDE.md or project configuration, I'll use:

#### For Neovim/Lua Projects
- `:TestNearest` - Test nearest function/block
- `:TestFile` - Test current file
- `:TestSuite` - Run all tests
- `:TestLast` - Re-run last test
- Custom lua test commands

#### For Web Projects
- `npm test` - Run test suite
- `npm run test:unit` - Unit tests only
- `npm run test:e2e` - End-to-end tests
- `npm run test:coverage` - With coverage report

#### For Python Projects
- `pytest <path>` - Test specific path
- `python -m pytest` - Full test suite
- `pytest -k <pattern>` - Test by name pattern
- `tox` - Run test environments

#### For Other Projects
- `make test` - Makefile-based testing
- `cargo test` - Rust projects
- `go test ./...` - Go projects
- Custom test scripts

### 4. Execute Tests
I'll run tests with appropriate options:
- **Verbose output** for debugging
- **Coverage reporting** if available
- **Parallel execution** for speed
- **Focused tests** when targeting specific features

### 5. Parse Results
I'll analyze test output to:
- Identify failures and their causes
- Extract coverage metrics
- Note performance issues
- Suggest fixes for failures

## Test Detection Strategy

### From CLAUDE.md
I'll look for patterns like:
- `Testing:` sections
- Command examples with `:Test`
- Test keybindings
- Test script references

### From Project Structure
I'll check for:
- `test/` or `tests/` directories
- `*_test.lua`, `*.test.js`, `test_*.py` files
- `spec/` directories (for BDD-style tests)
- `.github/workflows/` for CI test commands

### Smart Detection
If no explicit test configuration found, I'll:
1. Analyze file extensions to determine language
2. Look for test frameworks in dependencies
3. Check for test patterns in similar files
4. Suggest appropriate test setup if none exists

## Output Format

```
=== Test Execution Report ===

Target: [What was tested]
Test Command: [Command executed]
Test Type: [unit/integration/all]

Results:
- Tests Run: [N]
- Passed: [N]
- Failed: [N]
- Skipped: [N]

[Detailed output if failures]

Coverage: [X%] (if available)
Duration: [Xs]

[Suggestions for failures if any]
```

## Error Recovery

If tests fail, I'll:
1. Show detailed error messages
2. Identify the failing test cases
3. Suggest potential fixes
4. Offer to run tests in debug mode
5. Check if the issue is environment-specific

Let me analyze your project and run the appropriate tests.