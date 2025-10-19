#!/usr/bin/env bash
# Metadata Extraction
# Extracted from artifact-operations.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base-utils.sh"
source "${SCRIPT_DIR}/unified-logger.sh"

# Functions:

extract_report_metadata() {
  local report_path="${1:-}"

  if [ -z "$report_path" ]; then
    echo "Usage: extract_report_metadata <report-path>" >&2
    return 1
  fi

  if [ ! -f "$report_path" ]; then
    echo "{\"error\":\"File not found: $report_path\"}" >&2
    return 1
  fi

  # Extract title (first # heading)
  local title=$(head -100 "$report_path" | grep -m1 '^# ' | sed 's/^# //')

  # Extract 50-word summary from Executive Summary section or first paragraph
  local summary=""
  local exec_summary_section=$(get_report_section "$report_path" "Executive Summary" 2>/dev/null || echo "")

  if [ -n "$exec_summary_section" ]; then
    # Extract first paragraph from executive summary (non-heading, non-empty lines)
    summary=$(echo "$exec_summary_section" | grep -v '^#' | grep -v '^$' | head -5 | tr '\n' ' ' | awk '{for(i=1;i<=50 && i<=NF;i++) printf "%s ", $i}')
  else
    # Fallback: first 50 words from content after title
    summary=$(head -200 "$report_path" | grep -v '^#' | grep -v '^-' | grep -v '^$' | head -5 | tr '\n' ' ' | awk '{for(i=1;i<=50 && i<=NF;i++) printf "%s ", $i}')
  fi

  # Extract key file paths mentioned (look for code blocks and inline code with paths)
  local file_paths=$(grep -E '`[^`]*\.(sh|md|js|py|lua|rs|go|java|rb)`|```.*\.(sh|md|js|py|lua|rs|go|java|rb)' "$report_path" | \
    grep -oE '[a-zA-Z0-9_/-]+\.(sh|md|js|py|lua|rs|go|java|rb)' | head -10 | jq -R -s -c 'split("\n") | map(select(length > 0))')

  # Extract 3-5 top recommendations (from Recommendations section)
  local recommendations=""
  local rec_section=$(get_report_section "$report_path" "Recommendations" 2>/dev/null || echo "")

  if [ -n "$rec_section" ]; then
    recommendations=$(echo "$rec_section" | grep '^-' | head -5 | sed 's/^- //' | jq -R -s -c 'split("\n") | map(select(length > 0))')
  else
    recommendations="[]"
  fi

  # Get file size
  local file_size=$(wc -c < "$report_path" | tr -d ' ')

  # Build JSON
  if command -v jq &> /dev/null; then
    jq -n \
      --arg title "${title:-Unknown Report}" \
      --arg summary "${summary% }" \
      --argjson paths "${file_paths:-[]}" \
      --argjson recs "${recommendations}" \
      --arg path "$report_path" \
      --arg size "$file_size" \
      '{
        title: $title,
        summary: $summary,
        file_paths: $paths,
        recommendations: $recs,
        path: $path,
        size: ($size | tonumber)
      }'
  else
    cat <<EOF
{
  "title": "${title:-Unknown Report}",
  "summary": "${summary% }",
  "file_paths": ${file_paths:-[]},
  "recommendations": ${recommendations},
  "path": "$report_path",
  "size": $file_size
}
EOF
  fi
}

