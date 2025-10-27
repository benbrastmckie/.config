#!/usr/bin/env bash
# Monitor Claude model usage and costs for .claude/ agents
# Tracks invocation counts, costs, and quality metrics

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Data directories
DATA_DIR="$PROJECT_DIR/data"
LOG_DIR="$DATA_DIR/logs"
AGENTS_DIR="$PROJECT_DIR/agents"

# Pricing (per 1K tokens)
HAIKU_COST=0.003
SONNET_COST=0.015
OPUS_COST=0.075

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Usage
usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Monitor Claude model usage and costs for .claude/ agents

OPTIONS:
  --summary              Show current model distribution summary
  --agent <name>         Show metrics for specific agent
  --period <days>        Filter by time period (e.g., 7d, 30d)
  --cost-report          Generate cost comparison report
  --output <file>        Output file for reports (default: stdout)
  --test                 Run test mode (validate script functionality)
  --help                 Show this help message

EXAMPLES:
  # Show current model distribution
  $0 --summary

  # Track specific agent over 7 days
  $0 --agent spec-updater --period 7d

  # Generate cost report
  $0 --cost-report --output cost-report.md

  # Test mode
  $0 --test

EOF
  exit 0
}

# Logging functions
info() {
  echo -e "${BLUE}ℹ INFO${NC}: $1"
}

success() {
  echo -e "${GREEN}✓ SUCCESS${NC}: $1"
}

warning() {
  echo -e "${YELLOW}⚠ WARNING${NC}: $1"
}

error() {
  echo -e "${RED}✗ ERROR${NC}: $1" >&2
}

# Parse command-line arguments
MODE="summary"
AGENT_NAME=""
PERIOD_DAYS=0
OUTPUT_FILE=""
REPORT_TYPE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --summary)
      MODE="summary"
      shift
      ;;
    --agent)
      AGENT_NAME="$2"
      MODE="agent"
      shift 2
      ;;
    --period)
      PERIOD_DAYS="${2%d}"  # Remove 'd' suffix if present
      shift 2
      ;;
    --cost-report)
      MODE="cost-report"
      shift
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --test)
      MODE="test"
      shift
      ;;
    --help)
      usage
      ;;
    *)
      error "Unknown option: $1"
      usage
      ;;
  esac
done

# Ensure data directory exists
mkdir -p "$DATA_DIR" "$LOG_DIR"

# ============================================================================
# Core Functions
# ============================================================================

# Get all agent files
get_agent_files() {
  find "$AGENTS_DIR" -name "*.md" -type f 2>/dev/null | sort
}

# Extract model from agent file
get_agent_model() {
  local agent_file="$1"
  grep -E "^model:" "$agent_file" 2>/dev/null | head -1 | sed 's/^model: *//' || echo "unknown"
}

# Extract model justification
get_agent_justification() {
  local agent_file="$1"
  grep -E "^model-justification:" "$agent_file" 2>/dev/null | head -1 | sed 's/^model-justification: *//' || echo "No justification"
}

# Get agent name from file path
get_agent_name() {
  local agent_file="$1"
  basename "$agent_file" .md
}

# Count agents by model tier
count_by_model() {
  local model="$1"
  local count=0

  while IFS= read -r agent_file; do
    local agent_model=$(get_agent_model "$agent_file")
    if [[ "$agent_model" == "$model" ]]; then
      ((count++))
    fi
  done < <(get_agent_files)

  echo "$count"
}

# List agents by model tier
list_agents_by_model() {
  local model="$1"

  while IFS= read -r agent_file; do
    local agent_model=$(get_agent_model "$agent_file")
    if [[ "$agent_model" == "$model" ]]; then
      get_agent_name "$agent_file"
    fi
  done < <(get_agent_files)
}

# Calculate estimated cost for agent
calculate_agent_cost() {
  local model="$1"
  local invocations="${2:-1}"
  local tokens="${3:-1000}"  # Default 1K tokens per invocation

  local cost_per_1k=0
  case "$model" in
    haiku*)
      cost_per_1k=$HAIKU_COST
      ;;
    sonnet*)
      cost_per_1k=$SONNET_COST
      ;;
    opus*)
      cost_per_1k=$OPUS_COST
      ;;
    *)
      cost_per_1k=0
      ;;
  esac

  # Cost = (invocations × tokens / 1000) × cost_per_1k
  local total_cost=$(awk "BEGIN {printf \"%.4f\", ($invocations * $tokens / 1000.0) * $cost_per_1k}")
  echo "$total_cost"
}

# ============================================================================
# Summary Mode
# ============================================================================

