#!/usr/bin/env bash
#
# test_complexity_baseline.sh - Calculate baseline complexity metrics for Plan 080
#
# Purpose: Measure current formula performance before calibration
# Outputs: Raw scores, normalized scores, correlation, distribution metrics
#
# Usage: ./test_complexity_baseline.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Import complexity analyzer
ANALYZER="$PROJECT_ROOT/.claude/lib/analyze-phase-complexity.sh"
if [ ! -x "$ANALYZER" ]; then
  echo "ERROR: Complexity analyzer not found or not executable: $ANALYZER" >&2
  exit 1
fi

# Ground truth file
GROUND_TRUTH="$SCRIPT_DIR/fixtures/complexity/plan_080_ground_truth.yaml"
if [ ! -f "$GROUND_TRUTH" ]; then
  echo "ERROR: Ground truth file not found: $GROUND_TRUTH" >&2
  exit 1
fi

# Plan file
PLAN_FILE="$PROJECT_ROOT/.claude/specs/plans/080_orchestrate_enhancement/080_orchestrate_enhancement.md"
if [ ! -f "$PLAN_FILE" ]; then
  echo "ERROR: Plan 080 file not found: $PLAN_FILE" >&2
  exit 1
fi

echo "=== Complexity Baseline Analysis for Plan 080 ==="
echo "Plan: $(basename "$PLAN_FILE")"
echo "Ground Truth: $(basename "$GROUND_TRUTH")"
echo "Analyzer: $(basename "$ANALYZER")"
echo ""

# Extract ground truth scores
extract_ground_truth() {
  # Parse YAML ground truth scores
  # Format: "ground_truth_score: X.X"
  grep "ground_truth_score:" "$GROUND_TRUTH" | \
    grep -oE '[0-9]+\.[0-9]+' | \
    head -8
}

# Extract phase content from plan file
extract_phase_content() {
  local phase_num="$1"
  local plan_file="$2"

  # Extract content between "### Phase N:" and next "### Phase" or "##"
  awk -v phase="$phase_num" '
    /^### Phase/ {
      if ($3 == phase":") {
        capture = 1
        next
      } else if (capture) {
        exit
      }
    }
    /^## / && capture {
      exit
    }
    capture {
      print
    }
  ' "$plan_file"
}

# Calculate algorithm scores for all phases
calculate_algorithm_scores() {
  local plan_file="$1"
  local phase_num
  local phase_content
  local score_output
  local score

  for phase_num in {0..7}; do
    # Extract phase name from plan
    phase_name=$(grep "^### Phase $phase_num:" "$plan_file" | sed "s/^### Phase $phase_num: //")

    if [ -z "$phase_name" ]; then
      echo "ERROR: Phase $phase_num not found in plan file" >&2
      echo "0.0"
      continue
    fi

    # Extract phase content (tasks, dependencies, etc.)
    phase_content=$(extract_phase_content "$phase_num" "$plan_file")

    # Run complexity analyzer
    score_output=$("$ANALYZER" "$phase_name" "$phase_content" 2>/dev/null || echo "COMPLEXITY_SCORE=0.0")
    score=$(echo "$score_output" | grep -oE '[0-9]+\.[0-9]+')

    echo "$score"
  done
}

