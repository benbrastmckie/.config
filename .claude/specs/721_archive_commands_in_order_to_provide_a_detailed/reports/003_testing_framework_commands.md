# Testing Framework Commands Research Report

## Metadata
- **Date**: 2025-11-15
- **Agent**: research-specialist
- **Topic**: Testing Framework Commands (test.md, test-all.md)
- **Report Type**: Codebase analysis
- **Complexity Level**: 4

## Executive Summary

The `/test` and `/test-all` commands provide sophisticated multi-framework test execution with intelligent protocol discovery, enhanced error analysis, and optional agent delegation. Both commands support 7+ languages/frameworks through CLAUDE.md protocol extraction and smart project detection, offering coverage analysis, failure categorization, and actionable suggestions through the test-specialist agent pattern.

## Findings

### 1. Command Architecture and Design

#### /test Command Structure
**Location**: `/home/benjamin/.config/.claude/archive/commands/test.md`

**Three-Phase Execution Pattern** (lines 17-145):

1. **Phase 0: Discovery** (lines 17-38)
   - Standard 13 CLAUDE_PROJECT_DIR detection (lines 20-24)
   - Argument parsing for target and test-type (lines 27-38)
   - Test types supported: unit, integration, all, nearest, file, suite

2. **Phase 1: Identify Scope** (lines 40-70)
   - CLAUDE.md protocol extraction (lines 44-52)
   - Project type detection via file markers (lines 55-67)
   - Supports: node, rust, go, lua, python, unknown

3. **Phase 2: Execute Tests** (lines 72-101)
   - Direct execution for simple cases (lines 76-100)
   - Framework-specific command selection
   - Agent delegation for complex scenarios (lines 103-121)

4. **Phase 3: Results Analysis** (lines 123-145)
   - Exit code parsing (lines 127-128)
   - Success/failure reporting (lines 130-141)
   - Enhanced error analysis integration (lines 140)

**Documentation Separation Pattern**:
- Executable: 150 lines (lean, phases-based)
- Guide: 667 lines comprehensive documentation at `.claude/docs/guides/test-command-guide.md`

#### /test-all Command Structure
**Location**: `/home/benjamin/.config/.claude/archive/commands/test-all.md`

**Focused Full-Suite Execution** (132 lines):

1. **Project Analysis** (line 18-21)
   - References shared testing integration patterns
   - Identifies full suite command (`:TestSuite`, `npm test`, `pytest`)

2. **Framework-Specific Execution** (lines 23-54)
   - Neovim/Lua: `:TestSuite` or headless mode (lines 26-33)
   - Node.js: `npm test` with coverage option (lines 35-39)
   - Python: `pytest` with coverage flags (lines 41-47)
   - Other: Make/Cargo/Go test commands (lines 49-54)

3. **Parallel Execution Support** (lines 56-60)
   - Python: `pytest -n auto`
   - Node.js: `npm run test -- --parallel`

4. **Coverage Analysis** (lines 62-67)
   - Optional coverage generation
   - Untested code identification
   - Coverage trend analysis

**Agent Integration** (lines 116-131):
- test-specialist delegation for comprehensive diagnostics
- Coverage gap identification
- Failure grouping and health metrics

### 2. Test Detection and Discovery

#### Multi-Framework Support

**Detection Libraries** (`.claude/lib/detect-testing.sh`):

**Score-Based Detection System** (lines 9-133):
- Score range: 0-6 points based on testing infrastructure maturity
- Scoring criteria:
  - CI/CD configs: +2 points (lines 22-29)
  - Test directories: +1 point (lines 31-34)
  - Test file count >10: +1 point (lines 36-41)
  - Coverage tools: +1 point (lines 43-52)
  - Test runners: +1 point (lines 54-60)

