#!/usr/bin/env bash
# Test suite for agent discovery and validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the utilities to test
source "$PROJECT_ROOT/lib/agent-discovery.sh"
source "$PROJECT_ROOT/lib/agent-schema-validator.sh"
source "$PROJECT_ROOT/lib/agent-registry-utils.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
pass() {
  echo "  ✓ $1"
  ((TESTS_PASSED++))
  ((TESTS_RUN++))
}

fail() {
  echo "  ✗ $1"
  ((TESTS_FAILED++))
  ((TESTS_RUN++))
}

test_header() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test: $1"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Test 1: Agent Discovery
test_discover_agents() {
  test_header "Agent Discovery"

  local count
  count=$(discover_agents "$PROJECT_ROOT/agents" | wc -l)

  if [[ $count -ge 15 ]]; then
    pass "Discovered $count agents (expected ≥15)"
  else
    fail "Only discovered $count agents (expected ≥15)"
  fi
}

# Test 2: Metadata Extraction
test_extract_metadata() {
  test_header "Metadata Extraction"

  # Test with frontmatter agent
  local metadata
  if metadata=$(extract_agent_metadata "$PROJECT_ROOT/agents/research-specialist.md" 2>&1); then
    if echo "$metadata" | jq -e '.type' >/dev/null 2>&1; then
      pass "Extracted metadata from frontmatter agent"
    else
      fail "Invalid JSON from frontmatter agent"
    fi
  else
    fail "Failed to extract metadata from frontmatter agent"
  fi

  # Test metadata fields
  local has_type has_category has_tools has_metrics
  has_type=$(echo "$metadata" | jq -e '.type' >/dev/null 2>&1 && echo "yes" || echo "no")
  has_category=$(echo "$metadata" | jq -e '.category' >/dev/null 2>&1 && echo "yes" || echo "no")
  has_tools=$(echo "$metadata" | jq -e '.tools' >/dev/null 2>&1 && echo "yes" || echo "no")
  has_metrics=$(echo "$metadata" | jq -e '.metrics' >/dev/null 2>&1 && echo "yes" || echo "no")

  if [[ "$has_type" == "yes" && "$has_category" == "yes" && "$has_tools" == "yes" && "$has_metrics" == "yes" ]]; then
    pass "All required metadata fields present"
  else
    fail "Missing metadata fields (type:$has_type, category:$has_category, tools:$has_tools, metrics:$has_metrics)"
  fi
}

# Test 3: Schema Validation
test_schema_validation() {
  test_header "Schema Validation"

  if validate_agent_registry "$PROJECT_ROOT/agents/agent-registry.json" >/dev/null 2>&1; then
    pass "Registry passes schema validation"
  else
    fail "Registry fails schema validation"
  fi

  # Test individual agent validation
  local agent_count
  agent_count=$(jq '.agents | length' "$PROJECT_ROOT/agents/agent-registry.json")

  if [[ $agent_count -ge 15 ]]; then
    pass "Registry contains $agent_count agents (expected ≥15)"
  else
    fail "Registry contains only $agent_count agents (expected ≥15)"
  fi
}

# Test 4: Registry Query Functions
test_registry_queries() {
  test_header "Registry Query Functions"

  # Test get_agents_by_type
  local specialized_count
  specialized_count=$(get_agents_by_type "specialized" | wc -l)

  if [[ $specialized_count -ge 10 ]]; then
    pass "Found $specialized_count specialized agents (expected ≥10)"
  else
    fail "Found only $specialized_count specialized agents (expected ≥10)"
  fi

  # Test get_agents_by_category
  local research_count
  research_count=$(get_agents_by_category "research" | wc -l)

  if [[ $research_count -ge 1 ]]; then
    pass "Found $research_count research agents (expected ≥1)"
  else
    fail "Found no research agents (expected ≥1)"
  fi

  # Test get_agents_by_tool
  local read_tool_count
  read_tool_count=$(get_agents_by_tool "Read" | wc -l)

  if [[ $read_tool_count -ge 5 ]]; then
    pass "Found $read_tool_count agents using Read tool (expected ≥5)"
  else
    fail "Found only $read_tool_count agents using Read tool (expected ≥5)"
  fi
}

# Test 5: Agent Entry Validation
test_agent_entry_validation() {
  test_header "Individual Agent Entry Validation"

  local test_agent
  test_agent=$(jq -r '.agents | keys[0]' "$PROJECT_ROOT/agents/agent-registry.json")

  if validate_agent_entry "$test_agent" "$PROJECT_ROOT/agents/agent-registry.json" >/dev/null 2>&1; then
    pass "Agent entry '$test_agent' validates correctly"
  else
    fail "Agent entry '$test_agent' fails validation"
  fi
}

