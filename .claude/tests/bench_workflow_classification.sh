#!/usr/bin/env bash
# Performance Benchmark for Workflow Classification
#
# Measures latency (p50/p95/p99), fallback rate, and API cost

set -euo pipefail

# Source the libraries we need to benchmark
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source workflow scope detection library
source "${PROJECT_ROOT}/.claude/lib/workflow-scope-detection.sh"

# Benchmark configuration
NUM_ITERATIONS=100
declare -a LATENCIES=()
declare -a METHODS=()

# Test descriptions (representative sample)
TEST_DESCRIPTIONS=(
  "research authentication patterns and create implementation plan"
  "implement the authentication system"
  "revise the plan based on new requirements"
  "debug the login failure"
  "research the codebase structure"
  "analyze security implications and plan improvements"
  "build the user management system"
  "investigate the performance bottleneck"
  "review the API documentation"
  "create a comprehensive testing strategy"
)

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to measure classification latency
measure_latency() {
  local description="$1"
  local mode="$2"

  export WORKFLOW_CLASSIFICATION_MODE="$mode"
  export WORKFLOW_CLASSIFICATION_DEBUG=0

  local start_ms=$(date +%s%3N)
  local result
  result=$(detect_workflow_scope "$description" 2>&1)
  local end_ms=$(date +%s%3N)

  local latency_ms=$((end_ms - start_ms))

  # Detect if fallback was used
  local method="$mode"
  if echo "$result" | grep -q "fallback"; then
    method="${mode}-fallback"
  fi

  echo "$latency_ms|$method"
}

# Function to calculate percentile
calculate_percentile() {
  local -n arr=$1
  local percentile=$2

  # Sort array
  local sorted=($(printf '%s\n' "${arr[@]}" | sort -n))

  # Calculate index
  local len=${#sorted[@]}
  local index=$(echo "scale=0; ($percentile * $len) / 100" | bc)

  # Return value at index
  echo "${sorted[$index]}"
}

# Function to calculate statistics
calculate_stats() {
  local -n latencies=$1

  # Calculate min, max, avg
  local sum=0
  local min=999999
  local max=0

  for lat in "${latencies[@]}"; do
    sum=$((sum + lat))
    if [ $lat -lt $min ]; then
      min=$lat
    fi
    if [ $lat -gt $max ]; then
      max=$lat
    fi
  done

  local avg=$((sum / ${#latencies[@]}))

  # Calculate percentiles
  local p50=$(calculate_percentile latencies 50)
  local p95=$(calculate_percentile latencies 95)
  local p99=$(calculate_percentile latencies 99)

  echo "$min|$max|$avg|$p50|$p95|$p99"
}

# Function to calculate fallback rate
calculate_fallback_rate() {
  local -n methods=$1

  local total=${#methods[@]}
  local fallbacks=0

  for method in "${methods[@]}"; do
    if echo "$method" | grep -q "fallback"; then
      fallbacks=$((fallbacks + 1))
    fi
  done

  if [ $total -gt 0 ]; then
    echo "$((fallbacks * 100 / total))"
  else
    echo "0"
  fi
}

# Main benchmark execution
main() {
  echo "==========================================="
  echo "Workflow Classification Performance Benchmark"
  echo "==========================================="
  echo ""

  # Check which mode to benchmark
  local mode="${1:-hybrid}"
  echo -e "${CYAN}Benchmarking mode: $mode${NC}"
  echo "Number of iterations: $NUM_ITERATIONS"
  echo "Test descriptions: ${#TEST_DESCRIPTIONS[@]}"
  echo ""

  # Warmup
  echo -n "Warming up... "
  for desc in "${TEST_DESCRIPTIONS[@]}"; do
    measure_latency "$desc" "$mode" > /dev/null
  done
  echo "Done"
  echo ""

  # Run benchmark
  echo "Running benchmark..."
  local iteration=1
  while [ $iteration -le $NUM_ITERATIONS ]; do
    # Rotate through test descriptions
    local desc_index=$(((iteration - 1) % ${#TEST_DESCRIPTIONS[@]}))
    local description="${TEST_DESCRIPTIONS[$desc_index]}"

    # Measure latency
    local result
    result=$(measure_latency "$description" "$mode")
    IFS='|' read -r latency method <<< "$result"

    LATENCIES+=("$latency")
    METHODS+=("$method")

    # Progress indicator
    if [ $((iteration % 10)) -eq 0 ]; then
      echo -n "."
    fi

    iteration=$((iteration + 1))
  done
  echo ""
  echo ""

  # Calculate statistics
  echo "==========================================="
  echo "Results"
  echo "==========================================="

  IFS='|' read -r min max avg p50 p95 p99 <<< "$(calculate_stats LATENCIES)"

  echo "Latency Statistics (milliseconds):"
  echo "  Min:    ${min}ms"
  echo "  Max:    ${max}ms"
  echo "  Avg:    ${avg}ms"
  echo "  p50:    ${p50}ms"
  echo "  p95:    ${p95}ms"
  echo "  p99:    ${p99}ms"
  echo ""

  # Evaluate against targets
  local status="PASS"
  if [ $p50 -gt 300 ]; then
    echo -e "${YELLOW}⚠ p50 > 300ms target${NC}"
    status="WARN"
  else
    echo -e "${GREEN}✓ p50 < 300ms target${NC}"
  fi

  if [ $p95 -gt 600 ]; then
    echo -e "${YELLOW}⚠ p95 > 600ms target${NC}"
    status="WARN"
  else
    echo -e "${GREEN}✓ p95 < 600ms target${NC}"
  fi

  if [ $p99 -gt 1000 ]; then
    echo -e "${YELLOW}⚠ p99 > 1000ms target${NC}"
    status="WARN"
  else
    echo -e "${GREEN}✓ p99 < 1000ms target${NC}"
  fi

  echo ""

  # Fallback rate (only relevant for hybrid/llm-only modes)
  if [ "$mode" != "regex-only" ]; then
    local fallback_rate=$(calculate_fallback_rate METHODS)
    echo "Fallback Rate: ${fallback_rate}%"

    if [ $fallback_rate -lt 20 ]; then
      echo -e "${GREEN}✓ Fallback rate < 20% target${NC}"
    else
      echo -e "${YELLOW}⚠ Fallback rate >= 20%${NC}"
      status="WARN"
    fi
    echo ""
  fi

  # Cost estimation (LLM mode only)
  if [ "$mode" = "llm-only" ] || [ "$mode" = "hybrid" ]; then
    # Estimate: ~50 tokens per classification, Haiku 4.5 is $0.000003/token
    local successful_llm_calls=$((NUM_ITERATIONS - $(calculate_fallback_rate METHODS)))
    local estimated_tokens=$((successful_llm_calls * 50))
    local estimated_cost=$(echo "scale=8; $estimated_tokens * 0.000003" | bc)

    echo "Cost Estimation (LLM classifications):"
    echo "  Successful LLM calls: $successful_llm_calls"
    echo "  Estimated tokens: $estimated_tokens"
    echo "  Estimated cost: \$${estimated_cost}"
    echo "  Cost per classification: \$0.00003 (target)"

    # Note: Actual cost tracking would require API integration
    echo ""
  fi

  # Final status
  echo "==========================================="
  if [ "$status" = "PASS" ]; then
    echo -e "${GREEN}Overall Status: PASS${NC}"
    exit 0
  else
    echo -e "${YELLOW}Overall Status: ACCEPTABLE (with warnings)${NC}"
    exit 0
  fi
}

# Run main if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
