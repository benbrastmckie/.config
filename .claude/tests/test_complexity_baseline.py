#!/usr/bin/env python3
"""
test_complexity_baseline.py - Calculate baseline complexity metrics for Plan 080

Purpose: Measure current formula performance before calibration
Outputs: Raw scores, normalized scores, correlation, distribution metrics

Usage: ./test_complexity_baseline.py
"""

import subprocess
import sys
import yaml
from pathlib import Path
from statistics import mean, median, stdev
import re

# Paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
ANALYZER = PROJECT_ROOT / ".claude/lib/analyze-phase-complexity.sh"
GROUND_TRUTH = SCRIPT_DIR / "fixtures/complexity/plan_080_ground_truth.yaml"
PLAN_FILE = PROJECT_ROOT / ".claude/specs/plans/080_orchestrate_enhancement/080_orchestrate_enhancement.md"

def load_ground_truth():
    """Load ground truth scores from YAML file"""
    with open(GROUND_TRUTH) as f:
        data = yaml.safe_load(f)

    scores = []
    for phase in data['phases']:
        scores.append(phase['ground_truth_score'])

    return scores

def extract_phase_content(phase_num, plan_text):
    """Extract content for a specific phase from plan file"""
    lines = plan_text.split('\n')
    capturing = False
    content = []

    for line in lines:
        # Start capturing at the target phase
        if line.startswith(f'### Phase {phase_num}:'):
            capturing = True
            continue

        # Stop at next phase or section
        if capturing and (line.startswith('### Phase ') or line.startswith('## ')):
            break

        if capturing:
            content.append(line)

    return '\n'.join(content)

def extract_phase_name(phase_num, plan_text):
    """Extract phase name from plan file"""
    pattern = rf'^### Phase {phase_num}: (.+)$'
    for line in plan_text.split('\n'):
        match = re.match(pattern, line)
        if match:
            return match.group(1)
    return f"Phase {phase_num}"

def calculate_algorithm_scores():
    """Calculate algorithm scores for all phases using current formula"""
    if not ANALYZER.exists() or not ANALYZER.is_file():
        print(f"ERROR: Complexity analyzer not found: {ANALYZER}", file=sys.stderr)
        sys.exit(1)

    with open(PLAN_FILE) as f:
        plan_text = f.read()

    scores = []
    for phase_num in range(8):
        phase_name = extract_phase_name(phase_num, plan_text)
        phase_content = extract_phase_content(phase_num, plan_text)

        # Run complexity analyzer
        try:
            result = subprocess.run(
                [str(ANALYZER), phase_name, phase_content],
                capture_output=True,
                text=True,
                timeout=30
            )

            # Extract score from output: COMPLEXITY_SCORE=N.N
            match = re.search(r'COMPLEXITY_SCORE=([0-9]+\.[0-9]+)', result.stdout)
            if match:
                score = float(match.group(1))
                scores.append(score)
            else:
                print(f"WARNING: Could not parse score for Phase {phase_num}", file=sys.stderr)
                scores.append(0.0)
        except Exception as e:
            print(f"ERROR running analyzer for Phase {phase_num}: {e}", file=sys.stderr)
            scores.append(0.0)

    return scores

def calculate_correlation(x, y):
    """Calculate Pearson correlation coefficient"""
    if len(x) != len(y):
        raise ValueError("Arrays must have same length")

    n = len(x)
    mean_x = sum(x) / n
    mean_y = sum(y) / n

    sum_xy = sum((x[i] - mean_x) * (y[i] - mean_y) for i in range(n))
    sum_xx = sum((x[i] - mean_x) ** 2 for i in range(n))
    sum_yy = sum((y[i] - mean_y) ** 2 for i in range(n))

    denominator = (sum_xx * sum_yy) ** 0.5

    if denominator == 0:
        return 0.0

    return sum_xy / denominator

def calculate_distribution_metrics(scores):
    """Calculate distribution statistics"""
    sorted_scores = sorted(scores)
    n = len(sorted_scores)

    q1_idx = n // 4
    q3_idx = (3 * n) // 4

    q1 = sorted_scores[q1_idx]
    q3 = sorted_scores[q3_idx]
    iqr = q3 - q1

    return {
        'mean': mean(scores),
        'median': median(scores),
        'std_dev': stdev(scores) if len(scores) > 1 else 0.0,
        'min': min(scores),
        'max': max(scores),
        'q1': q1,
        'q3': q3,
        'iqr': iqr
    }