show_summary() {
  info "Analyzing current model distribution..."
  echo ""

  # Count agents by model
  local haiku_count=$(count_by_model "haiku-4.5")
  local sonnet_count=$(count_by_model "sonnet-4.5")
  local opus_count=$(count_by_model "opus-4.1")
  local total_count=$(get_agent_files | wc -l)

  # Calculate percentages
  local haiku_pct=$(awk "BEGIN {printf \"%.0f\", ($haiku_count / $total_count) * 100}")
  local sonnet_pct=$(awk "BEGIN {printf \"%.0f\", ($sonnet_count / $total_count) * 100}")
  local opus_pct=$(awk "BEGIN {printf \"%.0f\", ($opus_count / $total_count) * 100}")

  echo "════════════════════════════════════════════════"
  echo "Model Distribution Summary"
  echo "════════════════════════════════════════════════"
  echo ""
  echo -e "${CYAN}Total Agents${NC}: $total_count"
  echo ""
  echo -e "${GREEN}Haiku 4.5${NC}: $haiku_count agents (${haiku_pct}%) - \$${HAIKU_COST}/1K tokens"
  echo -e "${BLUE}Sonnet 4.5${NC}: $sonnet_count agents (${sonnet_pct}%) - \$${SONNET_COST}/1K tokens"
  echo -e "${YELLOW}Opus 4.1${NC}: $opus_count agents (${opus_pct}%) - \$${OPUS_COST}/1K tokens"
  echo ""

  # List agents by tier
  echo "────────────────────────────────────────────────"
  echo -e "${GREEN}Haiku Agents${NC}:"
  if [ "$haiku_count" -gt 0 ]; then
    list_agents_by_model "haiku-4.5" | while read -r agent; do
      echo "  • $agent"
    done
  else
    echo "  (none)"
  fi
  echo ""

  echo "────────────────────────────────────────────────"
  echo -e "${BLUE}Sonnet Agents${NC}:"
  if [ "$sonnet_count" -gt 0 ]; then
    list_agents_by_model "sonnet-4.5" | while read -r agent; do
      echo "  • $agent"
    done
  else
    echo "  (none)"
  fi
  echo ""

  echo "────────────────────────────────────────────────"
  echo -e "${YELLOW}Opus Agents${NC}:"
  if [ "$opus_count" -gt 0 ]; then
    list_agents_by_model "opus-4.1" | while read -r agent; do
      echo "  • $agent"
    done
  else
    echo "  (none)"
  fi
  echo ""

  # Optimization notes
  echo "════════════════════════════════════════════════"
  echo "Optimization Status"
  echo "════════════════════════════════════════════════"
  echo ""

  if [ -f "$DATA_DIR/model_optimization_baseline.json" ]; then
    success "Baseline metrics available"
  else
    warning "No baseline metrics found (run test suite with --baseline)"
  fi

  if [ -f "$DATA_DIR/cost_comparison_report.md" ]; then
    success "Cost comparison report available"
  else
    warning "No cost comparison report found"
  fi

  echo ""
  info "For detailed agent information, use: $0 --agent <name>"
  info "For cost analysis, use: $0 --cost-report"
}

# ============================================================================
# Agent Mode
# ============================================================================

