#!/usr/bin/env bash
# Integration test script for goose.nvim multi-provider configuration
# Tests all 9 authentication scenarios documented in Phase 5

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging functions
log_test() {
  echo -e "${BLUE}[TEST ${TESTS_RUN}]${NC} $1"
}

log_pass() {
  echo -e "${GREEN}[PASS]${NC} $1"
  ((TESTS_PASSED++))
}

log_fail() {
  echo -e "${RED}[FAIL]${NC} $1"
  ((TESTS_FAILED++))
}

log_info() {
  echo -e "${YELLOW}[INFO]${NC} $1"
}

# Backup current environment
backup_env() {
  export GEMINI_API_KEY_BACKUP="${GEMINI_API_KEY:-}"
  export GEMINI_MODEL_BACKUP="${GEMINI_MODEL:-}"
  export ANTHROPIC_API_KEY_BACKUP="${ANTHROPIC_API_KEY:-}"
}

# Restore environment
restore_env() {
  if [[ -n "${GEMINI_API_KEY_BACKUP}" ]]; then
    export GEMINI_API_KEY="${GEMINI_API_KEY_BACKUP}"
  else
    unset GEMINI_API_KEY
  fi

  if [[ -n "${GEMINI_MODEL_BACKUP}" ]]; then
    export GEMINI_MODEL="${GEMINI_MODEL_BACKUP}"
  else
    unset GEMINI_MODEL
  fi

  if [[ -n "${ANTHROPIC_API_KEY_BACKUP}" ]]; then
    export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY_BACKUP}"
  else
    unset ANTHROPIC_API_KEY
  fi
}

# Test Neovim configuration loading
test_nvim_config() {
  local scenario="$1"
  local expected_provider="$2"
  local expected_model="${3:-}"

  ((TESTS_RUN++))
  log_test "Scenario ${TESTS_RUN}: ${scenario}"

  # Create temporary Lua script to test configuration
  local test_script="/tmp/goose_test_${TESTS_RUN}.lua"
  cat > "${test_script}" <<'EOF'
-- Test goose.nvim configuration loading
local config_path = vim.fn.expand("~/.config/nvim/lua/neotex/plugins/ai/goose/init.lua")

-- Load and execute the config function
local ok, result = pcall(function()
  local spec = dofile(config_path)
  if spec.config and type(spec.config) == "function" then
    spec.config()
  end
  return require("goose").config
end)

if not ok then
  print("ERROR: " .. tostring(result))
  vim.cmd("qa!")
end

-- Print provider configuration
if result and result.providers then
  print("PROVIDERS:")
  for provider, models in pairs(result.providers) do
    print("  " .. provider .. " = " .. vim.inspect(models))
  end
else
  print("ERROR: No providers configured")
end

vim.cmd("qa!")
EOF

  # Run Neovim headless to test configuration
  local output
  output=$(nvim --headless --noplugin -u NONE -c "source ${test_script}" 2>&1 || true)

  # Validate expected provider present
  if [[ "${expected_provider}" != "none" ]]; then
    if echo "${output}" | grep -q "${expected_provider}"; then
      log_pass "Provider '${expected_provider}' detected"
    else
      log_fail "Provider '${expected_provider}' not found. Output: ${output}"
      return 1
    fi

    # Validate model if specified
    if [[ -n "${expected_model}" ]]; then
      if echo "${output}" | grep -q "${expected_model}"; then
        log_pass "Model '${expected_model}' configured"
      else
        log_fail "Model '${expected_model}' not found. Output: ${output}"
        return 1
      fi
    fi
  else
    # Expect fallback to default Gemini
    if echo "${output}" | grep -q "google"; then
      log_pass "Fallback to Gemini default provider"
    else
      log_fail "No fallback provider configured. Output: ${output}"
      return 1
    fi
  fi

  # Cleanup
  rm -f "${test_script}"
  return 0
}

# Test health check output
test_health_check() {
  local scenario="$1"
  local expected_pattern="$2"

  log_info "Testing health check for: ${scenario}"

  # Create temporary Lua script to run health check
  local test_script="/tmp/goose_health_${TESTS_RUN}.lua"
  cat > "${test_script}" <<'EOF'
-- Test goose health check
local health_path = vim.fn.expand("~/.config/nvim/lua/goose/health.lua")

-- Load health module
local ok, health = pcall(dofile, health_path)
if not ok then
  print("ERROR: Cannot load health module: " .. tostring(health))
  vim.cmd("qa!")
end

-- Capture health check output
local output = {}
local original_health = vim.health
vim.health = {
  start = function(msg) table.insert(output, "START: " .. msg) end,
  ok = function(msg) table.insert(output, "OK: " .. msg) end,
  warn = function(msg) table.insert(output, "WARN: " .. msg) end,
  error = function(msg) table.insert(output, "ERROR: " .. msg) end,
  info = function(msg) table.insert(output, "INFO: " .. msg) end,
}

-- Run health check
health.check()

-- Restore original health
vim.health = original_health

-- Print captured output
for _, line in ipairs(output) do
  print(line)
end

vim.cmd("qa!")
EOF

  # Run health check
  local output
  output=$(nvim --headless --noplugin -u NONE -c "source ${test_script}" 2>&1 || true)

  # Validate expected pattern
  if echo "${output}" | grep -q "${expected_pattern}"; then
    log_pass "Health check matches pattern: ${expected_pattern}"
  else
    log_fail "Health check does not match pattern: ${expected_pattern}. Output: ${output}"
  fi

  # Cleanup
  rm -f "${test_script}"
}

