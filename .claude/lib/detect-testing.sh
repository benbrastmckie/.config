#!/usr/bin/env bash
# Testing framework detection utility
# Analyzes repositories and generates score-based testing confidence ratings

set -euo pipefail

# Score-based testing detection (0-6 points)
# Returns: SCORE:N\nFRAMEWORKS:framework1 framework2
detect_testing_score() {
  local project_dir="${1:-.}"
  local score=0
  local frameworks=()

  # Validate directory
  if [[ ! -d "$project_dir" ]]; then
    echo "Error: Directory $project_dir does not exist" >&2
    return 1
  fi

  cd "$project_dir" || return 1

  # CI/CD configs (+2 points)
  if [[ -f .github/workflows/*.yml ]] || \
     [[ -f .gitlab-ci.yml ]] || \
     [[ -f .circleci/config.yml ]] || \
     [[ -f .travis.yml ]] || \
     [[ -f azure-pipelines.yml ]]; then
    ((score += 2))
  fi

  # Test directories (+1 point)
  if [[ -d tests ]] || [[ -d test ]] || [[ -d __tests__ ]] || [[ -d spec ]]; then
    ((score += 1))
  fi

  # Test file count (+1 point if >10 files)
  local test_files
  test_files=$(find . -type f \( -name '*test*' -o -name '*spec*' \) 2>/dev/null | wc -l || echo "0")
  if [[ $test_files -gt 10 ]]; then
    ((score += 1))
  fi

  # Coverage tools (+1 point)
  if [[ -f .coveragerc ]] || \
     [[ -f pytest.ini ]] || \
     [[ -f jest.config.js ]] || \
     [[ -f jest.config.ts ]] || \
     [[ -d .nyc_output ]] || \
     [[ -f coverage.xml ]] || \
     [[ -f .coverage ]]; then
    ((score += 1))
  fi

  # Test runners (+1 point)
  if [[ -f run_tests.sh ]] || \
     [[ -f run_tests.py ]] || \
     [[ -f run_all_tests.sh ]] || \
     grep -q "^test:" Makefile 2>/dev/null; then
    ((score += 1))
  fi

  # Framework detection
  # Python - pytest
  if [[ -f pytest.ini ]] || \
     [[ -f .pytest_cache ]] || \
     grep -q "pytest" requirements.txt 2>/dev/null || \
     grep -q "pytest" setup.py 2>/dev/null || \
     grep -q "pytest" pyproject.toml 2>/dev/null; then
    frameworks+=("pytest")
  fi

  # Python - unittest
  if find . -name "test_*.py" -type f 2>/dev/null | head -1 | xargs grep -l "unittest" 2>/dev/null >/dev/null; then
    frameworks+=("unittest")
  fi

  # JavaScript/TypeScript - jest
  if [[ -f jest.config.js ]] || \
     [[ -f jest.config.ts ]] || \
     grep -q '"jest"' package.json 2>/dev/null; then
    frameworks+=("jest")
  fi

  # JavaScript/TypeScript - vitest
  if [[ -f vitest.config.js ]] || \
     [[ -f vitest.config.ts ]] || \
     grep -q '"vitest"' package.json 2>/dev/null; then
    frameworks+=("vitest")
  fi

  # JavaScript/TypeScript - mocha
  if grep -q '"mocha"' package.json 2>/dev/null; then
    frameworks+=("mocha")
  fi

  # Lua/Neovim - plenary (only check in test directories to avoid false positives)
  if [[ -d tests ]] && find tests -maxdepth 3 -name "*_spec.lua" -type f 2>/dev/null | head -1 >/dev/null; then
    frameworks+=("plenary")
  elif [[ -d spec ]] && find spec -maxdepth 3 -name "*_spec.lua" -type f 2>/dev/null | head -1 >/dev/null; then
    frameworks+=("plenary")
  fi

  # Lua - busted
  if [[ -f .busted ]] || \
     grep -q "busted" .rockspec 2>/dev/null; then
    frameworks+=("busted")
  fi

  # Rust - cargo test
  if [[ -f Cargo.toml ]]; then
    frameworks+=("cargo-test")
  fi

  # Go - go test
  if [[ -f go.mod ]] && find . -name "*_test.go" -type f 2>/dev/null | head -1 >/dev/null; then
    frameworks+=("go-test")
  fi

  # Bash - test scripts
  if [[ -d .claude/tests ]] && find .claude/tests -name "test_*.sh" -type f 2>/dev/null | head -1 >/dev/null; then
    frameworks+=("bash-tests")
  elif [[ -d tests ]] && find tests -name "test_*.sh" -type f 2>/dev/null | head -1 >/dev/null; then
    frameworks+=("bash-tests")
  fi

  # Output format
  echo "SCORE:$score"
  if [[ ${#frameworks[@]} -gt 0 ]]; then
    echo "FRAMEWORKS:${frameworks[*]}"
  else
    echo "FRAMEWORKS:none"
  fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  detect_testing_score "${1:-.}"
fi
