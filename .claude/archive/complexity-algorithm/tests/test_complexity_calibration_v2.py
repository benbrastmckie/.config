#!/usr/bin/env python3
"""
test_complexity_calibration_v2.py - Calibration using expanded phase files

Purpose: Analyze expanded phase files (not collapsed parent plan) for accurate calibration
Approach: Find expanded files, extract content, calculate raw scores, tune normalization

Usage: ./test_complexity_calibration_v2.py
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
PLAN_DIR = PROJECT_ROOT / ".claude/specs/plans/080_orchestrate_enhancement"

def load_ground_truth():
    """Load ground truth scores"""
    with open(GROUND_TRUTH) as f:
        data = yaml.safe_load(f)
    return [phase['ground_truth_score'] for phase in data['phases']]

def get_phase_file(phase_num):
    """Get the file to analyze for a phase (expanded file if exists, else parent plan)"""
    expanded_file = PLAN_DIR / f"phase_{phase_num}_*.md"
    expanded_files = list(PLAN_DIR.glob(f"phase_{phase_num}_*.md"))

    if expanded_files:
        return expanded_files[0]  # Use expanded file
    else:
        return PLAN_DIR / "080_orchestrate_enhancement.md"  # Use parent plan

def extract_full_phase_content(phase_file):
    """Extract full content from phase file"""
    with open(phase_file) as f:
        return f.read()

def extract_phase_from_parent(phase_num, plan_text):
    """Extract phase content from parent plan"""
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

def get_phase_content_and_name(phase_num):
    """Get phase content and name, preferring expanded files"""
    expanded_files = list(PLAN_DIR.glob(f"phase_{phase_num}_*.md"))

    if expanded_files:
        # Use expanded file
        phase_file = expanded_files[0]
        content = extract_full_phase_content(phase_file)
        # Extract name from first heading
        match = re.search(r'^# (.+)$', content, re.MULTILINE)
        name = match.group(1) if match else f"Phase {phase_num}"
        return content, name, True  # expanded=True
    else:
        # Use parent plan
        parent_file = PLAN_DIR / "080_orchestrate_enhancement.md"
        with open(parent_file) as f:
            plan_text = f.read()
        content = extract_phase_from_parent(phase_num, plan_text)
        # Extract name from phase header
        match = re.search(rf'^### Phase {phase_num}: (.+)$', plan_text, re.MULTILINE)
        name = match.group(1) if match else f"Phase {phase_num}"
        return content, name, False  # expanded=False

def get_raw_scores_from_analyzer():
    """Run analyzer on all phases and extract scores"""
    print("Analyzing all phases...")
    print()

    raw_scores = []
    for phase_num in range(8):
        content, name, is_expanded = get_phase_content_and_name(phase_num)

        print(f"Phase {phase_num}: {name[:50]}")
        print(f"  Source: {'Expanded file' if is_expanded else 'Parent plan (collapsed)'}")

        # Run analyzer
        try:
            result = subprocess.run(
                [str(ANALYZER), name, content],
                capture_output=True,
                text=True,
                timeout=30,
                env={'COMPLEXITY_DEBUG': '1', 'PATH': subprocess.os.environ['PATH']}
            )

            # Extract task count from debug output
            task_match = re.search(r'Final task count: (\d+)', result.stderr)
            file_match = re.search(r'File count: (\d+)', result.stderr)
            depth_match = re.search(r'Dependency depth: (\d+)', result.stderr)
            test_match = re.search(r'Test count: (\d+)', result.stderr)
            risk_match = re.search(r'Risk count: (\d+)', result.stderr)
            raw_match = re.search(r'raw_score_int = (\d+)', result.stderr)

            if task_match and raw_match:
                tasks = int(task_match.group(1))
                files = int(file_match.group(1)) if file_match else 0
                depth = int(depth_match.group(1)) if depth_match else 0
                tests = int(test_match.group(1)) if test_match else 0
                risks = int(risk_match.group(1)) if risk_match else 0
                raw_int = int(raw_match.group(1))
                raw_score = raw_int / 100.0  # Convert from x100 integer to decimal

                print(f"  Tasks: {tasks}, Files: {files}, Depth: {depth}, Tests: {tests}, Risks: {risks}")
                print(f"  Raw score: {raw_score:.2f}")
                raw_scores.append(raw_score)
            else:
                print(f"  WARNING: Could not extract factors from debug output")
                raw_scores.append(0.0)

        except Exception as e:
            print(f"  ERROR: {e}")
            raw_scores.append(0.0)

        print()

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
    """Apply simple linear scaling with cap"""
    return [min(15.0, score * factor) for score in raw_scores]

def apply_power_scaling(raw_scores, power, scale):
    """Apply power law scaling"""
    return [min(15.0, scale * (score ** power)) for score in raw_scores]

def grid_search_linear(raw_scores, ground_truth):
    """Find best linear scaling factor"""
    best_correlation = -10.0
    best_factor = 0.0

    for factor in [f/100 for f in range(50, 500, 5)]:  # 0.5 to 5.0 by 0.05
        scaled = apply_linear_scaling(raw_scores, factor)
        corr = calculate_correlation(ground_truth, scaled)

        if corr > best_correlation:
            best_correlation = corr
            best_factor = factor

    return best_factor, best_correlation

def grid_search_power(raw_scores, ground_truth):
    """Find best power law parameters"""
    best_correlation = -10.0
    best_power = 1.0
    best_scale = 1.0

    for power in [p/10 for p in range(5, 30, 2)]:  # 0.5 to 3.0
        for scale in [s/10 for s in range(5, 100, 5)]:  # 0.5 to 10.0
            scaled = apply_power_scaling(raw_scores, power, scale)
            corr = calculate_correlation(ground_truth, scaled)

            if corr > best_correlation:
                best_correlation = corr
                best_power = power
                best_scale = scale

    return best_power, best_scale, best_correlation

def main():
    print("=== Complexity Calibration v2 (Expanded Files) ===")
    print()

    # Get raw scores from analyzer
    raw_scores = get_raw_scores_from_analyzer()
    ground_truth = load_ground_truth()

    print("="*60)
    print("Summary")
    print("="*60)
    print(f"Raw scores:    {[f'{s:.2f}' for s in raw_scores]}")
    print(f"Ground truth:  {ground_truth}")
    print()

    # Calculate baseline correlation
    baseline_corr = calculate_correlation(ground_truth, raw_scores)
    print(f"Baseline correlation (raw): {baseline_corr:.4f}")
    print()

    # Grid search for best scaling
    print("="*60)
    print("Linear Scaling")
    print("="*60)
    factor, corr_linear = grid_search_linear(raw_scores, ground_truth)
    print(f"Best factor: {factor:.3f}")
    print(f"Correlation: {corr_linear:.4f}")
    scaled_linear = apply_linear_scaling(raw_scores, factor)
    print(f"Scaled: {[f'{s:.1f}' for s in scaled_linear]}")
    print()

    print("="*60)
    print("Power Law Scaling")
    print("="*60)
    power, scale, corr_power = grid_search_power(raw_scores, ground_truth)
    print(f"Best power: {power:.2f}, scale: {scale:.2f}")
    print(f"Correlation: {corr_power:.4f}")
    scaled_power = apply_power_scaling(raw_scores, power, scale)
    print(f"Scaled: {[f'{s:.1f}' for s in scaled_power]}")
    print()

    # Determine best approach
    if corr_linear > corr_power:
        best_approach = "Linear"
        best_corr = corr_linear
        best_params = {'factor': factor}
        best_scaled = scaled_linear
    else:
        best_approach = "Power Law"
        best_corr = corr_power
        best_params = {'power': power, 'scale': scale}
        best_scaled = scaled_power

    print("="*60)
    print(f"BEST: {best_approach} (correlation: {best_corr:.4f})")
    print("="*60)
    print()

    # Phase-by-phase comparison
    print(f"{'Phase':<8} {'Name':<30} {'Ground':>8} {'Raw':>8} {'Scaled':>8} {'Diff':>8}")
    print("-"*70)
    for i in range(8):
        _, name, _ = get_phase_content_and_name(i)
        print(f"{i:<8} {name[:28]:<30} {ground_truth[i]:>8.1f} {raw_scores[i]:>8.2f} {best_scaled[i]:>8.1f} {best_scaled[i]-ground_truth[i]:>8.1f}")

    print()

    if best_corr >= 0.90:
        print(f"✅ Target achieved! Correlation: {best_corr:.4f} >= 0.90")
    else:
        print(f"⚠️  Target not met: {best_corr:.4f} < 0.90")

    # Save results
    CALIB_DIR = PROJECT_ROOT / ".claude/data/complexity_calibration"
    CALIB_DIR.mkdir(parents=True, exist_ok=True)

    with open(CALIB_DIR / "calibration_results.yaml", "w") as f:
        yaml.dump({
            'raw_scores': [float(s) for s in raw_scores],
            'ground_truth': ground_truth,
            'best_approach': best_approach,
            'best_correlation': float(best_corr),
            'parameters': best_params,
            'scaled_scores': [float(s) for s in best_scaled]
        }, f)

    print(f"\n✅ Results saved to: {CALIB_DIR / 'calibration_results.yaml'}")

if __name__ == "__main__":
    main()
