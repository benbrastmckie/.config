---
allowed-tools: Bash, Read, Grep
argument-hint: [coverage]
description: Run the complete test suite for the project
command-type: dependent
parent-commands: test, implement
---

# Run Complete Test Suite

I'll run the full test suite for your project using the testing protocols defined in CLAUDE.md.

## Options
- **Coverage**: $1 (optional: "coverage" to include coverage report)

## Process

### 1. Project Analysis
I'll determine the project type and testing framework by checking:
- CLAUDE.md for test commands
- Project root for configuration files
- Test directory structure
- Dependencies and test runners

### 2. Test Suite Execution
Based on the project type, I'll run:

#### Neovim/Lua Projects
```vim
:TestSuite
```
Or if not in Neovim:
```bash
nvim --headless -c "TestSuite" -c "qa"
```

#### Node.js Projects
```bash
npm test
# or with coverage
npm run test:coverage
```

#### Python Projects
```bash
pytest
# or with coverage
pytest --cov=. --cov-report=term-missing
```

#### Other Projects
- `make test` for Makefile projects
- `cargo test` for Rust
- `go test ./...` for Go
- Custom test commands from CLAUDE.md

### 3. Parallel Execution
Where supported, I'll use parallel test execution:
- `pytest -n auto` for Python
- `npm run test -- --parallel` for Node.js
- Project-specific parallel options

### 4. Coverage Analysis
If coverage requested, I'll:
- Generate coverage reports
- Identify untested code
- Suggest areas needing tests
- Show coverage trends if historical data exists

## Output Format

```
=== Full Test Suite Execution ===

Project Type: [Detected type]
Test Framework: [Framework used]
Command: [Executed command]

Test Results:
==============
Total Tests: [N]
✓ Passed: [N]
✗ Failed: [N]
⊘ Skipped: [N]

Duration: [Xs]

[If failures exist:]
Failed Tests:
-------------
[List of failed tests with error messages]

[If coverage requested:]
Coverage Report:
---------------
Overall Coverage: [X%]
- Lines: [X%]
- Functions: [X%]
- Branches: [X%]

Uncovered Areas:
[List of files/functions needing tests]

Recommendations:
[Suggestions for improving test coverage]
```

## Integration with CI/CD
I'll also check for CI configuration to ensure local tests match CI:
- `.github/workflows/` for GitHub Actions
- `.gitlab-ci.yml` for GitLab
- `Jenkinsfile` for Jenkins
- Other CI configurations

## Agent Usage

This command can delegate test suite execution to the `test-specialist` agent:

### test-specialist Agent
- **Purpose**: Execute complete test suites with comprehensive reporting
- **Tools**: Bash, Read, Grep
- **Invocation**: Single agent for full test suite execution
- **Capabilities**: Multi-framework support, coverage analysis, aggregated reporting

### Invocation Pattern
```yaml
Task {
  subagent_type: "test-specialist"
  description: "Run complete test suite"
  prompt: "
    Test Suite Task: Execute all project tests

    Context:
    - Coverage requested: [yes/no from --coverage flag]
    - Test Commands: [from CLAUDE.md Testing Protocols]
    - Project Standards: CLAUDE.md

    Execution:
    1. Detect test suite command
       - Check CLAUDE.md for :TestSuite or suite command
       - Detect framework-specific commands
       - Handle coverage flag if requested

    2. Execute full test suite
       - Run complete test suite via Bash
       - Capture all output (stdout/stderr)
       - Track execution time

    3. Analyze comprehensive results
       - Total count: passed/failed/skipped
       - Group failures by type
       - Extract coverage data if available
       - Identify coverage gaps
       - Calculate overall health metrics

    4. Generate detailed report
       - Test suite summary
       - Failure breakdown with diagnostics
       - Coverage report (if --coverage)
       - Recommendations for improvements

    Output Format:
    - Executive summary (pass/fail/skip counts)
    - Detailed failure analysis
    - Coverage metrics (if requested)
    - Recommendations for test improvements
  "
}
```

### Agent Benefits
- **Comprehensive Analysis**: Full test suite diagnostics
- **Coverage Integration**: Automatic coverage reporting when available
- **Failure Aggregation**: Groups related failures
- **Performance Tracking**: Monitors test execution time
- **Health Metrics**: Overall test suite quality assessment

### Workflow Integration
1. User invokes `/test-all` (optionally with `--coverage`)
2. Command detects test configuration from CLAUDE.md
3. Command delegates to `test-specialist` agent
4. Agent executes complete test suite and analyzes results
5. Command returns comprehensive test report
6. If failures: User can use `/debug` or `/test` for specific investigation

### Direct Execution Mode
For quick validation, the command can execute directly without agent delegation. Agent delegation provides additional value for:
- Detailed failure analysis and categorization
- Coverage gap identification
- Test suite health assessment
- Performance trend tracking
- Recommendations for test improvements

Let me run your complete test suite.