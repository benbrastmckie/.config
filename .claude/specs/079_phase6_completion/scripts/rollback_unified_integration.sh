#!/usr/bin/env bash
# rollback_unified_integration.sh
# Restore commands to pre-integration state

set -euo pipefail

COMMAND="${1:-all}"  # all, report, research, plan, orchestrate

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
COMMANDS_DIR="${PROJECT_ROOT}/.claude/commands"

echo "=========================================="
echo "Rollback: Unified Location Integration"
echo "=========================================="
echo ""

rollback_report() {
  echo "Rolling back /report command..."
  if [ -f "${COMMANDS_DIR}/report.md.backup-unified-integration" ]; then
    cp "${COMMANDS_DIR}/report.md.backup-unified-integration" "${COMMANDS_DIR}/report.md"
    echo "✓ /report restored from backup"
    return 0
  else
    echo "✗ ERROR: Backup not found for /report"
    return 1
  fi
}

rollback_research() {
  echo "Rolling back /research command..."
  if [ -f "${COMMANDS_DIR}/research.md.backup-unified-integration" ]; then
    cp "${COMMANDS_DIR}/research.md.backup-unified-integration" "${COMMANDS_DIR}/research.md"
    echo "✓ /research restored from backup"
    return 0
  else
    echo "✗ ERROR: Backup not found for /research"
    return 1
  fi
}

rollback_plan() {
  echo "Rolling back /plan command..."
  if [ -f "${COMMANDS_DIR}/plan.md.backup-unified-integration" ]; then
    cp "${COMMANDS_DIR}/plan.md.backup-unified-integration" "${COMMANDS_DIR}/plan.md"
    echo "✓ /plan restored from backup"
    return 0
  else
    echo "✗ ERROR: Backup not found for /plan"
    return 1
  fi
}

rollback_orchestrate() {
  echo "Rolling back /orchestrate command..."
  if [ -f "${COMMANDS_DIR}/orchestrate.md.backup-unified-integration" ]; then
    cp "${COMMANDS_DIR}/orchestrate.md.backup-unified-integration" "${COMMANDS_DIR}/orchestrate.md"
    echo "✓ /orchestrate restored from backup"
    return 0
  else
    echo "✗ ERROR: Backup not found for /orchestrate"
    return 1
  fi
}

case "$COMMAND" in
  report)
    rollback_report
    ;;
  research)
    rollback_research
    ;;
  plan)
    rollback_plan
    ;;
  orchestrate)
    rollback_orchestrate
    ;;
  all)
    FAILED=0
    rollback_report || FAILED=$((FAILED + 1))
    rollback_research || FAILED=$((FAILED + 1))
    rollback_plan || FAILED=$((FAILED + 1))
    rollback_orchestrate || FAILED=$((FAILED + 1))

    if [ $FAILED -gt 0 ]; then
      echo ""
      echo "✗ $FAILED command(s) failed to rollback"
      exit 1
    fi
    ;;
  *)
    echo "Usage: $0 {report|research|plan|orchestrate|all}"
    exit 1
    ;;
esac

echo ""
echo "Rollback complete. Verify with:"
echo "  ${PROJECT_ROOT}/.claude/tests/test_system_wide_location.sh"
echo ""
echo "NOTE: /supervise command was already optimized in earlier phases"
echo "      and does not need rollback as part of this integration."
