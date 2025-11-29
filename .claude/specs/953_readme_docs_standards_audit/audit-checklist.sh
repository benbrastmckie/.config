#!/bin/bash
# audit-checklist.sh - Comprehensive README compliance audit

set -uo pipefail

CLAUDE_DIR="/home/benjamin/.config/.claude"
AUDIT_LOG="$CLAUDE_DIR/specs/953_readme_docs_standards_audit/outputs/audit-results.log"

mkdir -p "$(dirname "$AUDIT_LOG")"

echo "README Compliance Audit - $(date)" > "$AUDIT_LOG"
echo "======================================" >> "$AUDIT_LOG"
echo "" >> "$AUDIT_LOG"

# Find all READMEs
readmes=$(find "$CLAUDE_DIR" -name "README.md" -type f | grep -v archive/ | sort)

total=0
compliant=0
issues=0

for readme in $readmes; do
  ((total++))
  readme_issues=0

  echo "Auditing: ${readme#$CLAUDE_DIR/}" >> "$AUDIT_LOG"

  # Check template compliance
  if ! grep -q "^## Purpose" "$readme"; then
    echo "  ❌ Missing Purpose section" >> "$AUDIT_LOG"
    ((readme_issues++))
  fi

  if ! grep -q "^## Navigation" "$readme"; then
    echo "  ❌ Missing Navigation section" >> "$AUDIT_LOG"
    ((readme_issues++))
  fi

  # Check timeless writing
  if grep -qiE "recent|new|updated|migration" "$readme" 2>/dev/null; then
    matches=$(grep -niE "recent|new|updated|migration" "$readme" | head -3)
    echo "  ⚠️  Potential temporal markers found:" >> "$AUDIT_LOG"
    echo "$matches" | sed 's/^/     /' >> "$AUDIT_LOG"
    ((readme_issues++))
  fi

  # Check for emojis (should be none)
  if grep -qP '[\x{1F600}-\x{1F64F}]' "$readme" 2>/dev/null; then
    echo "  ❌ Emojis found (UTF-8 encoding issues)" >> "$AUDIT_LOG"
    ((readme_issues++))
  fi

  if [ $readme_issues -eq 0 ]; then
    echo "  ✓ Compliant" >> "$AUDIT_LOG"
    ((compliant++))
  else
    ((issues += readme_issues))
  fi

  echo "" >> "$AUDIT_LOG"
done

echo "======================================" >> "$AUDIT_LOG"
echo "Audit Summary:" >> "$AUDIT_LOG"
echo "  Total READMEs: $total" >> "$AUDIT_LOG"
echo "  Compliant: $compliant" >> "$AUDIT_LOG"
echo "  READMEs with issues: $((total - compliant))" >> "$AUDIT_LOG"
echo "  Total issues: $issues" >> "$AUDIT_LOG"
echo "  Compliance rate: $(( compliant * 100 / total ))%" >> "$AUDIT_LOG"
echo "======================================" >> "$AUDIT_LOG"
echo "Audit complete: $(date)" >> "$AUDIT_LOG"

# Also print summary to stdout
echo "Audit complete. Results written to: $AUDIT_LOG"
echo ""
echo "Summary:"
echo "  Total READMEs: $total"
echo "  Compliant: $compliant"
echo "  Compliance rate: $(( compliant * 100 / total ))%"