show_agent_info() {
  local agent_name="$AGENT_NAME"
  local agent_file="$AGENTS_DIR/${agent_name}.md"

  if [ ! -f "$agent_file" ]; then
    error "Agent file not found: $agent_file"
    exit 1
  fi

  info "Analyzing agent: $agent_name"
  echo ""

  local model=$(get_agent_model "$agent_file")
  local justification=$(get_agent_justification "$agent_file")

  echo "════════════════════════════════════════════════"
  echo "Agent: $agent_name"
  echo "════════════════════════════════════════════════"
  echo ""
  echo -e "${CYAN}Model${NC}: $model"
  echo -e "${CYAN}Justification${NC}: $justification"
  echo ""

  # Cost estimation
  local cost_1_inv=$(calculate_agent_cost "$model" 1 1000)
  local cost_10_inv=$(calculate_agent_cost "$model" 10 1000)
  local cost_100_inv=$(calculate_agent_cost "$model" 100 1000)

  echo "────────────────────────────────────────────────"
  echo "Cost Estimation (@ 1K tokens per invocation)"
  echo "────────────────────────────────────────────────"
  echo "  1 invocation:   \$$cost_1_inv"
  echo "  10 invocations:  \$$cost_10_inv"
  echo "  100 invocations: \$$cost_100_inv"
  echo ""

  # Model alternatives
  echo "────────────────────────────────────────────────"
  echo "Model Alternatives"
  echo "────────────────────────────────────────────────"

  if [[ "$model" != "haiku-4.5" ]]; then
    local haiku_cost=$(calculate_agent_cost "haiku-4.5" 10 1000)
    local savings=$(awk "BEGIN {printf \"%.2f\", $cost_10_inv - $haiku_cost}")
    local savings_pct=$(awk "BEGIN {printf \"%.0f\", (($cost_10_inv - $haiku_cost) / $cost_10_inv) * 100}")
    echo "  Haiku 4.5:  \$$haiku_cost (10 inv) - saves \$$savings (${savings_pct}%)"
  fi

  if [[ "$model" != "sonnet-4.5" ]]; then
    local sonnet_cost=$(calculate_agent_cost "sonnet-4.5" 10 1000)
    if [[ "$model" == "haiku-4.5" ]]; then
      local increase=$(awk "BEGIN {printf \"%.2f\", $sonnet_cost - $cost_10_inv}")
      echo "  Sonnet 4.5: \$$sonnet_cost (10 inv) - costs \$$increase more"
    else
      local savings=$(awk "BEGIN {printf \"%.2f\", $cost_10_inv - $sonnet_cost}")
      local savings_pct=$(awk "BEGIN {printf \"%.0f\", (($cost_10_inv - $sonnet_cost) / $cost_10_inv) * 100}")
      echo "  Sonnet 4.5: \$$sonnet_cost (10 inv) - saves \$$savings (${savings_pct}%)"
    fi
  fi

  if [[ "$model" != "opus-4.1" ]]; then
    local opus_cost=$(calculate_agent_cost "opus-4.1" 10 1000)
    local increase=$(awk "BEGIN {printf \"%.2f\", $opus_cost - $cost_10_inv}")
    local increase_pct=$(awk "BEGIN {printf \"%.0f\", (($opus_cost - $cost_10_inv) / $cost_10_inv) * 100}")
    echo "  Opus 4.1:   \$$opus_cost (10 inv) - costs \$$increase more (+${increase_pct}%)"
  fi

  echo ""
  info "For model selection guidance, see: .claude/docs/guides/model-selection-guide.md"
}

# ============================================================================
# Cost Report Mode
# ============================================================================

generate_cost_report() {
  local output="${OUTPUT_FILE:-/dev/stdout}"

  info "Generating cost report..."

  {
    echo "# Model Usage Cost Report"
    echo ""
    echo "**Generated**: $(date +'%Y-%m-%d %H:%M:%S')"
    echo ""

    # Summary
    local haiku_count=$(count_by_model "haiku-4.5")
    local sonnet_count=$(count_by_model "sonnet-4.5")
    local opus_count=$(count_by_model "opus-4.1")
    local total_count=$(get_agent_files | wc -l)

    echo "## Summary"
    echo ""
    echo "| Model | Count | Percentage | Cost per 1K |"
    echo "|-------|-------|------------|-------------|"
    echo "| Haiku 4.5 | $haiku_count | $(awk "BEGIN {printf \"%.0f\", ($haiku_count / $total_count) * 100}")% | \$${HAIKU_COST} |"
    echo "| Sonnet 4.5 | $sonnet_count | $(awk "BEGIN {printf \"%.0f\", ($sonnet_count / $total_count) * 100}")% | \$${SONNET_COST} |"
    echo "| Opus 4.1 | $opus_count | $(awk "BEGIN {printf \"%.0f\", ($opus_count / $total_count) * 100}")% | \$${OPUS_COST} |"
    echo "| **Total** | **$total_count** | **100%** | - |"
    echo ""

    # Detailed breakdown
    echo "## Agents by Model Tier"
    echo ""

    echo "### Haiku 4.5 ($haiku_count agents)"
    echo ""
    if [ "$haiku_count" -gt 0 ]; then
      echo "| Agent | Justification |"
      echo "|-------|---------------|"
      while IFS= read -r agent_file; do
        local model=$(get_agent_model "$agent_file")
        if [[ "$model" == "haiku-4.5" ]]; then
          local name=$(get_agent_name "$agent_file")
          local just=$(get_agent_justification "$agent_file")
          echo "| $name | $just |"
        fi
      done < <(get_agent_files)
    else
      echo "(none)"
    fi
    echo ""

    echo "### Sonnet 4.5 ($sonnet_count agents)"
    echo ""
    if [ "$sonnet_count" -gt 0 ]; then
      echo "| Agent | Justification |"
      echo "|-------|---------------|"
      while IFS= read -r agent_file; do
        local model=$(get_agent_model "$agent_file")
        if [[ "$model" == "sonnet-4.5" ]]; then
          local name=$(get_agent_name "$agent_file")
          local just=$(get_agent_justification "$agent_file")
          echo "| $name | $just |"
        fi
      done < <(get_agent_files)
    else
      echo "(none)"
    fi
    echo ""

    echo "### Opus 4.1 ($opus_count agents)"
    echo ""
    if [ "$opus_count" -gt 0 ]; then
      echo "| Agent | Justification |"
      echo "|-------|---------------|"
      while IFS= read -r agent_file; do
        local model=$(get_agent_model "$agent_file")
        if [[ "$model" == "opus-4.1" ]]; then
          local name=$(get_agent_name "$agent_file")
          local just=$(get_agent_justification "$agent_file")
          echo "| $name | $just |"
        fi
      done < <(get_agent_files)
    else
      echo "(none)"
    fi
    echo ""

    # Cost projection
    echo "## Cost Projection (Estimated)"
    echo ""
    echo "Assuming 1K tokens per invocation:"
    echo ""
    echo "| Model | 10 inv/week | 50 inv/week | 100 inv/week |"
    echo "|-------|-------------|-------------|--------------|"
    echo "| Haiku 4.5 | \$$(calculate_agent_cost "haiku-4.5" 10 1000) | \$$(calculate_agent_cost "haiku-4.5" 50 1000) | \$$(calculate_agent_cost "haiku-4.5" 100 1000) |"
    echo "| Sonnet 4.5 | \$$(calculate_agent_cost "sonnet-4.5" 10 1000) | \$$(calculate_agent_cost "sonnet-4.5" 50 1000) | \$$(calculate_agent_cost "sonnet-4.5" 100 1000) |"
    echo "| Opus 4.1 | \$$(calculate_agent_cost "opus-4.1" 10 1000) | \$$(calculate_agent_cost "opus-4.1" 50 1000) | \$$(calculate_agent_cost "opus-4.1" 100 1000) |"
    echo ""

    echo "## Optimization Opportunities"
    echo ""
    echo "For model optimization guidance, see:"
    echo "- [Model Selection Guide](.claude/docs/guides/model-selection-guide.md)"
    echo "- [Model Optimization Analysis](.claude/specs/484_research_which_commands_or_agents_in_claude_could_/reports/001_model_optimization_analysis.md)"
    echo ""
  } > "$output"

  if [ "$output" != "/dev/stdout" ]; then
    success "Cost report generated: $output"
  fi
}