**Framework Detection** (lines 62-124):
- pytest: Detects via pytest.ini, requirements.txt, pyproject.toml (lines 64-70)
- unittest: Searches for test_*.py with unittest imports (lines 72-75)
- jest: Checks jest.config.js, package.json (lines 77-82)
- vitest: Checks vitest.config.ts, package.json (lines 84-89)
- mocha: Searches package.json (lines 91-94)
- plenary: Finds *_spec.lua in tests/ directory (lines 96-101)
- busted: Checks .busted, .rockspec (lines 103-107)
- cargo-test: Detects Cargo.toml (lines 109-112)
- go-test: Finds go.mod and *_test.go files (lines 114-117)
- bash-tests: Detects test_*.sh in .claude/tests/ (lines 119-124)

**Output Format** (lines 126-132):
```
SCORE:N
FRAMEWORKS:framework1 framework2 framework3
```

#### Protocol Generation

**Testing Protocol Generator** (`.claude/lib/generate-testing-protocols.sh`):

**Framework-Specific Documentation** (lines 20-94):
- pytest: Test patterns, commands, configuration files (lines 30-37)
- jest: JavaScript/TypeScript patterns and commands (lines 39-46)
- vitest: Modern JS test runner support (lines 48-55)
- plenary: Neovim/Lua testing with headless support (lines 57-64)
- bash-tests: Shell script test patterns (lines 66-73)
- cargo-test: Rust test attributes and commands (lines 75-82)
- go-test: Go test patterns and coverage (lines 84-91)

**Fallback Guidance** (lines 97-111):
- Recommends frameworks when none detected
- Suggests running `/setup --analyze` for recommendations

**Common Standards** (lines 114-126):
- >80% coverage requirement for new code
- Public API test requirements
- Critical path integration tests
- Regression test standards

### 3. Test Execution Process

#### /test Command Execution

**Discovery Strategy** (test-command-guide.md, lines 102-165):

1. **From CLAUDE.md** (highest priority, lines 106-127)
   - Extracts `testing_protocols` section
   - Test location, runner, pattern, coverage requirements
   - Framework-specific commands

