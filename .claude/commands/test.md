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

This command can delegate test execution to the `test-specialist` agent:

### test-specialist Agent
- **Purpose**: Execute tests and analyze failures
- **Tools**: Bash, Read, Grep
- **Invocation**: Single agent for each test run
- **Capabilities**: Multi-framework support, error categorization, structured reporting

### Invocation Pattern
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Run tests for [target] using test-specialist protocol"
  prompt: "Read and follow the behavioral guidelines from:
          /home/benjamin/.config/.claude/agents/test-specialist.md

          You are acting as a Test Specialist with the tools and constraints
          defined in that file.

          Test Task: Execute tests for [target]

          Context:
          - Target: [feature/module/file from user]
          - Test Commands: [from CLAUDE.md or detected]
          - Project Standards: CLAUDE.md Testing Protocols

          Execution:
          1. Determine appropriate test command
             - Check CLAUDE.md for test commands
             - Detect test framework from project
             - Run appropriate tests for target

          2. Execute tests and capture output
             - Run test command via Bash
             - Capture stdout and stderr
             - Note execution time

          3. Analyze results
             - Count passed/failed/skipped
             - Extract error messages for failures
             - Categorize errors (compilation, runtime, assertion)
             - Calculate coverage if available

          Output Format:
          - Summary: X passed, Y failed, Z skipped
          - Failure details with file:line references
          - Error categorization
          - Suggested next steps if failures found
  "
}
```

### Agent Benefits
- **Framework Expertise**: Understands multiple test frameworks
- **Error Analysis**: Categorizes failures for easier debugging
- **Structured Output**: Consistent test result format
- **Coverage Tracking**: Reports coverage metrics when available
- **Actionable Suggestions**: Provides next steps for failures

### Workflow Integration
1. User invokes `/test` with target (feature/module/file)
2. Command detects test configuration from CLAUDE.md or project
3. Command delegates to `test-specialist` agent
4. Agent executes tests and analyzes results
5. Command returns formatted test report
6. If failures: User can use `/debug` for investigation

### Direct Execution Mode
For simple, quick tests, the command can execute directly without agent delegation to minimize overhead. Agent delegation is beneficial for:
- Complex test suites requiring analysis
- Multi-framework test execution
- Detailed failure diagnostics
- Coverage report generation

Let me analyze your project and run the appropriate tests.