#!/usr/bin/env bash
# Generate testing protocols based on confidence score and detected frameworks

set -euo pipefail

# Generate testing protocols markdown based on score and frameworks
# Args: $1 = score (0-6), $2 = frameworks (space-separated string)
generate_testing_protocols() {
  local score="${1:-0}"
  local frameworks="${2:-none}"

  # High confidence (≥4): Full protocols with framework-specific commands
  if [[ $score -ge 4 ]]; then
    generate_high_confidence_protocols "$frameworks"
  # Medium confidence (2-3): Brief protocols with expansion suggestions
  elif [[ $score -ge 2 ]]; then
    generate_medium_confidence_protocols "$frameworks"
  # Low confidence (0-1): Minimal placeholder or omit
  else
    generate_low_confidence_protocols "$frameworks"
  fi
}

# High confidence protocols (≥4 points)
generate_high_confidence_protocols() {
  local frameworks="$1"

  cat <<'EOF'
## Testing Protocols
[Used by: /test, /test-all, /implement]

### Test Discovery
Commands should check CLAUDE.md in priority order:
1. Project root CLAUDE.md for test commands
2. Subdirectory-specific CLAUDE.md files
3. Language-specific test patterns

EOF

  # Add framework-specific testing commands
  if echo "$frameworks" | grep -q "pytest"; then
    cat <<'EOF'
### Python Testing (pytest)
- **Test Location**: `tests/` or adjacent to source files
- **Test Runner**: `pytest` or `python -m pytest`
- **Test Pattern**: `test_*.py` or `*_test.py`
- **Coverage**: `pytest --cov=src --cov-report=html`
- **CI Integration**: Include pytest in requirements.txt and CI config

EOF
  fi

  if echo "$frameworks" | grep -q "jest\|vitest"; then
    cat <<'EOF'
### JavaScript/TypeScript Testing (Jest/Vitest)
- **Test Location**: `__tests__/` or adjacent to source files
- **Test Runner**: `npm test` or `yarn test`
- **Test Pattern**: `*.test.js`, `*.test.ts`, `*.spec.js`, `*.spec.ts`
- **Coverage**: `npm test -- --coverage`
- **Watch mode**: `npm test -- --watch`

EOF
  fi

  if echo "$frameworks" | grep -q "plenary"; then
    cat <<'EOF'
### Neovim/Lua Testing (plenary.nvim)
- **Test Location**: `tests/` or adjacent to source files
- **Test Runner**: `:PlenaryBustedDirectory tests/` or `nvim --headless -c "PlenaryBustedDirectory tests/"`
- **Test Pattern**: `*_spec.lua`
- **Coverage**: Use luacov for coverage tracking

EOF
  fi

  if echo "$frameworks" | grep -q "cargo-test"; then
    cat <<'EOF'
### Rust Testing (cargo test)
- **Test Location**: Inline tests or `tests/` directory
- **Test Runner**: `cargo test`
- **Test Pattern**: `#[test]` attribute or `tests/*.rs`
- **Coverage**: `cargo tarpaulin` or `cargo llvm-cov`

EOF
  fi

  if echo "$frameworks" | grep -q "go-test"; then
    cat <<'EOF'
### Go Testing (go test)
- **Test Location**: Adjacent to source files
- **Test Runner**: `go test ./...`
- **Test Pattern**: `*_test.go`
- **Coverage**: `go test -cover ./...` or `go test -coverprofile=coverage.out`

EOF
  fi

  if echo "$frameworks" | grep -q "bash-tests"; then
    cat <<'EOF'
### Bash Testing
- **Test Location**: `.claude/tests/` or `tests/`
- **Test Runner**: `./run_all_tests.sh` or individual test scripts
- **Test Pattern**: `test_*.sh`
- **Coverage**: Manual coverage tracking

EOF
  fi

  # Add general testing requirements
  cat <<'EOF'
### Coverage Requirements
- Aim for >80% coverage on new code
- All public APIs must have tests
- Critical paths require integration tests
- Regression tests for all bug fixes

### Test-Driven Development
This project has comprehensive testing infrastructure. Follow TDD practices:
1. Write tests before implementation
2. Run tests frequently during development
3. Ensure all tests pass before committing
4. Add tests for bug fixes to prevent regressions
EOF
}

# Medium confidence protocols (2-3 points)
generate_medium_confidence_protocols() {
  local frameworks="$1"

  cat <<EOF
## Testing Protocols
[Used by: /test, /test-all, /implement]

### Test Discovery
This project has some testing infrastructure. Tests are detected in:
- Test directories: tests/, test/, __tests__/, spec/
- Test patterns: *test*, *spec*
- Detected frameworks: ${frameworks:-none}

### Running Tests
Check for test commands in:
1. Project documentation or README
2. Makefile (look for 'make test')
3. package.json (look for 'npm test')
4. Test runner scripts (run_tests.sh, etc.)

### Coverage Requirements
- Aim for >60% coverage on new code
- Add tests for critical functionality
- Consider expanding test infrastructure

### Recommendations
Consider enhancing testing infrastructure:
- Add CI/CD integration for automated testing
- Set up coverage reporting
- Document test commands in CLAUDE.md
EOF
}

# Low confidence protocols (0-1 points)
generate_low_confidence_protocols() {
  local frameworks="$1"

  if [[ "$frameworks" == "none" ]]; then
    cat <<'EOF'
## Testing Protocols
[Used by: /test, /test-all, /implement]

### Test Discovery
No comprehensive testing infrastructure detected. Testing protocols will be determined on a per-feature basis.

### Recommendations
Consider adding testing infrastructure:
1. Choose appropriate testing framework for your language
2. Set up test directory structure (tests/ or __tests__/)
3. Add coverage tools
4. Integrate with CI/CD for automated testing
5. Update this section once testing is configured
EOF
  else
    cat <<EOF
## Testing Protocols
[Used by: /test, /test-all, /implement]

### Test Discovery
Limited testing infrastructure detected. Detected frameworks: ${frameworks}

### Running Tests
Refer to project documentation for test execution commands.

### Recommendations
Consider expanding testing infrastructure:
- Add more comprehensive test coverage
- Set up CI/CD integration
- Document test commands clearly
EOF
  fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  generate_testing_protocols "$@"
fi
