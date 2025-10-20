#!/usr/bin/env bash
#
# Execution Enforcement Audit Script
#
# Audits command and agent files for execution enforcement patterns.
# Usage: ./audit-execution-enforcement.sh <file> [--json]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE="${1:-}"
OUTPUT_JSON="${2:-}"

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "Usage: $0 <command-or-agent-file> [--json]"
  exit 1
fi

# Initialize scores
SCORE_TOTAL=0
SCORE_MAX=100
FINDINGS=()

echo "Auditing: $FILE"
echo "========================================"
echo ""

## PATTERN 1: Imperative Language (20 points)
echo "[1/10] Checking for imperative language..."
SCORE_IMPERATIVE=0

if grep -q "YOU MUST" "$FILE"; then
  SCORE_IMPERATIVE=$((SCORE_IMPERATIVE + 10))
  echo "  ✓ Found 'YOU MUST' markers (+10)"
else
  echo "  ✗ Missing 'YOU MUST' markers (0)"
  FINDINGS+=("Missing imperative 'YOU MUST' language")
fi

if grep -q "EXECUTE NOW" "$FILE"; then
  SCORE_IMPERATIVE=$((SCORE_IMPERATIVE + 10))
  echo "  ✓ Found 'EXECUTE NOW' markers (+10)"
else
  echo "  ✗ Missing 'EXECUTE NOW' markers (0)"
  FINDINGS+=("Missing 'EXECUTE NOW' execution markers")
fi

echo "  Score: $SCORE_IMPERATIVE/20"
SCORE_TOTAL=$((SCORE_TOTAL + SCORE_IMPERATIVE))
echo ""

## PATTERN 2: Step Dependencies (15 points)
echo "[2/10] Checking for step dependencies..."
SCORE_STEPS=0

if grep -q "STEP [0-9]" "$FILE"; then
  STEP_COUNT=$(grep -c "STEP [0-9]" "$FILE" || echo 0)
  if [ "$STEP_COUNT" -ge 3 ]; then
    SCORE_STEPS=15
    echo "  ✓ Found $STEP_COUNT sequential steps (+15)"
  else
    SCORE_STEPS=7
    echo "  △ Found only $STEP_COUNT steps (+7)"
    FINDINGS+=("Few sequential steps (found $STEP_COUNT, expected ≥3)")
  fi
else
  echo "  ✗ No sequential steps found (0)"
  FINDINGS+=("No sequential step structure")
fi

echo "  Score: $SCORE_STEPS/15"
SCORE_TOTAL=$((SCORE_TOTAL + SCORE_STEPS))
echo ""

## PATTERN 3: Verification Checkpoints (20 points)
echo "[3/10] Checking for verification checkpoints..."
SCORE_VERIFICATION=0

if grep -q "MANDATORY VERIFICATION" "$FILE"; then
  SCORE_VERIFICATION=$((SCORE_VERIFICATION + 15))
  echo "  ✓ Found 'MANDATORY VERIFICATION' markers (+15)"
else
  echo "  ✗ Missing 'MANDATORY VERIFICATION' markers (0)"
  FINDINGS+=("Missing mandatory verification checkpoints")
fi

if grep -q "CHECKPOINT" "$FILE"; then
  SCORE_VERIFICATION=$((SCORE_VERIFICATION + 5))
  echo "  ✓ Found 'CHECKPOINT' markers (+5)"
else
  echo "  ✗ Missing 'CHECKPOINT' markers (0)"
  FINDINGS+=("Missing checkpoint markers")
fi

echo "  Score: $SCORE_VERIFICATION/20"
SCORE_TOTAL=$((SCORE_TOTAL + SCORE_VERIFICATION))
echo ""

## PATTERN 4: Fallback Mechanisms (10 points)
echo "[4/10] Checking for fallback mechanisms..."
SCORE_FALLBACK=0

if grep -qi "fallback" "$FILE"; then
  SCORE_FALLBACK=10
  echo "  ✓ Found fallback mechanism (+10)"
else
  echo "  △ No fallback mechanism found (0)"
  FINDINGS+=("No fallback mechanism for failures")
fi

echo "  Score: $SCORE_FALLBACK/10"
SCORE_TOTAL=$((SCORE_TOTAL + SCORE_FALLBACK))
echo ""

## PATTERN 5: Critical Requirements (10 points)
echo "[5/10] Checking for critical requirements..."
SCORE_CRITICAL=0

CRITICAL_COUNT=$(grep -c "CRITICAL\|ABSOLUTE REQUIREMENT" "$FILE" || echo 0)
if [ "$CRITICAL_COUNT" -ge 3 ]; then
  SCORE_CRITICAL=10
  echo "  ✓ Found $CRITICAL_COUNT critical markers (+10)"
elif [ "$CRITICAL_COUNT" -ge 1 ]; then
  SCORE_CRITICAL=5
  echo "  △ Found only $CRITICAL_COUNT critical markers (+5)"
  FINDINGS+=("Few critical requirement markers")
else
  echo "  ✗ No critical requirement markers (0)"
  FINDINGS+=("Missing critical requirement markers")
fi

echo "  Score: $SCORE_CRITICAL/10"
SCORE_TOTAL=$((SCORE_TOTAL + SCORE_CRITICAL))
echo ""