extract_plan_metadata() {
  local plan_path="${1:-}"

  if [ -z "$plan_path" ]; then
    echo "Usage: extract_plan_metadata <plan-path>" >&2
    return 1
  fi

  if [ ! -f "$plan_path" ]; then
    echo "{\"error\":\"File not found: $plan_path\"}" >&2
    return 1
  fi

  # Read metadata section (first 50 lines)
  local metadata_lines=$(head -50 "$plan_path")

  # Extract title (first # heading)
  local title=$(echo "$metadata_lines" | grep -m1 '^# ' | sed 's/^# //')

  # Extract date from metadata
  local date=$(echo "$metadata_lines" | grep -m1 '^\s*-\s*\*\*Date\*\*:' | sed 's/.*Date\*\*:\s*//')

  # Count phases
  local phases=$(grep -E '^##+ Phase [0-9]' "$plan_path" 2>/dev/null | wc -l)
  phases=${phases// /}

  # Extract complexity assessment (from Risk field in phases or overall complexity)
  local complexity="Unknown"
  local risk_line=$(grep -m1 '^\*\*Risk\*\*:' "$plan_path" || echo "")
  if [ -n "$risk_line" ]; then
    complexity=$(echo "$risk_line" | sed 's/.*Risk\*\*:\s*//' | awk '{print $1}')
  fi

  # Extract estimated time (from Estimated Time or Estimated Phases metadata)
  local time_estimate=$(echo "$metadata_lines" | grep -m1 '^\s*-\s*\*\*Estimated.*\*\*:' | sed 's/.*Estimated.*\*\*:\s*//')

  # Count success criteria checkboxes
  local success_criteria=$(grep -c '^\s*-\s*\[[ x]\]' "$plan_path" || echo "0")

  # Get file size
  local file_size=$(wc -c < "$plan_path" | tr -d ' ')

  # Build JSON
  if command -v jq &> /dev/null; then
    jq -n \
      --arg title "${title:-Unknown Plan}" \
      --arg date "${date:-Unknown}" \
      --arg phases "$phases" \
      --arg complexity "$complexity" \
      --arg time "${time_estimate:-Unknown}" \
      --arg criteria "$success_criteria" \
      --arg path "$plan_path" \
      --arg size "$file_size" \
      '{
        title: $title,
        date: $date,
        phases: ($phases | tonumber),
        complexity: $complexity,
        time_estimate: $time,
        success_criteria: ($criteria | tonumber),
        path: $path,
        size: ($size | tonumber)
      }'
  else
    cat <<EOF
{
  "title": "${title:-Unknown Plan}",
  "date": "${date:-Unknown}",
  "phases": $phases,
  "complexity": "$complexity",
  "time_estimate": "${time_estimate:-Unknown}",
  "success_criteria": $success_criteria,
  "path": "$plan_path",
  "size": $file_size
}
EOF
  fi
}

extract_summary_metadata() {
  local summary_path="${1:-}"

  if [ -z "$summary_path" ]; then
    echo "Usage: extract_summary_metadata <summary-path>" >&2
    return 1
  fi

  if [ ! -f "$summary_path" ]; then
    echo "{\"error\":\"File not found: $summary_path\"}" >&2
    return 1
  fi

  # Read first 100 lines for metadata
  local content=$(head -100 "$summary_path")

  # Extract workflow type (from Metadata or title)
  local workflow_type="Unknown"
  local workflow_line=$(echo "$content" | grep -m1 '^\s*-\s*\*\*Workflow\*\*:' || echo "")
  if [ -n "$workflow_line" ]; then
    workflow_type=$(echo "$workflow_line" | sed 's/.*Workflow\*\*:\s*//')
  fi

  # Count artifacts generated (plans, reports, debug reports mentioned)
  local artifacts_count=$(grep -cE '(specs/.*\.md|Created.*:.*specs/)' "$summary_path" || echo "0")

  # Extract test status
  local tests_passing="Unknown"
  local test_line=$(echo "$content" | grep -m1 -i 'test.*pass\|pass.*test\|all tests' || echo "")
  if echo "$test_line" | grep -qi 'pass'; then
    tests_passing="true"
  elif echo "$test_line" | grep -qi 'fail'; then
    tests_passing="false"
  fi

  # Extract performance metrics (time saved, parallel effectiveness)
  local performance="Unknown"
  local perf_line=$(echo "$content" | grep -m1 -iE 'time saved|performance|parallel.*%|reduction.*%' || echo "")
  if [ -n "$perf_line" ]; then
    performance=$(echo "$perf_line" | sed 's/^[^:]*:\s*//' | head -c 100)
  fi

  # Get file size
  local file_size=$(wc -c < "$summary_path" | tr -d ' ')

  # Build JSON
  if command -v jq &> /dev/null; then
    jq -n \
      --arg type "$workflow_type" \
      --arg count "$artifacts_count" \
      --arg tests "$tests_passing" \
      --arg perf "$performance" \
      --arg path "$summary_path" \
      --arg size "$file_size" \
      '{
        workflow_type: $type,
        artifacts_count: ($count | tonumber),
        tests_passing: $tests,
        performance: $perf,
        path: $path,
        size: ($size | tonumber)
      }'
  else
    cat <<EOF
{
  "workflow_type": "$workflow_type",
  "artifacts_count": $artifacts_count,
  "tests_passing": "$tests_passing",
  "performance": "$performance",
  "path": "$summary_path",
  "size": $file_size
}
EOF
  fi
}

