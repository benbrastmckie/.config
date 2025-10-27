#!/bin/bash
# Audit imperative language usage in command files
# Target: ≥90% imperative ratio

FILE="${1:-.claude/commands/research.md}"

if [ ! -f "$FILE" ]; then
  echo "Error: File not found: $FILE"
  exit 1
fi

echo "========================================="
echo "Imperative Language Audit"
echo "========================================="
echo "File: $FILE"
echo ""

# Count imperative markers
MUST_COUNT=$(grep -iow "MUST" "$FILE" | wc -l)
WILL_COUNT=$(grep -iow "WILL" "$FILE" | wc -l)
SHALL_COUNT=$(grep -iow "SHALL" "$FILE" | wc -l)
REQUIRED_COUNT=$(grep -iow "REQUIRED" "$FILE" | wc -l)
MANDATORY_COUNT=$(grep -iow "MANDATORY" "$FILE" | wc -l)
EXECUTE_COUNT=$(grep -i "EXECUTE NOW" "$FILE" | wc -l)
CRITICAL_COUNT=$(grep -iow "CRITICAL" "$FILE" | wc -l)

IMPERATIVE_TOTAL=$((MUST_COUNT + WILL_COUNT + SHALL_COUNT + REQUIRED_COUNT + MANDATORY_COUNT + EXECUTE_COUNT + CRITICAL_COUNT))

# Count weak language
SHOULD_COUNT=$(grep -iow "should" "$FILE" | wc -l)
MAY_COUNT=$(grep -iow "may" "$FILE" | wc -l)
CAN_COUNT=$(grep -iow "can" "$FILE" | wc -l)
COULD_COUNT=$(grep -iow "could" "$FILE" | wc -l)
ILL_COUNT=$(grep -o "I'll" "$FILE" | wc -l)
LETME_COUNT=$(grep -o "Let me" "$FILE" | wc -l)

WEAK_TOTAL=$((SHOULD_COUNT + MAY_COUNT + CAN_COUNT + COULD_COUNT + ILL_COUNT + LETME_COUNT))

echo "Imperative Language Instances:"
echo "  MUST: $MUST_COUNT"
echo "  WILL: $WILL_COUNT"
echo "  SHALL: $SHALL_COUNT"
echo "  REQUIRED: $REQUIRED_COUNT"
echo "  MANDATORY: $MANDATORY_COUNT"
echo "  EXECUTE NOW: $EXECUTE_COUNT"
echo "  CRITICAL: $CRITICAL_COUNT"
echo "  ─────────────"
echo "  Total: $IMPERATIVE_TOTAL"
echo ""

echo "Weak Language Instances:"
echo "  should: $SHOULD_COUNT"
echo "  may: $MAY_COUNT"
echo "  can: $CAN_COUNT"
echo "  could: $COULD_COUNT"
echo "  I'll: $ILL_COUNT"
echo "  Let me: $LETME_COUNT"
echo "  ─────────────"
echo "  Total: $WEAK_TOTAL"
echo ""

# Calculate ratio
TOTAL=$((IMPERATIVE_TOTAL + WEAK_TOTAL))
if [ $TOTAL -eq 0 ]; then
  RATIO=0
else
  RATIO=$(awk "BEGIN {printf \"%.1f\", ($IMPERATIVE_TOTAL / $TOTAL) * 100}")
fi

echo "========================================="
echo "Imperative Ratio: ${RATIO}%"
echo "Target: ≥90%"

if [ $(echo "$RATIO >= 90" | bc -l 2>/dev/null || echo 0) -eq 1 ]; then
  echo "Status: ✓ PASS"
else
  echo "Status: ✗ NEEDS IMPROVEMENT"
  NEEDED=$((TOTAL * 90 / 100 - IMPERATIVE_TOTAL))
  echo "Need $NEEDED more imperative instances or remove $((WEAK_TOTAL - (TOTAL * 10 / 100))) weak instances"
fi
echo "========================================="