# Calculate correlation coefficient (Pearson's r)
calculate_correlation() {
  local -n ground_ref=$1
  local -n algorithm_ref=$2
  local n=${#ground_ref[@]}

  if [ "$n" -ne "${#algorithm_ref[@]}" ]; then
    echo "ERROR: Array length mismatch" >&2
    echo "0.0"
    return
  fi

  # Calculate means
  local sum_x=0
  local sum_y=0
  local i

  for i in $(seq 0 $((n-1))); do
    sum_x=$(echo "$sum_x + ${ground_ref[$i]}" | bc -l)
    sum_y=$(echo "$sum_y + ${algorithm_ref[$i]}" | bc -l)
  done

  local mean_x=$(echo "scale=4; $sum_x / $n" | bc -l)
  local mean_y=$(echo "scale=4; $sum_y / $n" | bc -l)

  # Calculate correlation components
  local sum_xy=0
  local sum_xx=0
  local sum_yy=0
  local diff_x
  local diff_y

  for i in $(seq 0 $((n-1))); do
    diff_x=$(echo "${ground_ref[$i]} - $mean_x" | bc -l)
    diff_y=$(echo "${algorithm_ref[$i]} - $mean_y" | bc -l)

    sum_xy=$(echo "$sum_xy + ($diff_x * $diff_y)" | bc -l)
    sum_xx=$(echo "$sum_xx + ($diff_x * $diff_x)" | bc -l)
    sum_yy=$(echo "$sum_yy + ($diff_y * $diff_y)" | bc -l)
  done

  # Calculate correlation coefficient
  local denominator=$(echo "sqrt($sum_xx * $sum_yy)" | bc -l)

  if [ "$(echo "$denominator == 0" | bc -l)" = "1" ]; then
    echo "0.0"
    return
  fi

  local correlation=$(echo "scale=4; $sum_xy / $denominator" | bc -l)
  echo "$correlation"
}

# Calculate distribution metrics
calculate_distribution_metrics() {
  local -n scores_ref=$1
  local n=${#scores_ref[@]}

  # Sort array for median/quartile calculation
  local sorted=($(printf '%s\n' "${scores_ref[@]}" | sort -n))

  # Mean
  local sum=0
  local i
  for i in $(seq 0 $((n-1))); do
    sum=$(echo "$sum + ${scores_ref[$i]}" | bc -l)
  done
  local mean=$(echo "scale=2; $sum / $n" | bc -l)

  # Median
  local median_idx=$((n / 2))
  local median=${sorted[$median_idx]}

  # Min/Max
  local min=${sorted[0]}
  local max=${sorted[$((n-1))]}

  # Standard deviation
  local sum_sq_diff=0
  local diff
  for i in $(seq 0 $((n-1))); do
    diff=$(echo "${scores_ref[$i]} - $mean" | bc -l)
    sum_sq_diff=$(echo "$sum_sq_diff + ($diff * $diff)" | bc -l)
  done
  local variance=$(echo "scale=4; $sum_sq_diff / $n" | bc -l)
  local std_dev=$(echo "scale=2; sqrt($variance)" | bc -l)

  # IQR (Q1 and Q3)
  local q1_idx=$((n / 4))
  local q3_idx=$(((3 * n) / 4))
  local q1=${sorted[$q1_idx]}
  local q3=${sorted[$q3_idx]}
  local iqr=$(echo "scale=2; $q3 - $q1" | bc -l)

  echo "$mean|$median|$std_dev|$min|$max|$iqr|$q1|$q3"
}

# Main analysis
main() {
  echo "Step 1: Extracting ground truth scores..."
  mapfile -t ground_truth_scores < <(extract_ground_truth)
  echo "Ground truth scores: ${ground_truth_scores[*]}"
  echo ""

  echo "Step 2: Calculating algorithm scores with current formula (0.822 normalization)..."
  mapfile -t algorithm_scores < <(calculate_algorithm_scores "$PLAN_FILE")
  echo "Algorithm scores: ${algorithm_scores[*]}"
  echo ""

  echo "Step 3: Calculating correlation..."
  correlation=$(calculate_correlation ground_truth_scores algorithm_scores)
  echo "Pearson correlation: $correlation"
  echo "Target: >0.90"
  echo ""

  echo "Step 4: Calculating distribution metrics..."
  echo ""
  echo "--- Ground Truth Distribution ---"
  IFS='|' read -r mean median std_dev min max iqr q1 q3 < <(calculate_distribution_metrics ground_truth_scores)
  echo "Mean:     $mean"
  echo "Median:   $median"
  echo "Std Dev:  $std_dev"
  echo "Min:      $min"
  echo "Max:      $max"
  echo "Q1:       $q1"
  echo "Q3:       $q3"
  echo "IQR:      $iqr"
  echo ""

  echo "--- Algorithm Score Distribution ---"
  IFS='|' read -r mean median std_dev min max iqr q1 q3 < <(calculate_distribution_metrics algorithm_scores)
  echo "Mean:     $mean"
  echo "Median:   $median"
  echo "Std Dev:  $std_dev"
  echo "Min:      $min"
  echo "Max:      $max"
  echo "Q1:       $q1"
  echo "Q3:       $q3"
  echo "IQR:      $iqr"
  echo ""

  echo "Step 5: Phase-by-phase comparison..."
  echo ""
  printf "%-8s %-50s %12s %12s %12s\n" "Phase" "Name" "Ground Truth" "Algorithm" "Difference"
  printf "%-8s %-50s %12s %12s %12s\n" "-----" "----" "------------" "---------" "----------"

  for i in {0..7}; do
    phase_name=$(grep "^### Phase $i:" "$PLAN_FILE" | sed "s/^### Phase $i: //" | cut -c1-48)
    ground_score=${ground_truth_scores[$i]}
    algo_score=${algorithm_scores[$i]}
    diff=$(echo "scale=2; $algo_score - $ground_score" | bc -l)

    printf "%-8s %-50s %12s %12s %12s\n" "$i" "$phase_name" "$ground_score" "$algo_score" "$diff"
  done

  echo ""
  echo "Step 6: Identifying issues..."
  echo ""

  # Count phases at ceiling (15.0)
  ceiling_count=$(printf '%s\n' "${algorithm_scores[@]}" | grep -c "^15\.0$" || echo "0")
  echo "Phases at ceiling (15.0): $ceiling_count / 8"

  # Check correlation threshold
  if [ "$(echo "$correlation < 0.90" | bc -l)" = "1" ]; then
    echo "❌ Correlation below target (<0.90)"
  else
    echo "✅ Correlation meets target (>=0.90)"
  fi

  # Check distribution clustering
  if [ "$ceiling_count" -ge 5 ]; then
    echo "❌ Severe score clustering at ceiling (>= 5 phases)"
  elif [ "$ceiling_count" -ge 3 ]; then
    echo "⚠️  Moderate score clustering at ceiling (>= 3 phases)"
  else
    echo "✅ Good score distribution"
  fi

  echo ""
  echo "=== Baseline Analysis Complete ==="
  echo ""
  echo "Next steps:"
  echo "1. Implement IQR-based robust scaling (median: $median, IQR: $iqr)"
  echo "2. Implement sigmoid mapping for 0-15 range"
  echo "3. Tune normalization to achieve correlation >0.90"
}

# Execute main analysis
main
