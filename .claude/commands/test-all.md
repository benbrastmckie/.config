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

Let me run your complete test suite.