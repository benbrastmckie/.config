#!/usr/bin/env python3
"""
test_complexity_calibration.py - Tune normalization for optimal correlation

Purpose: Find optimal scaling parameters to achieve correlation >0.90
Approach: Try different scaling strategies and measure correlation

Usage: ./test_complexity_calibration.py
"""

import subprocess
import sys
import yaml
from pathlib import Path
from statistics import mean, median
import re
import math

# Paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
ANALYZER = PROJECT_ROOT / ".claude/lib/analyze-phase-complexity.sh"
GROUND_TRUTH = SCRIPT_DIR / "fixtures/complexity/plan_080_ground_truth.yaml"
PLAN_FILE = PROJECT_ROOT / ".claude/specs/plans/080_orchestrate_enhancement/080_orchestrate_enhancement.md"

def load_ground_truth():
    """Load ground truth scores"""
    with open(GROUND_TRUTH) as f:
        data = yaml.safe_load(f)
    return [phase['ground_truth_score'] for phase in data['phases']]

def extract_phase_content(phase_num, plan_text):
    """Extract content for a specific phase"""
    lines = plan_text.split('\n')
    capturing = False
    content = []

    for line in lines:
        if line.startswith(f'### Phase {phase_num}:'):
            capturing = True
            continue
        if capturing and (line.startswith('### Phase ') or line.startswith('## ')):
            break
        if capturing:
            content.append(line)

    return '\n'.join(content)

def extract_phase_name(phase_num, plan_text):
    """Extract phase name"""
    pattern = rf'^### Phase {phase_num}: (.+)$'
    for line in plan_text.split('\n'):
        match = re.match(pattern, line)
        if match:
            return match.group(1)
    return f"Phase {phase_num}"

def get_raw_scores():
    """Get raw scores from algorithm (before final normalization)"""
    with open(PLAN_FILE) as f:
        plan_text = f.read()

    raw_scores = []
    for phase_num in range(8):
        phase_name = extract_phase_name(phase_num, plan_text)
        phase_content = extract_phase_content(phase_num, plan_text)

        # Extract factors manually to get raw score
        task_count = phase_content.count('- [ ]')
        file_count = min(len(set(re.findall(r'([a-zA-Z0-9_/-]+/)*[a-zA-Z0-9_-]+\.[a-zA-Z0-9]+', phase_content))), 30)

        # Simplified dependency depth (count comma-separated items)
        dep_match = re.search(r'depends_on:\s*\[([^\]]+)\]', phase_content)
        depth = min(len(dep_match.group(1).split(',')) if dep_match else 0, 5)

        test_count = min(len(re.findall(r'test|spec|coverage|testing', phase_content, re.IGNORECASE)), 20)
        risk_count = min(len(re.findall(r'security|migration|breaking|API|schema|authentication|authorization|database', phase_content, re.IGNORECASE)), 10)

        # Calculate raw score (NOT normalized)
        raw = (task_count * 0.30) + (file_count * 0.20) + (depth * 0.20) + (test_count * 0.15) + (risk_count * 0.15)
        raw_scores.append(raw)

    return raw_scores

def calculate_correlation(x, y):
    """Calculate Pearson correlation"""
    n = len(x)
    mean_x = sum(x) / n
    mean_y = sum(y) / n

    sum_xy = sum((x[i] - mean_x) * (y[i] - mean_y) for i in range(n))
    sum_xx = sum((x[i] - mean_x) ** 2 for i in range(n))
    sum_yy = sum((y[i] - mean_y) ** 2 for i in range(n))

    denominator = (sum_xx * sum_yy) ** 0.5
    return sum_xy / denominator if denominator != 0 else 0.0

def apply_linear_scaling(raw_scores, factor):
    """Apply simple linear scaling"""
    return [min(15.0, score * factor) for score in raw_scores]

def apply_power_scaling(raw_scores, power, scale):
    """Apply power law scaling: final = scale * (raw ^ power)"""
    return [min(15.0, scale * (score ** power)) for score in raw_scores]

def apply_robust_sigmoid(raw_scores, raw_median, raw_iqr, steepness=1.0):
    """Apply robust scaling + sigmoid mapping"""
    scaled = [(score - raw_median) / raw_iqr if raw_iqr > 0 else 0 for score in raw_scores]
    final = [15.0 / (1 + math.exp(-steepness * s)) for s in scaled]
    return final

def grid_search_linear():
    """Grid search for best linear scaling factor"""
    raw_scores = get_raw_scores()
    ground_truth = load_ground_truth()

    best_correlation = -1.0
    best_factor = 0.0

    print("Grid search for linear scaling factor...")
    for factor in [f/10 for f in range(10, 200, 5)]:  # 1.0 to 20.0 by 0.5
        scaled = apply_linear_scaling(raw_scores, factor)
        corr = calculate_correlation(ground_truth, scaled)

        if corr > best_correlation:
            best_correlation = corr
            best_factor = factor

    return best_factor, best_correlation