def main():
    print("=== Complexity Baseline Analysis for Plan 080 ===")
    print(f"Plan: {PLAN_FILE.name}")
    print(f"Ground Truth: {GROUND_TRUTH.name}")
    print(f"Analyzer: {ANALYZER.name}")
    print()

    # Step 1: Load ground truth
    print("Step 1: Extracting ground truth scores...")
    ground_truth_scores = load_ground_truth()
    print(f"Ground truth scores: {ground_truth_scores}")
    print()

    # Step 2: Calculate algorithm scores
    print("Step 2: Calculating algorithm scores with current formula (0.822 normalization)...")
    algorithm_scores = calculate_algorithm_scores()
    print(f"Algorithm scores: {algorithm_scores}")
    print()

    # Step 3: Calculate correlation
    print("Step 3: Calculating correlation...")
    correlation = calculate_correlation(ground_truth_scores, algorithm_scores)
    print(f"Pearson correlation: {correlation:.4f}")
    print(f"Target: >0.90")
    print()

    # Step 4: Distribution metrics
    print("Step 4: Calculating distribution metrics...")
    print()
    print("--- Ground Truth Distribution ---")
    gt_metrics = calculate_distribution_metrics(ground_truth_scores)
    print(f"Mean:     {gt_metrics['mean']:.2f}")
    print(f"Median:   {gt_metrics['median']:.2f}")
    print(f"Std Dev:  {gt_metrics['std_dev']:.2f}")
    print(f"Min:      {gt_metrics['min']:.2f}")
    print(f"Max:      {gt_metrics['max']:.2f}")
    print(f"Q1:       {gt_metrics['q1']:.2f}")
    print(f"Q3:       {gt_metrics['q3']:.2f}")
    print(f"IQR:      {gt_metrics['iqr']:.2f}")
    print()

    print("--- Algorithm Score Distribution ---")
    algo_metrics = calculate_distribution_metrics(algorithm_scores)
    print(f"Mean:     {algo_metrics['mean']:.2f}")
    print(f"Median:   {algo_metrics['median']:.2f}")
    print(f"Std Dev:  {algo_metrics['std_dev']:.2f}")
    print(f"Min:      {algo_metrics['min']:.2f}")
    print(f"Max:      {algo_metrics['max']:.2f}")
    print(f"Q1:       {algo_metrics['q1']:.2f}")
    print(f"Q3:       {algo_metrics['q3']:.2f}")
    print(f"IQR:      {algo_metrics['iqr']:.2f}")
    print()

    # Step 5: Phase-by-phase comparison
    print("Step 5: Phase-by-phase comparison...")
    print()
    print(f"{'Phase':<8} {'Name':<50} {'Ground Truth':>12} {'Algorithm':>12} {'Difference':>12}")
    print(f"{'-----':<8} {'----':<50} {'------------':>12} {'---------':>12} {'----------':>12}")

    with open(PLAN_FILE) as f:
        plan_text = f.read()

    for i in range(8):
        phase_name = extract_phase_name(i, plan_text)[:48]
        ground_score = ground_truth_scores[i]
        algo_score = algorithm_scores[i]
        diff = algo_score - ground_score

        print(f"{i:<8} {phase_name:<50} {ground_score:>12.1f} {algo_score:>12.1f} {diff:>12.1f}")

    print()

    # Step 6: Identify issues
    print("Step 6: Identifying issues...")
    print()

    ceiling_count = sum(1 for score in algorithm_scores if score >= 14.5)
    print(f"Phases at/near ceiling (>=14.5): {ceiling_count} / 8")

    if correlation < 0.90:
        print(f"❌ Correlation below target (<0.90): {correlation:.4f}")
    else:
        print(f"✅ Correlation meets target (>=0.90): {correlation:.4f}")

    if ceiling_count >= 5:
        print(f"❌ Severe score clustering at ceiling (>= 5 phases)")
    elif ceiling_count >= 3:
        print(f"⚠️  Moderate score clustering at ceiling (>= 3 phases)")
    else:
        print(f"✅ Good score distribution")

    print()
    print("=== Baseline Analysis Complete ===")
    print()
    print("Next steps:")
    print(f"1. Implement IQR-based robust scaling (median: {algo_metrics['median']:.2f}, IQR: {algo_metrics['iqr']:.2f})")
    print("2. Implement sigmoid mapping for 0-15 range")
    print("3. Tune normalization to achieve correlation >0.90")

    # Return exit code based on correlation
    if correlation < 0.50:
        sys.exit(1)  # Poor correlation
    else:
        sys.exit(0)  # Acceptable for baseline

if __name__ == "__main__":
    main()
