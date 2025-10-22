#!/usr/bin/env bash
#
# robust-scaling.sh - IQR-based robust scaling and sigmoid mapping utilities
#
# Purpose: Transform raw complexity scores to 0-15 range using robust scaling
# Prevents outliers from causing ceiling effects
#
# Usage:
#   source robust-scaling.sh
#   scaled=$(robust_scale $raw_score $median $iqr)
#   final=$(sigmoid_map $scaled 15)

set -euo pipefail

# Configuration directory for calibration parameters
CALIBRATION_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/data/complexity_calibration"
mkdir -p "$CALIBRATION_DIR" 2>/dev/null || true

# Robust Scaling: (value - median) / IQR
# Uses median and IQR instead of mean/std to resist outliers
robust_scale() {
  local raw_score=$1
  local median=$2
  local iqr=$3

  # Handle edge case: IQR = 0
  if [ "$iqr" -eq 0 ]; then
    echo "0"
    return
  fi

  # Calculate scaled value using integer arithmetic
  # scaled = ((raw - median) * 100) / iqr
  # Multiply by 100 for 2 decimal places of precision

  local raw_int=$(echo "$raw_score * 100" | awk '{printf "%.0f", $1}')
  local median_int=$(echo "$median * 100" | awk '{printf "%.0f", $1}')

  local diff=$(( raw_int - median_int ))
  local iqr_int=$(echo "$iqr * 100" | awk '{printf "%.0f", $1}')

  local scaled_int=$(( (diff * 100) / iqr_int ))

  # Convert back to decimal (2 decimal places)
  local whole=$(( scaled_int / 100 ))
  local decimal=$(( scaled_int % 100 ))
  local decimal_abs=$(( decimal < 0 ? -decimal : decimal ))

  if [ "$decimal_abs" -lt 10 ]; then
    decimal_abs="0${decimal_abs}"
  fi

  if [ "$scaled_int" -lt 0 ]; then
    # Negative number
    if [ "$whole" -eq 0 ]; then
      echo "-0.${decimal_abs}"
    else
      echo "${whole}.${decimal_abs}"
    fi
  else
    echo "${whole}.${decimal_abs}"
  fi
}

# Sigmoid mapping: final = max_value / (1 + exp(-scaled))
# Provides smooth compression of extremes
# Guarantees output in range (0, max_value)
sigmoid_map() {
  local scaled=$1
  local max_value=$2

  # Use awk for floating point exponential calculation
  # sigmoid = max / (1 + e^(-scaled))
  local final=$(awk -v scaled="$scaled" -v max="$max_value" '
    BEGIN {
      e = 2.71828182845904523536
      exp_val = e^(-scaled)
      sigmoid = max / (1 + exp_val)
      printf "%.1f", sigmoid
    }
  ')

  echo "$final"
}

# Linear mapping with scaling factor (simpler alternative)
# final = (raw * scale_factor)
linear_scale() {
  local raw_score=$1
  local scale_factor=$2
  local max_value=${3:-15}

  # Calculate scaled value
  local scaled_int=$(echo "$raw_score * $scale_factor * 10" | awk '{printf "%.0f", $1}')

  # Cap at max
  local max_int=$(( max_value * 10 ))
  if [ "$scaled_int" -gt "$max_int" ]; then
    scaled_int=$max_int
  fi

  # Convert to decimal
  local whole=$(( scaled_int / 10 ))
  local decimal=$(( scaled_int % 10 ))

  echo "${whole}.${decimal}"
}

# Save calibration parameters to file
save_calibration_params() {
  local median=$1
  local iqr=$2
  local scale_factor=${3:-1.0}

  cat > "$CALIBRATION_DIR/params.txt" <<EOF
# Complexity Calibration Parameters
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
MEDIAN=$median
IQR=$iqr
SCALE_FACTOR=$scale_factor
EOF

  echo "Calibration parameters saved to $CALIBRATION_DIR/params.txt"
}

# Load calibration parameters from file
load_calibration_params() {
  local params_file="$CALIBRATION_DIR/params.txt"

  if [ ! -f "$params_file" ]; then
    echo "ERROR: Calibration parameters not found: $params_file" >&2
    echo "Run calibration first to generate parameters" >&2
    return 1
  fi

  # Source the parameters file
  source "$params_file"

  echo "$MEDIAN $IQR $SCALE_FACTOR"
}

# Test functions (if script run directly)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  echo "=== Robust Scaling Utility Tests ==="
  echo ""

  echo "Test 1: Robust scaling with known values"
  median=5.0
  iqr=3.0
  raw_score=8.0

  scaled=$(robust_scale $raw_score $median $iqr)
  echo "robust_scale($raw_score, median=$median, iqr=$iqr) = $scaled"
  echo "Expected: ~1.0 ((8-5)/3 = 1.0)"
  echo ""

  echo "Test 2: Sigmoid mapping"
  final=$(sigmoid_map 1.0 15)
  echo "sigmoid_map(scaled=1.0, max=15) = $final"
  echo "Expected: ~11.2 (15/(1+e^-1) = 15/1.37 = 10.9)"
  echo ""

  final=$(sigmoid_map -1.0 15)
  echo "sigmoid_map(scaled=-1.0, max=15) = $final"
  echo "Expected: ~3.8 (15/(1+e^1) = 15/3.72 = 4.0)"
  echo ""

  final=$(sigmoid_map 0.0 15)
  echo "sigmoid_map(scaled=0.0, max=15) = $final"
  echo "Expected: ~7.5 (15/(1+1) = 7.5)"
  echo ""

  echo "Test 3: Linear scaling (for comparison)"
  final=$(linear_scale 8.0 1.5 15)
  echo "linear_scale(raw=8.0, factor=1.5, max=15) = $final"
  echo "Expected: 12.0 (8 * 1.5 = 12)"
  echo ""

  echo "Test 4: Save/load calibration parameters"
  save_calibration_params 5.0 3.0 1.5
  params=$(load_calibration_params)
  echo "Loaded parameters: $params"
  echo "Expected: 5.0 3.0 1.5"
  echo ""

  echo "=== Tests Complete ==="
fi