def grid_search_power():
    """Grid search for best power law parameters"""
    raw_scores = get_raw_scores()
    ground_truth = load_ground_truth()

    best_correlation = -1.0
    best_power = 1.0
    best_scale = 1.0

    print("Grid search for power law (power, scale)...")
    for power in [p/10 for p in range(5, 20, 2)]:  # 0.5 to 2.0
        for scale in [s/10 for s in range(10, 150, 10)]:  # 1.0 to 15.0
            scaled = apply_power_scaling(raw_scores, power, scale)
            corr = calculate_correlation(ground_truth, scaled)

            if corr > best_correlation:
                best_correlation = corr
                best_power = power
                best_scale = scale

    return best_power, best_scale, best_correlation

def grid_search_robust_sigmoid():
    """Grid search for best robust sigmoid parameters"""
    raw_scores = get_raw_scores()
    ground_truth = load_ground_truth()

    raw_median = median(raw_scores)
    sorted_raw = sorted(raw_scores)
    q1 = sorted_raw[len(sorted_raw) // 4]
    q3 = sorted_raw[(3 * len(sorted_raw)) // 4]
    raw_iqr = q3 - q1

    best_correlation = -1.0
    best_steepness = 1.0

    print(f"Grid search for sigmoid steepness (median={raw_median:.2f}, IQR={raw_iqr:.2f})...")
    for steepness in [s/10 for s in range(5, 50, 2)]:  # 0.5 to 5.0
        scaled = apply_robust_sigmoid(raw_scores, raw_median, raw_iqr, steepness)
        corr = calculate_correlation(ground_truth, scaled)

        if corr > best_correlation:
            best_correlation = corr
            best_steepness = steepness

    return raw_median, raw_iqr, best_steepness, best_correlation

def main():
    print("=== Complexity Calibration Tuning ===")
    print()

    # Get raw scores
    print("Step 1: Extracting raw scores (before normalization)...")
    raw_scores = get_raw_scores()
    ground_truth = load_ground_truth()
    print(f"Raw scores: {[f'{s:.2f}' for s in raw_scores]}")
    print(f"Ground truth: {ground_truth}")
    print()

    # Calculate baseline correlation
    baseline_corr = calculate_correlation(ground_truth, raw_scores)
    print(f"Baseline correlation (raw scores): {baseline_corr:.4f}")
    print()

    # Try different scaling approaches
    print("="*60)
    print("Approach 1: Linear Scaling")
    print("="*60)
    factor, corr = grid_search_linear()
    print(f"Best linear factor: {factor:.2f}")
    print(f"Correlation: {corr:.4f}")
    scaled = apply_linear_scaling(raw_scores, factor)
    print(f"Scaled scores: {[f'{s:.1f}' for s in scaled]}")
    print()

    print("="*60)
    print("Approach 2: Power Law Scaling")
    print("="*60)
    power, scale, corr = grid_search_power()
    print(f"Best power: {power:.2f}, scale: {scale:.2f}")
    print(f"Correlation: {corr:.4f}")
    scaled = apply_power_scaling(raw_scores, power, scale)
    print(f"Scaled scores: {[f'{s:.1f}' for s in scaled]}")
    print()

    print("="*60)
    print("Approach 3: Robust Scaling + Sigmoid")
    print("="*60)
    raw_median, raw_iqr, steepness, corr = grid_search_robust_sigmoid()
    print(f"Median: {raw_median:.2f}, IQR: {raw_iqr:.2f}, Steepness: {steepness:.2f}")
    print(f"Correlation: {corr:.4f}")
    scaled = apply_robust_sigmoid(raw_scores, raw_median, raw_iqr, steepness)
    print(f"Scaled scores: {[f'{s:.1f}' for s in scaled]}")
    print()

    # Determine best approach
    approaches = [
        ("Linear", factor, None, grid_search_linear()[1]),
        ("Power Law", power, scale, grid_search_power()[2]),
        ("Robust Sigmoid", steepness, None, grid_search_robust_sigmoid()[3])
    ]

    best_approach = max(approaches, key=lambda x: x[3])
    print("="*60)
    print(f"BEST APPROACH: {best_approach[0]} (correlation: {best_approach[3]:.4f})")
    print("="*60)
    print()

    if best_approach[3] >= 0.90:
        print(f"✅ Target correlation achieved (>= 0.90)")
    else:
        print(f"⚠️  Target correlation not achieved ({best_approach[3]:.4f} < 0.90)")
        print("Consider:")
        print("  - Feature weight adjustments")
        print("  - Additional calibration iterations")
        print("  - Hybrid scaling approaches")

    # Save calibration parameters
    CALIB_DIR = PROJECT_ROOT / ".claude/data/complexity_calibration"
    CALIB_DIR.mkdir(parents=True, exist_ok=True)

    with open(CALIB_DIR / "tuning_results.yaml", "w") as f:
        yaml.dump({
            'raw_scores': [float(s) for s in raw_scores],
            'ground_truth': ground_truth,
            'linear': {
                'factor': float(factor),
                'correlation': float(grid_search_linear()[1])
            },
            'power_law': {
                'power': float(power),
                'scale': float(scale),
                'correlation': float(grid_search_power()[2])
            },
            'robust_sigmoid': {
                'median': float(raw_median),
                'iqr': float(raw_iqr),
                'steepness': float(steepness),
                'correlation': float(grid_search_robust_sigmoid()[3])
            },
            'best_approach': best_approach[0],
            'best_correlation': float(best_approach[3])
        }, f)

    print(f"\nCalibration results saved to: {CALIB_DIR / 'tuning_results.yaml'}")

if __name__ == "__main__":
    main()