load_metadata_on_demand() {
  local artifact_path="${1:-}"

  if [ -z "$artifact_path" ]; then
    echo "Usage: load_metadata_on_demand <artifact-path>" >&2
    return 1
  fi

  # Check cache first
  local cached=$(get_cached_metadata "$artifact_path")
  if [ -n "$cached" ]; then
    echo "$cached"
    return 0
  fi

  # Determine artifact type from path
  local artifact_type="unknown"
  if [[ "$artifact_path" == */reports/* ]]; then
    artifact_type="report"
  elif [[ "$artifact_path" == */plans/* ]]; then
    artifact_type="plan"
  elif [[ "$artifact_path" == */summaries/* ]]; then
    artifact_type="summary"
  fi

  # Extract metadata based on type
  local metadata=""
  case "$artifact_type" in
    report)
      metadata=$(extract_report_metadata "$artifact_path")
      ;;
    plan)
      metadata=$(extract_plan_metadata "$artifact_path")
      ;;
    summary)
      metadata=$(extract_summary_metadata "$artifact_path")
      ;;
    *)
      echo "{\"error\":\"Unknown artifact type for: $artifact_path\"}" >&2
      return 1
      ;;
  esac

  # Cache metadata
  if [ -n "$metadata" ]; then
    cache_metadata "$artifact_path" "$metadata"
  fi

  echo "$metadata"
}

cache_metadata() {
  local artifact_path="${1:-}"
  local metadata_json="${2:-}"

  if [ -z "$artifact_path" ] || [ -z "$metadata_json" ]; then
    return 1
  fi

  METADATA_CACHE["$artifact_path"]="$metadata_json"
  return 0
}

get_cached_metadata() {
  local artifact_path="${1:-}"

  if [ -z "$artifact_path" ]; then
    return 1
  fi

  echo "${METADATA_CACHE[$artifact_path]:-}"
}

clear_metadata_cache() {
  METADATA_CACHE=()
  return 0
}

get_plan_metadata() {
  local plan_path="${1:-}"

  if [ -z "$plan_path" ]; then
    echo "Usage: get_plan_metadata <plan-path>" >&2
    return 1
  fi

  if [ ! -f "$plan_path" ]; then
    echo "{\"error\":\"File not found: $plan_path\"}" >&2
    return 1
  fi

  # Read only first 50 lines (metadata section)
  local metadata_lines=$(head -50 "$plan_path")

  # Extract title (first # heading)
  local title=$(echo "$metadata_lines" | grep -m1 '^# ' | sed 's/^# //')

  # Extract date from metadata (- **Date**: ...)
  local date=$(echo "$metadata_lines" | grep -m1 '^\s*-\s*\*\*Date\*\*:' | sed 's/.*Date\*\*:\s*//')

  # Extract standards file reference
  local standards_file=$(echo "$metadata_lines" | grep -m1 '^\s*-\s*\*\*Standards File\*\*:' | sed 's/.*Standards File\*\*:\s*//')

  # Count phases in full file (### Phase N: or ## Phase N: pattern)
  local phases=$(grep -E '^##+ Phase [0-9]' "$plan_path" 2>/dev/null | wc -l)
  phases=${phases// /}  # Remove whitespace

  # Build JSON (handle jq availability)
  if command -v jq &> /dev/null; then
    jq -n \
      --arg title "${title:-Unknown Plan}" \
      --arg date "${date:-Unknown}" \
      --arg phases "$phases" \
      --arg standards "${standards_file:-None}" \
      --arg path "$plan_path" \
      '{
        title: $title,
        date: $date,
        phases: ($phases | tonumber),
        standards_file: $standards,
        path: $path
      }'
  else
    cat <<EOF
{
  "title": "${title:-Unknown Plan}",
  "date": "${date:-Unknown}",
  "phases": $phases,
  "standards_file": "${standards_file:-None}",
  "path": "$plan_path"
}
EOF
  fi
}

get_report_metadata() {
  local report_path="${1:-}"

  if [ -z "$report_path" ]; then
    echo "Usage: get_report_metadata <report-path>" >&2
    return 1
  fi

  if [ ! -f "$report_path" ]; then
    echo "{\"error\":\"File not found: $report_path\"}" >&2
    return 1
  fi

  # Read only first 100 lines (metadata + exec summary section)
  local metadata_lines=$(head -100 "$report_path")

  # Extract title (first # heading)
  local title=$(echo "$metadata_lines" | grep -m1 '^# ' | sed 's/^# //')

  # Extract date from metadata
  local date=$(echo "$metadata_lines" | grep -m1 '^\s*-\s*\*\*Date\*\*:' | sed 's/.*Date\*\*:\s*//')

  # Extract research question count
  local question_count=$(echo "$metadata_lines" | grep -c '^\s*[0-9]\+\.\s' || echo "0")

  # Build JSON
  if command -v jq &> /dev/null; then
    jq -n \
      --arg title "${title:-Unknown Report}" \
      --arg date "${date:-Unknown}" \
      --arg questions "$question_count" \
      --arg path "$report_path" \
      '{
        title: $title,
        date: $date,
        research_questions: ($questions | tonumber),
        path: $path
      }'
  else
    cat <<EOF
{
  "title": "${title:-Unknown Report}",
  "date": "${date:-Unknown}",
  "research_questions": $question_count,
  "path": "$report_path"
}
EOF
  fi
}

get_plan_phase() {
  local plan_path="${1:-}"
  local phase_num="${2:-}"

  if [ -z "$plan_path" ] || [ -z "$phase_num" ]; then
    echo "Usage: get_plan_phase <plan-path> <phase-number>" >&2
    return 1
  fi

  if [ ! -f "$plan_path" ]; then
    echo "Error: File not found: $plan_path" >&2
    return 1
  fi

  # Find line number of phase heading (supports both ## and ### levels)
  local start_line=$(grep -nE "^##+ Phase $phase_num:" "$plan_path" | cut -d: -f1 | head -1)

  if [ -z "$start_line" ]; then
    echo "Error: Phase $phase_num not found in $plan_path" >&2
    return 1
  fi

  # Find line number of next phase or end of file
  local next_phase=$((phase_num + 1))
  local end_line=$(grep -nE "^##+ Phase $next_phase:" "$plan_path" | cut -d: -f1 | head -1)

  # Extract phase content
  if [ -n "$end_line" ]; then
    sed -n "${start_line},$((end_line - 1))p" "$plan_path"
  else
    sed -n "${start_line},\$p" "$plan_path"
  fi
}

get_plan_section() {
  local plan_path="${1:-}"
  local section_pattern="${2:-}"

  if [ -z "$plan_path" ] || [ -z "$section_pattern" ]; then
    echo "Usage: get_plan_section <plan-path> <section-heading>" >&2
    return 1
  fi

  if [ ! -f "$plan_path" ]; then
    echo "Error: File not found: $plan_path" >&2
    return 1
  fi

  # Find line number of section heading (## pattern)
  local start_line=$(grep -n "^## .*$section_pattern" "$plan_path" | cut -d: -f1 | head -1)

  if [ -z "$start_line" ]; then
    echo "Error: Section '$section_pattern' not found in $plan_path" >&2
    return 1
  fi

  # Find line number of next ## heading or end of file
  local end_line=$(awk "NR>$start_line && /^## / {print NR; exit}" "$plan_path")

  # Extract section content
  if [ -n "$end_line" ]; then
    sed -n "${start_line},$((end_line - 1))p" "$plan_path"
  else
    sed -n "${start_line},\$p" "$plan_path"
  fi
}

get_report_section() {
  local report_path="${1:-}"
  local section_pattern="${2:-}"

  if [ -z "$report_path" ] || [ -z "$section_pattern" ]; then
    echo "Usage: get_report_section <report-path> <section-heading>" >&2
    return 1
  fi

  if [ ! -f "$report_path" ]; then
    echo "Error: File not found: $report_path" >&2
    return 1
  fi

  # Find line number of section heading (## pattern)
  local start_line=$(grep -n "^## .*$section_pattern" "$report_path" | cut -d: -f1 | head -1)

  if [ -z "$start_line" ]; then
    echo "Error: Section '$section_pattern' not found in $report_path" >&2
    return 1
  fi

  # Find line number of next ## heading or end of file
  local end_line=$(awk "NR>$start_line && /^## / {print NR; exit}" "$report_path")

  # Extract section content
  if [ -n "$end_line" ]; then
    sed -n "${start_line},$((end_line - 1))p" "$report_path"
  else
    sed -n "${start_line},\$p" "$report_path"
  fi
}

# Export functions
export -f extract_report_metadata
export -f extract_plan_metadata
export -f extract_summary_metadata
export -f load_metadata_on_demand
export -f cache_metadata
export -f get_cached_metadata
export -f clear_metadata_cache
export -f get_plan_metadata
export -f get_report_metadata
export -f get_plan_phase
export -f get_plan_section
export -f get_report_section