# ============================================================================
# Test Mode
# ============================================================================

run_tests() {
  info "Running monitoring script tests..."
  echo ""

  local pass_count=0
  local fail_count=0

  # Test 1: Check agents directory exists
  if [ -d "$AGENTS_DIR" ]; then
    success "Test 1: Agents directory exists"
    ((pass_count++))
  else
    error "Test 1: Agents directory not found"
    ((fail_count++))
  fi

  # Test 2: Check agent files are readable
  local agent_count=$(get_agent_files | wc -l)
  if [ "$agent_count" -gt 0 ]; then
    success "Test 2: Found $agent_count agent files"
    ((pass_count++))
  else
    error "Test 2: No agent files found"
    ((fail_count++))
  fi

  # Test 3: Check model extraction
  local first_agent=$(get_agent_files | head -1)
  if [ -n "$first_agent" ]; then
    local model=$(get_agent_model "$first_agent")
    if [[ "$model" =~ (haiku|sonnet|opus) ]]; then
      success "Test 3: Model extraction works (got: $model)"
      ((pass_count++))
    else
      error "Test 3: Model extraction failed (got: $model)"
      ((fail_count++))
    fi
  else
    warning "Test 3: Skipped (no agents to test)"
  fi

  # Test 4: Check cost calculation
  local test_cost=$(calculate_agent_cost "haiku-4.5" 10 1000)
  local expected_cost="0.0300"
  if [ "$test_cost" == "$expected_cost" ]; then
    success "Test 4: Cost calculation correct ($test_cost)"
    ((pass_count++))
  else
    error "Test 4: Cost calculation incorrect (got $test_cost, expected $expected_cost)"
    ((fail_count++))
  fi

  # Test 5: Check data directory
  if [ -d "$DATA_DIR" ]; then
    success "Test 5: Data directory exists"
    ((pass_count++))
  else
    error "Test 5: Data directory not found"
    ((fail_count++))
  fi

  # Summary
  echo ""
  echo "════════════════════════════════════════════════"
  echo "Test Results"
  echo "════════════════════════════════════════════════"
  echo -e "${GREEN}Passed${NC}: $pass_count"
  echo -e "${RED}Failed${NC}: $fail_count"
  echo ""

  if [ $fail_count -eq 0 ]; then
    success "All tests passed ✓"
    return 0
  else
    error "Some tests failed"
    return 1
  fi
}

# ============================================================================
# Main Execution
# ============================================================================

case "$MODE" in
  summary)
    show_summary
    ;;
  agent)
    show_agent_info
    ;;
  cost-report)
    generate_cost_report
    ;;
  test)
    run_tests
    ;;
  *)
    error "Unknown mode: $MODE"
    usage
    ;;
esac
