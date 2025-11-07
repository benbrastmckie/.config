# /test Command - Complete Guide

**Executable**: `.claude/commands/test.md`

**Quick Start**: Run `/test <target> [test-type]` - the command is self-executing.

---

## Table of Contents

1. [Overview](#overview)
2. [Usage](#usage)
3. [Test Detection Strategy](#test-detection-strategy)
4. [Test Execution Process](#test-execution-process)
5. [Supported Frameworks](#supported-frameworks)
6. [Error Analysis](#error-analysis)
7. [Agent Integration](#agent-integration)
8. [Troubleshooting](#troubleshooting)

---

## Overview

The `/test` command runs project-specific tests based on protocols defined in CLAUDE.md, automatically detecting the test framework and executing appropriate test commands.

### When to Use

- Run tests for specific features, modules, or files
- Execute test suites during development
- Verify implementation before committing
- Validate bug fixes with targeted tests
- Check coverage after adding functionality

### Key Features

- **Protocol Discovery**: Extracts test commands from CLAUDE.md testing_protocols section
- **Smart Detection**: Identifies test framework from project structure
- **Multi-Framework**: Supports Neovim/Lua, Node.js, Python, Rust, Go, and more
- **Enhanced Error Analysis**: Provides actionable suggestions for test failures
- **Agent Delegation**: Uses specialized agent for complex test scenarios

---

## Usage

### Syntax

```bash
/test <target> [test-type]
```

### Arguments

- `<target>` (required): Feature name, module path, or file path to test
- `[test-type]` (optional): Type of tests to run (default: `all`)

### Test Types

- `unit`: Run unit tests only
- `integration`: Run integration tests only
- `all`: Run all tests (default)
- `nearest`: Test nearest function/block (if framework supports)
- `file`: Test entire file
- `suite`: Run full test suite

### Examples

#### Test Specific File

```bash
/test tests/auth_spec.lua
```

Runs tests in the specified file.

#### Test Module

```bash
/test src/auth/
```

Runs all tests related to the auth module.

#### Test Feature

```bash
/test authentication unit
```

Runs unit tests for authentication feature.

#### Run Full Suite

```bash
/test . suite
```

Runs the entire test suite.

---

## Test Detection Strategy

The command uses multiple strategies to discover test protocols:

### 1. From CLAUDE.md

Extracts testing information from the `testing_protocols` section:

```markdown
<!-- SECTION: testing_protocols -->
## Testing Protocols

### Test Discovery
- **Test Location**: `.claude/tests/`
- **Test Runner**: `./run_all_tests.sh`
- **Test Pattern**: `test_*.sh`

### Neovim Testing
- **Test Commands**: `:TestNearest`, `:TestFile`, `:TestSuite`
- **Linting**: `<leader>l`

### Coverage Requirements
- >80% for new code
- All public APIs must have tests
<!-- END_SECTION: testing_protocols -->
```

### 2. From Project Structure

Examines project files to identify test framework:

**Node.js Projects**:
- `package.json` with test scripts
- `node_modules/` with jest, mocha, or ava
- Test files: `*.test.js`, `*.spec.js`

**Python Projects**:
- `pytest.ini`, `setup.py`, or `tox.ini`
- `tests/` directory
- Test files: `test_*.py`, `*_test.py`

**Rust Projects**:
- `Cargo.toml`
- Test files: `tests/*.rs`
- Inline tests with `#[test]`

**Go Projects**:
- `go.mod`
- Test files: `*_test.go`

**Lua/Neovim Projects**:
- `tests/` directory
- Test files: `*_spec.lua`, `test_*.lua`
- Neovim test commands: `:TestNearest`, `:TestFile`, `:TestSuite`

### 3. Smart Detection Fallback

If no explicit configuration found:

1. Analyze file extensions to determine language
2. Search for test framework in dependencies
3. Check for test patterns in existing files
4. Suggest appropriate test setup if none exists

---

## Test Execution Process

### Phase 0: Discover Testing Protocols

1. **CLAUDE_PROJECT_DIR Detection**: Uses Standard 13 to find project root
2. **Parse Arguments**: Extracts target and test type
3. **Load CLAUDE.md**: Reads testing_protocols section if available
4. **Report Configuration**: Shows target and test type

### Phase 1: Identify Test Scope and Commands

1. **Load Protocols**: Extracts test commands from CLAUDE.md
2. **Detect Project Type**: Identifies language and framework
3. **Select Commands**: Chooses appropriate test runner
4. **Report Detection**: Shows detected project type and framework

### Phase 2: Execute Tests

**Simple Execution** (direct):
```bash
# For Node.js
npm test -- "$TARGET"

# For Rust
cargo test "$TARGET"

# For Go
go test "$TARGET"

# For Python
pytest "$TARGET"
```

**Complex Execution** (agent delegation):

For complex scenarios (multi-framework, custom setup, unclear structure), delegates to test specialist agent:

**Agent Task**: Execute tests and provide comprehensive results:
- Discover test framework and commands
- Identify appropriate test scope
- Execute with verbose output and coverage
- Parse results and identify failures
- Suggest fixes using enhanced error analysis

### Phase 3: Analyze Results and Report

1. **Parse Exit Code**: Determines success or failure
2. **Report Status**: Shows pass/fail summary
3. **Enhanced Error Analysis**: For failures, provides detailed diagnostics
4. **Suggest Next Steps**: Recommends `/debug` for investigation

---

## Supported Frameworks

### Neovim/Lua Projects

**Test Commands**:
- `:TestNearest` - Test nearest function/block (cursor position)
- `:TestFile` - Test current file
- `:TestSuite` - Run all tests
- `:TestLast` - Re-run last test

**Linting**:
- `<leader>l` - Run linter via nvim-lint

**Formatting**:
- `<leader>mp` - Format code via conform.nvim

**Custom Tests**:
- Check CLAUDE.md for project-specific commands

### Node.js/JavaScript Projects

**npm Scripts**:
```bash
npm test                 # Run test suite
npm run test:unit        # Unit tests only
npm run test:integration # Integration tests only
npm run test:e2e         # End-to-end tests
npm run test:coverage    # With coverage report
```

**Jest**:
```bash
jest <path>              # Test specific path
jest --coverage          # With coverage
jest --watch             # Watch mode
```

### Python Projects

**pytest**:
```bash
pytest <path>            # Test specific path
python -m pytest         # Full test suite
pytest -k <pattern>      # Test by name pattern
pytest --cov             # With coverage
pytest -v                # Verbose output
```

**unittest**:
```bash
python -m unittest <module>
python -m unittest discover
```

**tox**:
```bash
tox                      # Run all environments
tox -e py39              # Specific environment
```

### Rust Projects

**cargo test**:
```bash
cargo test               # Run all tests
cargo test <name>        # Test specific item
cargo test --package <pkg> # Test specific package
cargo test --doc         # Documentation tests
cargo test -- --nocapture # Show output
```

### Go Projects

**go test**:
```bash
go test ./...            # Test all packages
go test <package>        # Test specific package
go test -v               # Verbose output
go test -cover           # With coverage
go test -run <pattern>   # Test by name pattern
```

### Other Projects

**Make-based**:
```bash
make test                # Run test target
make test-unit           # Unit tests
make test-integration    # Integration tests
```

**Custom Scripts**:
```bash
./scripts/run-tests.sh   # Custom test runner
```

---

## Error Analysis

### Enhanced Error Analysis

When tests fail, the command provides enhanced diagnostics using `.claude/lib/analyze-error.sh`:

**Error Type Classification**:
- `syntax`: Syntax errors in code or tests
- `test_failure`: Assertion failures
- `file_not_found`: Missing files or modules
- `import_error`: Import/require failures
- `null_error`: Null/undefined errors
- `timeout`: Test timeouts
- `permission`: Permission denied errors

**Error Location**:
- File path and line number
- 3 lines of context before/after error
- Specific error message

**Specific Suggestions**:
- 2-3 actionable fixes tailored to error type
- Debug commands for investigation
- Related documentation links

### Example Enhanced Error Output

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

Debug Commands:
- Investigate further: /debug "auth login test failing with nil result"
- View file: nvim tests/auth_spec.lua
- Run tests: :TestNearest or :TestFile
===============================================
```

### Graceful Degradation

For partial test failures:

1. **Document Results**: Shows which tests passed vs. failed
2. **Identify Patterns**: Highlights common failure types (e.g., all timeouts)
3. **Suggest Investigation**:
   - `/debug "<specific test failure description>"`
   - `git diff` to review recent changes
   - Run individual tests: `:TestNearest`

---

## Agent Integration

### Test Specialist Agent

For complex test scenarios, the command delegates to a specialized agent:

**Agent Purpose**:
- Execute tests across multiple frameworks
- Provide structured failure analysis
- Track coverage metrics
- Generate actionable suggestions

**Agent Capabilities**:
- **Multi-Framework Support**: Expertise in Jest, pytest, cargo test, go test, etc.
- **Error Categorization**: Classifies failures by type
- **Coverage Tracking**: Reports code coverage gaps
- **Actionable Suggestions**: Provides specific fixes for failures

**When Agent Delegation Occurs**:
- Complex project structure (multi-language, microservices)
- Custom test setup not in CLAUDE.md
- Detailed diagnostics requested
- Coverage analysis needed

**Direct Execution**:

For simple, well-defined test runs, the command executes directly without agent overhead:
- Single test file
- Standard framework setup
- Clear test protocols in CLAUDE.md

---

## Troubleshooting

### No Tests Found

**Symptom**: "No tests discovered" or "0 tests run"

**Possible Causes**:
- Target path incorrect
- Test files don't match expected pattern
- Test framework not installed

**Resolution**:
1. Verify target path exists: `ls <target>`
2. Check test file naming:
   - Node.js: `*.test.js`, `*.spec.js`
   - Python: `test_*.py`, `*_test.py`
   - Rust: `tests/*.rs`
   - Lua: `*_spec.lua`, `test_*.lua`
3. Install test framework:
   - Node.js: `npm install --save-dev jest`
   - Python: `pip install pytest`
   - Rust: (included with cargo)

### Test Command Not Found

**Symptom**: "command not found: pytest" or similar

**Possible Causes**:
- Test framework not installed
- Framework not in PATH
- Wrong project type detected

**Resolution**:
1. Install missing framework (see above)
2. Check PATH: `which pytest` (or appropriate command)
3. Verify project type detection:
   ```bash
   /test --detect-only .
   ```
4. Update CLAUDE.md with explicit test commands

### Tests Timeout

**Symptom**: Tests hang or timeout

**Possible Causes**:
- Infinite loops in code
- Async operations not completing
- Resource deadlocks
- Network requests hanging

**Resolution**:
1. Run specific test in isolation: `/test <specific-test>`
2. Check for infinite loops or blocking operations
3. Review async/await patterns
4. Add timeout configuration:
   - Jest: `jest --testTimeout=10000`
   - pytest: `pytest --timeout=10`
5. Use `/debug` for detailed investigation

### Coverage Not Generated

**Symptom**: No coverage report after tests

**Possible Causes**:
- Coverage tool not installed
- Coverage flag not specified
- Wrong test command

**Resolution**:
1. Install coverage tool:
   - Node.js: `npm install --save-dev jest` (includes coverage)
   - Python: `pip install pytest-cov`
2. Run with coverage flag:
   - Node.js: `npm test -- --coverage`
   - Python: `pytest --cov`
   - Rust: `cargo test --coverage`
3. Update CLAUDE.md with coverage commands

### Test Failures After Refactor

**Symptom**: Tests fail after code changes

**Possible Causes**:
- API changes broke test expectations
- Test data no longer valid
- Mocks/fixtures outdated

**Resolution**:
1. Review recent changes: `git diff`
2. Update test expectations to match new API
3. Refresh test data and fixtures
4. Update mocks to match new behavior
5. Run `/document` to update documentation
6. Use `/debug` for complex failures

---

## Integration with Other Commands

### Before Testing

- **`/implement`**: Complete implementation before running tests
- **`/document`**: Ensure documentation matches implementation

### After Testing

- **`/debug`**: Investigate test failures in detail
- **`/document`**: Update documentation after fixing issues
- **`git commit`**: Commit with passing tests

### Testing Workflow Example

```bash
# 1. Implement feature
/implement specs/plans/auth-feature.md

# 2. Run targeted tests
/test src/auth/ unit

# 3. If failures, debug
/debug "OAuth2 token validation test failure"

# 4. Run full suite
/test . suite

# 5. Check coverage
/test . all --coverage

# 6. Document and commit
/document "OAuth2 authentication"
git add .
git commit -m "feat(auth): OAuth2 authentication with tests"
```

---

## Output Examples

### Successful Test Run

```
Target: tests/auth_spec.lua
Test Type: all

✓ Testing protocols loaded from CLAUDE.md
Detected project type: lua

Running tests...

✓ All tests passed

Tests Run: 15
Passed: 15
Failed: 0
Skipped: 0
Duration: 2.3s
Coverage: 87%

=== Test Execution Complete ===
```

### Failed Test Run

```
Target: src/auth/oauth2.js
Test Type: unit

✓ Testing protocols loaded from CLAUDE.md
Detected project type: node

Running tests...

❌ Test failures detected
Exit code: 1

Tests Run: 12
Passed: 10
Failed: 2
Skipped: 0

Failed Tests:
1. OAuth2.validateToken - AssertionError: Expected token to be valid
2. OAuth2.refreshToken - TypeError: Cannot read property 'refresh_token' of undefined

===============================================
Enhanced Error Analysis
===============================================

Error Type: test_failure
Location: tests/oauth2.test.js:87

Context (around line 87):
   84  describe('validateToken', () => {
   85    it('should validate valid tokens', () => {
   86      const token = generateTestToken()
   87      expect(oauth2.validateToken(token)).toBe(true)
   88    })
   89  })

Suggestions:
1. Check token generation - verify generateTestToken() returns expected format
2. Review validation logic - ensure validation accepts test token format
3. Check for timing issues - token may have expired

Debug Commands:
- Investigate further: /debug "OAuth2 validateToken test failure"
- View file: nvim tests/oauth2.test.js
- Run test: npm test -- oauth2.test.js
===============================================

For detailed failure analysis:
  /debug "test failure in src/auth/oauth2.js"

=== Test Execution Complete ===
```

---

## Best Practices

### DO

- **Run tests frequently**: Test during development, not just before commits
- **Test small units**: Use targeted tests for faster feedback
- **Check coverage**: Aim for >80% coverage on new code
- **Use appropriate test types**: Unit tests for logic, integration for workflows
- **Fix failures promptly**: Don't accumulate broken tests

### DON'T

- **Skip failing tests**: Fix or remove, don't ignore
- **Commit broken tests**: Ensure tests pass before committing
- **Over-test**: Focus on critical paths and public APIs
- **Neglect test maintenance**: Update tests with code changes
- **Rely on coverage alone**: Coverage doesn't guarantee quality

---

## Notes

- **Framework Agnostic**: Supports multiple test frameworks via protocol discovery
- **CLAUDE.md Integration**: Respects project-specific test protocols
- **Enhanced Diagnostics**: Provides actionable error analysis
- **Agent Delegation**: Uses specialized agent for complex scenarios
- **Fail-Fast**: Reports failures immediately with suggestions
