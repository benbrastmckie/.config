#!/usr/bin/env bash
# Generate testing protocols section for CLAUDE.md
# Usage: generate-testing-protocols.sh <score> <frameworks>

set -euo pipefail

SCORE="${1:-0}"
FRAMEWORKS="${2:-none}"

# Generate testing protocols based on score and frameworks
cat << EOF
### Test Discovery
Commands should check CLAUDE.md in priority order:
1. Project root CLAUDE.md for test commands
2. Subdirectory-specific CLAUDE.md files
3. Language-specific test patterns

EOF

# Add framework-specific sections if frameworks detected
if [[ "$FRAMEWORKS" != "none" ]]; then
  echo "### Detected Testing Frameworks"
  echo "- **Frameworks**: $FRAMEWORKS"
  echo "- **Test Score**: $SCORE/6"
  echo ""

  # Add specific framework documentation
  for fw in $FRAMEWORKS; do
    case "$fw" in
      pytest)
        cat << 'EOF'
#### Python - pytest
- **Test Pattern**: `test_*.py` or `*_test.py`
- **Test Commands**: `pytest`, `pytest -v`, `pytest --cov`
- **Configuration**: `pytest.ini`, `pyproject.toml`

EOF
        ;;
      jest)
        cat << 'EOF'
#### JavaScript/TypeScript - Jest
- **Test Pattern**: `*.test.js`, `*.spec.js`, `__tests__/*.js`
- **Test Commands**: `npm test`, `jest`, `jest --coverage`
- **Configuration**: `jest.config.js`

EOF
        ;;
      vitest)
        cat << 'EOF'
#### JavaScript/TypeScript - Vitest
- **Test Pattern**: `*.test.ts`, `*.spec.ts`
- **Test Commands**: `npm test`, `vitest`, `vitest run`
- **Configuration**: `vitest.config.ts`

EOF
        ;;
      plenary)
        cat << 'EOF'
#### Lua/Neovim - Plenary
- **Test Pattern**: `*_spec.lua` in tests/ or spec/
- **Test Commands**: `nvim --headless -c "PlenaryBustedDirectory tests/"`, `:TestSuite`
- **Configuration**: Neovim test configuration

EOF
        ;;
      bash-tests)
        cat << 'EOF'
#### Bash Tests
- **Test Pattern**: `test_*.sh`
- **Test Runner**: `./run_all_tests.sh` or individual test scripts
- **Test Location**: `.claude/tests/` or `tests/`

EOF
        ;;
      cargo-test)
        cat << 'EOF'
#### Rust - Cargo Test
- **Test Pattern**: `#[test]` attributes, `tests/` directory
- **Test Commands**: `cargo test`, `cargo test --verbose`
- **Configuration**: `Cargo.toml`

EOF
        ;;
      go-test)
        cat << 'EOF'
#### Go - go test
- **Test Pattern**: `*_test.go`
- **Test Commands**: `go test`, `go test -v`, `go test -cover`
- **Configuration**: `go.mod`

EOF
        ;;
    esac
  done
else
  # No frameworks detected - provide generic guidance
  cat << 'EOF'
### Testing Setup
No testing frameworks detected. Consider setting up:

- **Python**: pytest, unittest
- **JavaScript/TypeScript**: jest, vitest, mocha
- **Lua**: plenary.nvim, busted
- **Rust**: cargo test
- **Go**: go test
- **Bash**: test scripts with assertions

Run `/setup --analyze` for detailed recommendations.

EOF
fi

# Common testing standards
cat << 'EOF'
### Coverage Requirements
- Aim for >80% coverage on new code
- All public APIs must have tests
- Critical paths require integration tests
- Regression tests for all bug fixes

### Test Organization
- Keep tests close to source code
- Use descriptive test names
- One assertion per test when possible
- Mock external dependencies
EOF