2. **From Project Structure** (secondary, lines 129-156)
   - Node.js: package.json scripts, test file patterns (lines 133-136)
   - Python: pytest.ini, setup.py, test directories (lines 138-141)
   - Rust: Cargo.toml, tests/*.rs (lines 143-146)
   - Go: go.mod, *_test.go (lines 148-150)
   - Lua: tests/ directory, *_spec.lua (lines 152-156)

3. **Smart Fallback** (tertiary, lines 158-165)
   - Analyzes file extensions
   - Searches dependencies
   - Suggests setup if none exists

**Execution Modes**:

1. **Direct Execution** (test.md, lines 76-100)
   - Simple framework-specific commands
   - No agent overhead for straightforward tests
   - Immediate results

2. **Agent Delegation** (test.md, lines 103-121)
   - Complex scenarios: multi-framework, custom setup
   - Comprehensive diagnostics with test-specialist
   - Requirements passed to agent:
     - Discover framework from CLAUDE.md or structure
     - Execute with verbose output and coverage
     - Parse results and identify failures
     - Suggest fixes using enhanced error analysis

#### /test-all Command Execution

**Full Suite Patterns**:

1. **Neovim/Lua** (test-all.md, lines 26-33)
   - Interactive: `:TestSuite`
   - Headless: `nvim --headless -c "TestSuite" -c "qa"`

2. **Node.js** (test-all.md, lines 35-39)
   - Standard: `npm test`
   - Coverage: `npm run test:coverage`

3. **Python** (test-all.md, lines 41-47)
   - Standard: `pytest`
   - Coverage: `pytest --cov=. --cov-report=term-missing`

4. **Other Frameworks** (test-all.md, lines 49-54)
   - Make: `make test`
   - Rust: `cargo test`
   - Go: `go test ./...`

**Parallel Execution** (test-all.md, lines 56-60):
- Python: `pytest -n auto` (automatic CPU detection)
- Node.js: `npm run test -- --parallel`
- Project-specific parallelism

**Coverage Analysis** (test-all.md, lines 62-67):
- Coverage report generation
- Untested code identification
- Coverage improvement suggestions
- Historical trend tracking

### 4. Test Failure Handling

#### Enhanced Error Analysis

**Integration with Error Analysis Library** (test-command-guide.md, lines 318-373):

**Error Type Classification**:
- syntax: Code or test syntax errors
- test_failure: Assertion failures
- file_not_found: Missing files/modules
- import_error: Import/require failures
- null_error: Null/undefined errors
- timeout: Test timeouts
- permission: Permission denied errors

**Error Context Display** (lines 348-361):
- File path and line number
- 3 lines before/after error
- Specific error message
- Stack trace if available

**Actionable Suggestions** (lines 362-367):
- 2-3 tailored fixes per error type
- Debug commands for investigation
- Related documentation links

**Example Output Format** (test-command-guide.md, lines 343-373):
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
1. Check test setup - verify mocks and fixtures
2. Review test data - ensure inputs match expected types
3. Check for race conditions - add delays if timing-sensitive

Debug Commands:
- Investigate: /debug "auth login test failing"
- View file: nvim tests/auth_spec.lua
- Run tests: :TestNearest or :TestFile
===============================================
```

**Graceful Degradation** (test-command-guide.md, lines 375-385):
- Documents which tests passed vs failed
- Identifies failure patterns (all timeouts, same module)
- Suggests investigation paths:
  - `/debug` for specific failures
  - `git diff` for recent changes
  - Individual test runs with `:TestNearest`

#### Test-Specialist Agent Pattern

**Agent Behavioral Guidelines** (`.claude/agents/test-specialist.md`):

**Five-Step Execution Process**:

1. **STEP 1: Discover Test Commands** (lines 46-95)
   - Priority order: CLAUDE.md → test scripts → framework defaults
   - Mandatory verification checkpoint
   - Progress emission: "Test command discovered"

2. **STEP 2: Execute Tests** (lines 97-150)
   - Timeout configuration (120s unit, 300s integration)
   - Full output capture (stdout + stderr)
   - Exit code preservation
   - Progress markers during execution

3. **STEP 3: Analyze Results** (lines 152-221)
   - Parse test counts (total, passed, failed, skipped)
   - Extract failure details (name, location, type, message)
   - Enhanced error analysis integration
   - Pattern identification (clustered failures, timeouts)
   - Performance analysis (slow tests >1s)

4. **STEP 4: Report Findings** (lines 223-302)
   - Structured markdown report (exact template enforced)
   - Failure analysis with code context
   - Minimum 2 suggested fixes per failure
   - Performance notes and recommendations

5. **STEP 5: Return Summary** (lines 304-363)
   - Exact format: `TEST_RESULTS: PASSED|FAILED|PARTIAL`
   - Counts with percentages
   - Duration
   - Top 3 failures if applicable

**Report Template** (lines 367-441):
- Test Results Summary (status, counts, duration)
- Test Execution Details (command, framework, coverage)
- Failures section (location, type, error, analysis, fixes)
- Performance Notes (slow tests, total time, regressions)
- Recommendations (minimum 2 actionable items)

**Error Categorization** (lines 676-703):
- Compilation/Syntax: Parse/compile failures
- Assertion Failures: Expectation mismatches
- Runtime Errors: Exceptions during execution
- Timeout Errors: Excessive execution time
- Flaky Tests: Intermittent failures (race conditions)

**Flaky Test Detection** (lines 535-543):
```
Test: auth/login_spec.lua:42
  Run 1: PASS
  Run 2: FAIL (timeout)
  Run 3: PASS
Status: FLAKY (33% failure rate)
Recommendation: Investigate race condition
```

**Retry Strategy** (lines 490-573):
- Flaky tests: 2 retries with 1s delay
- Command failures: 1 retry after prerequisite check
- Timeouts: 1 retry with increased timeout
- Alternative commands if primary fails

### 5. Coverage Analysis Capabilities

#### Coverage Tool Detection

**Coverage Configuration Files** (detect-testing.sh, lines 43-52):
- Python: `.coveragerc`, `pytest.ini`, `.coverage`
- JavaScript: `jest.config.js`, `jest.config.ts`, `.nyc_output/`
- Generic: `coverage.xml`

**Framework-Specific Coverage Commands**:

1. **Jest** (generate-testing-protocols.sh, lines 41-45)
   - Command: `jest --coverage`
   - Configuration: `jest.config.js`

2. **pytest** (generate-testing-protocols.sh, lines 32-36)
   - Command: `pytest --cov`
   - Configuration: `pytest.ini`, `pyproject.toml`

3. **Cargo** (test-all.md, line 52)
   - Command: `cargo test --coverage`

4. **Go** (test-all.md, line 53)
   - Command: `go test -cover`

#### Coverage Reporting

**test-all Coverage Features** (test-all.md, lines 62-67):
- Generate coverage reports
- Identify untested code sections
- Suggest areas needing tests
- Track coverage trends over time

**Coverage Requirements** (testing-protocols.md, lines 33-38):
- >80% for new code
- 100% for public APIs
- Critical paths require integration tests
- Regression tests for all bug fixes

**Output Format** (test-all.md, lines 91-103):
```
Coverage Report:
---------------
Overall Coverage: X%
- Lines: X%
- Functions: X%
- Branches: X%

Uncovered Areas:
[List of files/functions needing tests]

Recommendations:
[Suggestions for improving coverage]
```

### 6. Use Cases and Best Practices

#### When to Use /test

**Primary Use Cases** (test-command-guide.md, lines 27-33):
- Run tests for specific features, modules, or files
- Execute test suites during development
- Verify implementation before committing
- Validate bug fixes with targeted tests
- Check coverage after adding functionality

**Example Scenarios** (test-command-guide.md, lines 67-98):

1. **Test Specific File**:
   ```bash
   /test tests/auth_spec.lua
   ```

2. **Test Module**:
   ```bash
   /test src/auth/
   ```

3. **Test Feature with Type**:
   ```bash
   /test authentication unit
   ```

4. **Run Full Suite**:
   ```bash
   /test . suite
   ```

#### When to Use /test-all

**Primary Use Cases** (inferred from design):
- Full regression testing before commits
- Pre-deployment validation
- CI/CD integration verification
- Coverage analysis across entire codebase

**Benefits Over /test**:
- Parallel execution support
- Comprehensive coverage analysis
- Full suite health metrics
- Failure aggregation and categorization

#### Integration with Development Workflow

**Testing Workflow** (test-command-guide.md, lines 533-554):
```bash
# 1. Implement feature
/implement specs/plans/auth-feature.md

# 2. Run targeted tests
/test src/auth/ unit

# 3. Debug failures
/debug "OAuth2 token validation test failure"

# 4. Run full suite
/test . suite

# 5. Check coverage
/test . all --coverage

# 6. Document and commit
/document "OAuth2 authentication"
git commit -m "feat(auth): OAuth2 with tests"
```

**Before Testing** (test-command-guide.md, lines 521-524):
- Complete implementation
- Ensure documentation matches code

**After Testing** (test-command-guide.md, lines 526-531):
- Debug failures with `/debug`
- Update documentation
- Commit only with passing tests

### 7. Troubleshooting and Error Recovery

#### Common Issues

**No Tests Found** (test-command-guide.md, lines 423-443):
- **Symptoms**: "No tests discovered", "0 tests run"
- **Causes**: Incorrect path, wrong patterns, missing framework
- **Resolution**:
  1. Verify target path exists
  2. Check test file naming conventions
  3. Install missing framework

**Test Command Not Found** (test-command-guide.md, lines 445-461):
- **Symptoms**: "command not found: pytest"
- **Causes**: Framework not installed, wrong PATH, incorrect detection
- **Resolution**:
  1. Install missing framework
  2. Verify PATH configuration
  3. Update CLAUDE.md with explicit commands

**Tests Timeout** (test-command-guide.md, lines 463-480):
- **Symptoms**: Tests hang or timeout
- **Causes**: Infinite loops, async issues, deadlocks, network hangs
- **Resolution**:
  1. Run specific test in isolation
  2. Check for blocking operations
  3. Review async/await patterns
  4. Add timeout configuration
  5. Use `/debug` for investigation

**Coverage Not Generated** (test-command-guide.md, lines 482-499):
- **Symptoms**: No coverage report
- **Causes**: Tool not installed, missing flag, wrong command
- **Resolution**:
  1. Install coverage tool
  2. Use coverage flags
  3. Update CLAUDE.md

**Test Failures After Refactor** (test-command-guide.md, lines 501-516):
- **Symptoms**: Tests fail after code changes
- **Causes**: API changes, outdated data, stale mocks
- **Resolution**:
  1. Review changes with `git diff`
  2. Update test expectations
  3. Refresh test data and fixtures
  4. Update mocks
  5. Run `/document` and `/debug`

### 8. Performance Characteristics

#### Direct Execution Performance

**Fast Path** (minimal overhead):
- Single test file with known framework
- Standard framework setup in CLAUDE.md
- Clear test protocols
- No complex analysis needed

**Execution Time**: <2 seconds overhead

#### Agent Delegation Performance

**Comprehensive Analysis Path**:
- Multi-framework projects
- Custom test setup
- Detailed diagnostics required
- Coverage analysis needed

**Execution Time**: 5-15 seconds overhead (agent startup + analysis)

**Trade-offs**:
- Direct: Fast, simple, limited diagnostics
- Agent: Slower, comprehensive, actionable insights

#### Parallel Execution Benefits

**test-all Parallelism** (test-all.md, lines 56-60):
- Python: Auto-detects CPU count with `-n auto`
- Node.js: Framework-specific parallel flags
- Typical speedup: 2-4x on multi-core systems

### 9. Standards and Integration

#### CLAUDE.md Integration

**Testing Protocols Section** (testing-protocols.md, lines 1-75):
- Test location and runner configuration
- Test file patterns
- Framework-specific commands
- Coverage requirements
- Test isolation standards

**Discovery Hierarchy**:
1. Project root CLAUDE.md (highest priority)
2. Subdirectory-specific CLAUDE.md
3. Language-specific defaults

#### Test Isolation Standards

**Environment Overrides** (testing-protocols.md, lines 40-72):
```bash
export CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"
export CLAUDE_PROJECT_DIR="/tmp/manual_test_$$"
```

**Key Requirements**:
- Use `mktemp` for unique test directories
- Register cleanup traps: `trap cleanup EXIT`
- Prevent production directory pollution
- Test runner validates isolation

**Detection Point**: `unified-location-detection.sh` checks `CLAUDE_SPECS_ROOT` override to prevent production directory creation during tests.

#### Command Standards Compliance

**Executable/Documentation Separation** (both commands):
- test.md: 150 lines executable, 667 lines guide
- test-all.md: 132 lines executable, referenced shared patterns

**Standard 13 Compliance** (test.md, lines 20-24):
- CLAUDE_PROJECT_DIR detection
- Git repository root fallback
- Export for downstream usage

**Agent Integration Pattern**:
- General-purpose agent with behavior file
- Complete behavioral guidelines in `.claude/agents/test-specialist.md`
- Progress streaming protocol
- Structured return format

## Recommendations

### 1. Command Utility and Preservation

**Recommendation**: Retain both commands in active use; do not archive.

**Rationale**:
- Complementary use cases: `/test` for targeted testing, `/test-all` for full regression
- Sophisticated multi-framework support (7+ languages)
- Mature error analysis integration
- Well-documented with comprehensive guides
- Active integration with test-specialist agent

**Action**: Move from `.claude/archive/commands/` back to `.claude/commands/` if archived.

### 2. Documentation Consolidation Opportunity

**Recommendation**: Merge test-all functionality into test command as optional flag.

**Current Duplication**:
- Both commands share discovery logic
- Similar execution patterns
- Overlapping framework support

**Proposed Consolidation**:
```bash
/test <target> [test-type] [--full-suite] [--coverage] [--parallel]
```

**Benefits**:
- Single command for all testing needs
- Reduced maintenance burden
- Clearer user experience
- Preserved functionality

**Migration Path**:
1. Add `--full-suite` flag to `/test`
2. Add `--coverage` and `--parallel` flags
3. Deprecate `/test-all` with redirect message
4. Update documentation to reflect unified interface

### 3. Enhanced Coverage Integration

**Recommendation**: Standardize coverage reporting across all frameworks.

**Current State**: Coverage support varies by framework and command.

**Proposed Enhancement**:
- Unified coverage output format
- Standardized thresholds (>80% new code, >60% baseline)
- Coverage trend tracking in `.claude/data/coverage-history.json`
- Integration with `/implement` for pre-commit validation

**Implementation**:
- Create `.claude/lib/coverage-analyzer.sh` library
- Normalize coverage reports from all frameworks
- Generate actionable coverage improvement suggestions
- Track historical coverage data

### 4. Test Specialist Agent Enhancement

**Recommendation**: Enhance flaky test detection and reporting.

**Current Capability**: Basic retry with flaky detection (test-specialist.md, lines 535-543).

**Proposed Enhancements**:
- Persistent flaky test tracking in `.claude/data/flaky-tests.json`
- Statistical analysis (failure rate over N runs)
- Automatic quarantine of consistently flaky tests
- Integration with CI/CD for flaky test reporting

**Benefits**:
- Reduced false positive investigation time
- Better test suite health visibility
- Proactive flaky test remediation

### 5. Performance Optimization

**Recommendation**: Implement intelligent test selection for faster feedback.

**Current State**: Full suite or manual scope selection.

**Proposed Enhancement**:
- Git diff analysis to identify changed files
- Dependency graph to find affected test files
- Incremental testing: run only affected tests
- Full suite on demand or pre-commit

**Implementation**:
- Create `.claude/lib/test-selector.sh`
- Build test-to-source dependency map
- Integrate with `/implement` for automatic test selection

**Expected Impact**:
- 50-80% reduction in test execution time during development
- Faster feedback loop
- Full coverage maintained through periodic full runs

## References

### Primary Command Files
- `/home/benjamin/.config/.claude/archive/commands/test.md` - Main test command (150 lines)
- `/home/benjamin/.config/.claude/archive/commands/test-all.md` - Full suite command (132 lines)
- `/home/benjamin/.config/.claude/docs/guides/test-command-guide.md` - Comprehensive test documentation (667 lines)

### Supporting Libraries
- `/home/benjamin/.config/.claude/lib/detect-testing.sh` - Framework detection (139 lines)
- `/home/benjamin/.config/.claude/lib/generate-testing-protocols.sh` - Protocol generation (127 lines)

### Agent Specifications
- `/home/benjamin/.config/.claude/agents/test-specialist.md` - Test execution agent (920 lines)

### Standards and Protocols
- `/home/benjamin/.config/.claude/docs/reference/testing-protocols.md` - Testing standards (75 lines)

### Framework Support
- Python: pytest, unittest (detect-testing.sh:64-75, generate-testing-protocols.sh:30-37)
- JavaScript/TypeScript: jest, vitest, mocha (detect-testing.sh:77-94, generate-testing-protocols.sh:39-55)
- Lua/Neovim: plenary, busted (detect-testing.sh:96-107, generate-testing-protocols.sh:57-64)
- Rust: cargo test (detect-testing.sh:109-112, generate-testing-protocols.sh:75-82)
- Go: go test (detect-testing.sh:114-117, generate-testing-protocols.sh:84-91)
- Bash: test scripts (detect-testing.sh:119-124, generate-testing-protocols.sh:66-73)

### Integration Points
- CLAUDE.md testing_protocols section extraction
- Enhanced error analysis via `.claude/lib/analyze-error.sh`
- Coverage tools: pytest-cov, jest coverage, cargo coverage, go cover
- Test isolation via CLAUDE_SPECS_ROOT override in unified-location-detection.sh