# Test 6: Metrics Update (v2 schema)
test_metrics_update() {
  test_header "Metrics Update (v2 schema)"

  # Create a backup of registry
  local backup_file
  backup_file=$(mktemp)
  cp "$PROJECT_ROOT/agents/agent-registry.json" "$backup_file"

  # Get first agent
  local test_agent
  test_agent=$(jq -r '.agents | keys[0]' "$PROJECT_ROOT/agents/agent-registry.json")

  # Get initial invocations
  local initial_invocations
  initial_invocations=$(jq -r ".agents[\"$test_agent\"].metrics.total_invocations" "$PROJECT_ROOT/agents/agent-registry.json")

  # Update metrics
  if update_agent_metrics_v2 "$test_agent" "true" 1.5 >/dev/null 2>&1; then
    local new_invocations
    new_invocations=$(jq -r ".agents[\"$test_agent\"].metrics.total_invocations" "$PROJECT_ROOT/agents/agent-registry.json")

    if [[ $new_invocations -gt $initial_invocations ]]; then
      pass "Metrics update successful (invocations: $initial_invocations → $new_invocations)"
    else
      fail "Metrics not updated (invocations still $initial_invocations)"
    fi
  else
    fail "Failed to update metrics"
  fi

  # Restore backup
  mv "$backup_file" "$PROJECT_ROOT/agents/agent-registry.json"
}

# Test 7: Frontmatter Validation
test_frontmatter_validation() {
  test_header "Frontmatter Validation"

  # Test with an agent that has frontmatter
  if validate_agent_frontmatter "$PROJECT_ROOT/agents/research-specialist.md" >/dev/null 2>&1; then
    pass "Frontmatter validation passes for valid agent"
  else
    fail "Frontmatter validation fails for valid agent"
  fi
}

# Test 8: Agent Stats Retrieval
test_agent_stats() {
  test_header "Agent Stats Retrieval"

  local test_agent
  test_agent=$(jq -r '.agents | keys[0]' "$PROJECT_ROOT/agents/agent-registry.json")

  local stats
  if stats=$(get_agent_stats "$test_agent" 2>&1); then
    if echo "$stats" | grep -q "Agent: $test_agent"; then
      pass "Successfully retrieved stats for $test_agent"
    else
      fail "Stats output malformed for $test_agent"
    fi
  else
    fail "Failed to retrieve stats for $test_agent"
  fi
}

# Test 9: List All Agents
test_list_agents() {
  test_header "List All Agents"

  local agent_list
  if agent_list=$(list_agents 2>&1); then
    local count
    count=$(echo "$agent_list" | wc -l)
    if [[ $count -ge 15 ]]; then
      pass "Listed $count agents (expected ≥15)"
    else
      fail "Listed only $count agents (expected ≥15)"
    fi
  else
    fail "Failed to list agents"
  fi
}

# Test 10: Registry Schema Version
test_registry_schema_version() {
  test_header "Registry Schema Version"

  local schema_version
  schema_version=$(jq -r '.schema_version' "$PROJECT_ROOT/agents/agent-registry.json")

  if [[ "$schema_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    pass "Schema version is valid semver: $schema_version"
  else
    fail "Schema version is invalid: $schema_version"
  fi
}

# Run all tests
main() {
  echo "╔════════════════════════════════════════╗"
  echo "║  Agent Discovery Test Suite            ║"
  echo "╚════════════════════════════════════════╝"
  echo ""
  echo "Testing agent discovery and validation functionality..."

  test_discover_agents
  test_extract_metadata
  test_schema_validation
  test_registry_queries
  test_agent_entry_validation
  test_metrics_update
  test_frontmatter_validation
  test_agent_stats
  test_list_agents
  test_registry_schema_version

  echo ""
  echo "╔════════════════════════════════════════╗"
  echo "║  Test Results                          ║"
  echo "╚════════════════════════════════════════╝"
  echo ""
  echo "  Tests Run:    $TESTS_RUN"
  echo "  Tests Passed: $TESTS_PASSED"
  echo "  Tests Failed: $TESTS_FAILED"
  echo ""

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "✓ All tests passed!"
    return 0
  else
    echo "✗ Some tests failed"
    return 1
  fi
}

main "$@"
