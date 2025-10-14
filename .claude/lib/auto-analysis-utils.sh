#!/usr/bin/env bash
# auto-analysis-utils.sh
# Main entry point for auto-analysis utilities
# Sources modular components for complexity estimator agent orchestration

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source core modules
source "$SCRIPT_DIR/agent-invocation.sh"
source "$SCRIPT_DIR/phase-analysis.sh"
source "$SCRIPT_DIR/stage-analysis.sh"
source "$SCRIPT_DIR/artifact-management.sh"

# ============================================================================
# Main (for testing)
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "auto-analysis-utils.sh: Library for complexity estimator agent orchestration"
  echo "Source this file to use its functions"
  echo ""
  echo "Modules loaded:"
  echo "  - agent-invocation.sh (agent prompting)"
  echo "  - phase-analysis.sh (phase expansion/collapse analysis)"
  echo "  - stage-analysis.sh (stage expansion/collapse analysis)"
  echo "  - artifact-management.sh (reporting, registry, parallel execution, hierarchy review)"
  echo ""
  echo "Available functions:"
  echo "  Agent Invocation:"
  echo "    - invoke_complexity_estimator <mode> <content_json> <context_json>"
  echo ""
  echo "  Phase Analysis:"
  echo "    - analyze_phases_for_expansion <plan_path>"
  echo "    - analyze_phases_for_collapse <plan_path>"
  echo ""
  echo "  Stage Analysis:"
  echo "    - analyze_stages_for_expansion <plan_path> <phase_num>"
  echo "    - analyze_stages_for_collapse <plan_path> <phase_num>"
  echo ""
  echo "  Reporting & Artifacts:"
  echo "    - generate_analysis_report <mode> <decisions_json> <plan_path>"
  echo "    - register_operation_artifact <plan_path> <operation_type> <item_id> <artifact_path>"
  echo "    - get_artifact_path <plan_path> <item_id>"
  echo "    - validate_operation_artifacts <plan_path>"
  echo ""
  echo "  Parallel Execution:"
  echo "    - invoke_expansion_agents_parallel <plan_path> <recommendations_json>"
  echo "    - aggregate_expansion_artifacts <plan_path> <artifact_refs_json>"
  echo "    - coordinate_metadata_updates <plan_path> <aggregation_json>"
  echo "    - invoke_collapse_agents_parallel <plan_path> <recommendations_json>"
  echo "    - aggregate_collapse_artifacts <plan_path> <artifact_refs_json>"
  echo "    - coordinate_collapse_metadata_updates <plan_path> <aggregation_json>"
  echo ""
  echo "  Hierarchy Review:"
  echo "    - review_plan_hierarchy <plan_path> <operation_summary_json>"
  echo "    - run_second_round_analysis <plan_path> <initial_analysis_json>"
  echo "    - present_recommendations_for_approval <recommendations_json> <context>"
  echo "    - generate_recommendations_report <plan_path> <hierarchy_json> <second_round_json> <operations_json>"
fi