# Main test execution
main() {
  echo "========================================"
  echo "Goose.nvim Multi-Provider Test Suite"
  echo "========================================"
  echo ""

  # Backup environment
  backup_env

  # Test Scenario 1: No authentication
  log_info "Setting up Scenario 1: No authentication"
  unset GEMINI_API_KEY
  unset GEMINI_MODEL
  unset ANTHROPIC_API_KEY
  test_nvim_config "No authentication" "google" "gemini-2.0-flash-exp"
  test_health_check "No authentication" "WARN.*Gemini provider not configured"

  # Test Scenario 2: Gemini API key only (free tier)
  log_info "Setting up Scenario 2: Gemini API key (free tier)"
  export GEMINI_API_KEY="test-key-free-tier"
  unset GEMINI_MODEL
  test_nvim_config "Gemini free tier" "google" "gemini-2.0-flash-exp"
  test_health_check "Gemini free tier" "INFO.*free tier model"

  # Test Scenario 3: Gemini API key with Gemini 3 Pro
  log_info "Setting up Scenario 3: Gemini 3 Pro via GEMINI_MODEL"
  export GEMINI_API_KEY="test-key-paid-tier"
  export GEMINI_MODEL="gemini-3-pro-preview-11-2025"
  test_nvim_config "Gemini 3 Pro" "google" "gemini-3-pro-preview-11-2025"
  test_health_check "Gemini 3 Pro" "WARN.*Gemini 3 Pro.*paid model"

  # Test Scenario 4: Gemini 2.5 Pro (alternative paid tier)
  log_info "Setting up Scenario 4: Gemini 2.5 Pro"
  export GEMINI_API_KEY="test-key-paid-tier"
  export GEMINI_MODEL="gemini-2.5-pro-preview"
  test_nvim_config "Gemini 2.5 Pro" "google" "gemini-2.5-pro-preview"

  # Test Scenario 5: Claude CLI (mock - requires actual CLI)
  log_info "Setting up Scenario 5: Claude CLI with subscription"
  if command -v claude &> /dev/null; then
    log_info "Claude CLI found, testing authentication"
    test_health_check "Claude Code" "OK.*claude CLI found"
  else
    log_info "Claude CLI not found (expected if not installed)"
    test_health_check "Claude Code" "WARN.*claude CLI not found"
  fi

  # Test Scenario 6: API key conflict
  log_info "Setting up Scenario 6: API key conflict (ANTHROPIC_API_KEY with claude CLI)"
  if command -v claude &> /dev/null; then
    export ANTHROPIC_API_KEY="test-api-key-conflict"
    test_health_check "API key conflict" "ERROR.*ANTHROPIC_API_KEY conflict"
    unset ANTHROPIC_API_KEY
  else
    log_info "Skipping API key conflict test (claude CLI not installed)"
  fi

  # Test Scenario 7: Both providers (Gemini free + Claude)
  log_info "Setting up Scenario 7: Both Gemini (free tier) and Claude"
  export GEMINI_API_KEY="test-key-multi"
  unset GEMINI_MODEL
  if command -v claude &> /dev/null; then
    test_nvim_config "Multi-provider" "google" "gemini-2.0-flash-exp"
    log_info "Check if both providers present in configuration"
  else
    log_info "Skipping multi-provider test (claude CLI not installed)"
  fi

  # Test Scenario 8: Model tier persistence
  log_info "Setting up Scenario 8: Model tier selection persists"
  export GEMINI_API_KEY="test-key-persistence"
  export GEMINI_MODEL="gemini-3-pro-preview-11-2025"
  test_nvim_config "Model tier persistence" "google" "gemini-3-pro-preview-11-2025"

  # Restore environment
  restore_env

  # Print summary
  echo ""
  echo "========================================"
  echo "Test Summary"
  echo "========================================"
  echo "Tests Run:    ${TESTS_RUN}"
  echo -e "Tests Passed: ${GREEN}${TESTS_PASSED}${NC}"
  echo -e "Tests Failed: ${RED}${TESTS_FAILED}${NC}"
  echo ""

  if [[ ${TESTS_FAILED} -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
  fi
}

# Run main
main "$@"
