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
For testing protocol discovery, see [Testing Integration Patterns](../docs/command-patterns.md#testing-integration-patterns).

**Test-specific discovery:** Extract test commands, coverage thresholds, and framework configuration from CLAUDE.md or project files.

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

## Error Recovery and Enhanced Analysis

If tests fail, I'll provide enhanced error analysis with actionable suggestions:

### 1. Capture Error Output
- Capture complete test output including error messages
- Identify failing test cases and error locations
- Preserve context around failures

### 2. Run Enhanced Error Analysis
```bash
# Analyze error output with enhanced error tool
.claude/lib/analyze-error.sh "$TEST_OUTPUT"
```

### 3. Enhanced Error Report
The analysis provides:
- **Error Type Classification**: syntax, test_failure, file_not_found, import_error, null_error, timeout, permission
- **Error Location**: File and line number with 3 lines of context before/after
- **Specific Suggestions**: 2-3 actionable fixes tailored to the error type
- **Debug Commands**: Next steps for investigation

### 4. Graceful Degradation
For partial test failures:
- Document which tests passed vs. failed
- Identify patterns in failures (e.g., all timeout errors)
- Suggest manual investigation steps:
  - `/debug "<specific test failure description>"`
  - Review recent changes: `git diff`
  - Run individual tests: `:TestNearest`

### 5. Example Enhanced Test Error Output

```
===============================================
Enhanced Error Analysis
===============================================

Error Type: test_failure
Location: tests/auth_spec.lua:42

Context (around line 42):
   39  setup(function()
   40    session = mock_session_factory()
   41  end)
   42  it("should login with valid credentials", function()
   43    local result = auth.login(session, "user", "pass")
   44    assert.is_not_nil(result)
   45  end)

Suggestions:
1. Check test setup - verify mocks and fixtures are initialized correctly
2. Review test data - ensure test inputs match expected types and values
3. Check for race conditions - add delays or synchronization if timing-sensitive
4. Run test in isolation: :TestNearest to isolate the failure

Debug Commands:
- Investigate further: /debug "auth login test failing with nil result"
- View file: nvim tests/auth_spec.lua
- Run tests: :TestNearest or :TestFile
===============================================
```

## Agent Usage

For agent invocation patterns, see [Agent Invocation Patterns](../docs/command-patterns.md#agent-invocation-patterns).

**Test-specific agent:**

| Agent | Purpose | Key Capabilities |
|-------|---------|------------------|
| test-specialist | Execute tests and analyze failures | Multi-framework support, error categorization, coverage tracking |

**Delegation Benefits:**
- Framework expertise across multiple test runners
- Structured failure analysis with error categorization
- Coverage metrics and gap identification
- Actionable suggestions for failures

**Direct Execution:**
Quick tests can execute directly without agent overhead. Delegate for complex test suites or detailed diagnostics.

Let me analyze your project and run the appropriate tests.