## PATTERN 6: Path Verification (10 points)
echo "[6/10] Checking for path verification..."
SCORE_PATH=0

if grep -q "absolute path" "$FILE" || grep -q "REPORT_PATH\|PLAN_PATH" "$FILE"; then
  SCORE_PATH=10
  echo "  ✓ Found path verification (+10)"
else
  echo "  △ No explicit path verification (0)"
fi

echo "  Score: $SCORE_PATH/10"
SCORE_TOTAL=$((SCORE_TOTAL + SCORE_PATH))
echo ""

## PATTERN 7: File Creation Enforcement (10 points)
echo "[7/10] Checking for file creation enforcement..."
SCORE_FILE=0

if grep -q "create.*file.*FIRST\|Create.*BEFORE" "$FILE"; then
  SCORE_FILE=10
  echo "  ✓ Found file-first enforcement (+10)"
elif grep -q "Write tool" "$FILE"; then
  SCORE_FILE=5
  echo "  △ Mentions Write tool but no explicit enforcement (+5)"
  FINDINGS+=("File creation mentioned but not enforced")
else
  echo "  △ No file creation enforcement (0)"
fi

echo "  Score: $SCORE_FILE/10"
SCORE_TOTAL=$((SCORE_TOTAL + SCORE_FILE))
echo ""

## PATTERN 8: Return Format Specification (5 points)
echo "[8/10] Checking for return format specification..."
SCORE_RETURN=0

if grep -q "return ONLY\|ONLY return" "$FILE"; then
  SCORE_RETURN=5
  echo "  ✓ Found return format specification (+5)"
else
  echo "  △ No explicit return format (0)"
fi

echo "  Score: $SCORE_RETURN/5"
SCORE_TOTAL=$((SCORE_TOTAL + SCORE_RETURN))
echo ""

## PATTERN 9: Passive Voice Detection (Negative Points)
echo "[9/10] Checking for passive voice (anti-pattern)..."
SCORE_PASSIVE=0

PASSIVE_COUNT=$(grep -c "should\|may\|can\|I am\|I will" "$FILE" || echo 0)
if [ "$PASSIVE_COUNT" -gt 10 ]; then
  SCORE_PASSIVE=-10
  echo "  ✗ Found $PASSIVE_COUNT passive/descriptive phrases (-10)"
  FINDINGS+=("High passive voice count: $PASSIVE_COUNT instances")
elif [ "$PASSIVE_COUNT" -gt 5 ]; then
  SCORE_PASSIVE=-5
  echo "  △ Found $PASSIVE_COUNT passive/descriptive phrases (-5)"
  FINDINGS+=("Some passive voice: $PASSIVE_COUNT instances")
else
  echo "  ✓ Minimal passive voice (0)"
fi

echo "  Score: $SCORE_PASSIVE/0"
SCORE_TOTAL=$((SCORE_TOTAL + SCORE_PASSIVE))
echo ""

## PATTERN 10: Error Handling (10 points)
echo "[10/10] Checking for error handling..."
SCORE_ERROR=0

if grep -q "exit 1\|echo.*ERROR" "$FILE"; then
  SCORE_ERROR=10
  echo "  ✓ Found error handling (+10)"
else
  echo "  △ No explicit error handling (0)"
fi

echo "  Score: $SCORE_ERROR/10"
SCORE_TOTAL=$((SCORE_TOTAL + SCORE_ERROR))
echo ""

## FINAL SCORE
echo "========================================"
echo "FINAL SCORE: $SCORE_TOTAL / $SCORE_MAX"
echo ""

GRADE="F"
if [ "$SCORE_TOTAL" -ge 90 ]; then
  GRADE="A"
elif [ "$SCORE_TOTAL" -ge 80 ]; then
  GRADE="B"
elif [ "$SCORE_TOTAL" -ge 70 ]; then
  GRADE="C"
elif [ "$SCORE_TOTAL" -ge 60 ]; then
  GRADE="D"
fi

echo "Grade: $GRADE"
echo ""

if [ ${#FINDINGS[@]} -gt 0 ]; then
  echo "Findings:"
  for finding in "${FINDINGS[@]}"; do
    echo "  - $finding"
  done
  echo ""
fi

## JSON OUTPUT
if [ "$OUTPUT_JSON" = "--json" ]; then
  cat <<EOF
{
  "file": "$FILE",
  "score": $SCORE_TOTAL,
  "max_score": $SCORE_MAX,
  "grade": "$GRADE",
  "scores": {
    "imperative_language": $SCORE_IMPERATIVE,
    "step_dependencies": $SCORE_STEPS,
    "verification_checkpoints": $SCORE_VERIFICATION,
    "fallback_mechanisms": $SCORE_FALLBACK,
    "critical_requirements": $SCORE_CRITICAL,
    "path_verification": $SCORE_PATH,
    "file_creation": $SCORE_FILE,
    "return_format": $SCORE_RETURN,
    "passive_voice": $SCORE_PASSIVE,
    "error_handling": $SCORE_ERROR
  },
  "findings": [$(printf '"%s",' "${FINDINGS[@]}" | sed 's/,$//')]
}
EOF
fi

exit 0
