#!/usr/bin/env bash
# Hierarchical Agent Support
# Extracted from artifact-operations.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base-utils.sh"
source "${SCRIPT_DIR}/unified-logger.sh"

# Configuration
SUPERVISION_DEPTH=${SUPERVISION_DEPTH:-0}
MAX_SUPERVISION_DEPTH=3

# Functions:

invoke_sub_supervisor() {
  local task_domain="${1:-}"
  local subagent_count="${2:-2}"
  local task_list_json="${3:-[]}"
  local max_words="${4:-100}"

  if [ -z "$task_domain" ]; then
    echo "Usage: invoke_sub_supervisor <task-domain> <subagent-count> <task-list-json> [max-words]" >&2
    return 1
  fi

  # Check depth limit
  SUPERVISION_DEPTH=$((SUPERVISION_DEPTH + 1))
  if [ "$SUPERVISION_DEPTH" -gt "$MAX_SUPERVISION_DEPTH" ]; then
    echo "{\"error\":\"Maximum supervision depth ($MAX_SUPERVISION_DEPTH) exceeded\"}" >&2
    SUPERVISION_DEPTH=$((SUPERVISION_DEPTH - 1))
    return 1
  fi

  # Load sub-supervisor template
  local template_file="${CLAUDE_PROJECT_DIR}/.claude/templates/sub_supervisor_pattern.md"
  if [ ! -f "$template_file" ]; then
    echo "{\"error\":\"Sub-supervisor template not found: $template_file\"}" >&2
    SUPERVISION_DEPTH=$((SUPERVISION_DEPTH - 1))
    return 1
  fi

  # Convert task list JSON to numbered list
  local task_list=""
  if command -v jq &> /dev/null; then
    local idx=1
    while IFS= read -r task; do
      if [ -n "$task" ]; then
        task_list="${task_list}${idx}. ${task}"$'\n'
        idx=$((idx + 1))
      fi
    done < <(echo "$task_list_json" | jq -r '.[] | .task')
  fi

  # Build sub-supervisor prompt from template (use awk to avoid sed multiline issues)
  local sub_supervisor_prompt=$(cat "$template_file" | awk \
    -v n="$subagent_count" \
    -v domain="$task_domain" \
    -v words="$max_words" \
    -v tasks="$task_list" \
    '{
      gsub(/{N}/, n);
      gsub(/{task_domain}/, domain);
      gsub(/{max_words}/, words);
      if (/{task_list}/) {
        sub(/{task_list}/, tasks);
      }
      print
    }')

  # Log sub-supervisor invocation
  local log_dir="${CLAUDE_PROJECT_DIR}/.claude/data/logs"
  mkdir -p "$log_dir"
  local supervision_log="$log_dir/supervision-tree.log"

  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] SUB-SUPERVISOR INVOKED:" >> "$supervision_log"
  echo "  Domain: $task_domain" >> "$supervision_log"
  echo "  Depth: $SUPERVISION_DEPTH" >> "$supervision_log"
  echo "  Subagent Count: $subagent_count" >> "$supervision_log"
  echo "---" >> "$supervision_log"

  # Note: Actual agent invocation must be done by command layer using Task tool
  # This function prepares the prompt and returns invocation metadata

  local invocation_metadata=$(jq -n \
    --arg prompt "$sub_supervisor_prompt" \
    --arg domain "$task_domain" \
    --arg depth "$SUPERVISION_DEPTH" \
    --arg count "$subagent_count" \
    '{
      sub_supervisor_prompt: $prompt,
      task_domain: $domain,
      supervision_depth: ($depth | tonumber),
      subagent_count: ($count | tonumber),
      requires_agent_invocation: true
    }')

  # Decrement depth when returning (will be incremented again if sub-supervisor invokes another)
  SUPERVISION_DEPTH=$((SUPERVISION_DEPTH - 1))

  echo "$invocation_metadata"
}

track_supervision_depth() {
  local operation="${1:-check}"

  case "$operation" in
    increment)
      SUPERVISION_DEPTH=$((SUPERVISION_DEPTH + 1))
      if [ "$SUPERVISION_DEPTH" -gt "$MAX_SUPERVISION_DEPTH" ]; then
        echo "ERROR: Maximum supervision depth ($MAX_SUPERVISION_DEPTH) exceeded" >&2
        SUPERVISION_DEPTH=$((SUPERVISION_DEPTH - 1))
        return 1
      fi
      echo "$SUPERVISION_DEPTH"
      ;;
    decrement)
      if [ "$SUPERVISION_DEPTH" -gt 0 ]; then
        SUPERVISION_DEPTH=$((SUPERVISION_DEPTH - 1))
      fi
      echo "$SUPERVISION_DEPTH"
      ;;
    reset)
      SUPERVISION_DEPTH=0
      echo "$SUPERVISION_DEPTH"
      ;;
    check|get)
      echo "$SUPERVISION_DEPTH"
      ;;
    *)
      echo "Usage: track_supervision_depth <increment|decrement|reset|check|get>" >&2
      return 1
      ;;
  esac
}

generate_supervision_tree() {
  local workflow_state_json="${1:-{}}"

  if [ -z "$workflow_state_json" ] || [ "$workflow_state_json" = "{}" ]; then
    echo "No supervision hierarchy to display"
    return 0
  fi

  # Parse workflow state for supervision structure
  local tree_output="Orchestrator\n"

  if command -v jq &> /dev/null; then
    # Extract supervisor information
    local supervisor_count=$(echo "$workflow_state_json" | jq -r '.supervisors | length' 2>/dev/null | tr -d '\n' || echo "0")
    supervisor_count=${supervisor_count:-0}

    if [ "$supervisor_count" -gt 0 ]; then
      local idx=0
      while [ "$idx" -lt "$supervisor_count" ]; do
        local supervisor_name=$(echo "$workflow_state_json" | jq -r ".supervisors[$idx].name" 2>/dev/null || echo "Unknown")
        local subagent_count=$(echo "$workflow_state_json" | jq ".supervisors[$idx].subagents | length" 2>/dev/null || echo "0")

        # Determine tree connector
        local connector="├──"
        if [ "$idx" -eq $((supervisor_count - 1)) ]; then
          connector="└──"
        fi

        tree_output="${tree_output}${connector} ${supervisor_name} (${subagent_count} subagents)\n"

        # Add subagents
        if [ "$subagent_count" -gt 0 ]; then
          local sub_idx=0
          while [ "$sub_idx" -lt "$subagent_count" ]; do
            local agent_name=$(echo "$workflow_state_json" | jq -r ".supervisors[$idx].subagents[$sub_idx].name" 2>/dev/null || echo "Agent")
            local artifact_path=$(echo "$workflow_state_json" | jq -r ".supervisors[$idx].subagents[$sub_idx].artifact" 2>/dev/null || echo "")

            local sub_connector="│   ├──"
            if [ "$sub_idx" -eq $((subagent_count - 1)) ]; then
              sub_connector="│   └──"
            fi
            if [ "$idx" -eq $((supervisor_count - 1)) ]; then
              sub_connector="    ${sub_connector:4}"
            fi

            tree_output="${tree_output}${sub_connector} ${agent_name}"
            if [ -n "$artifact_path" ] && [ "$artifact_path" != "null" ]; then
              tree_output="${tree_output} → ${artifact_path}\n"
            else
              tree_output="${tree_output}\n"
            fi

            sub_idx=$((sub_idx + 1))
          done
        fi

        idx=$((idx + 1))
      done
    fi
  fi

  echo -e "$tree_output"
}

forward_message() {
  local subagent_output="${1:-}"

  if [ -z "$subagent_output" ]; then
    echo "Usage: forward_message <subagent-output>" >&2
    return 1
  fi

  # Parse subagent output for artifact paths
  local artifact_paths=$(echo "$subagent_output" | grep -oE 'specs/[^[:space:]]+\.md' | sort -u | jq -R -s -c 'split("\n") | map(select(length > 0))')

  # Extract status indicators
  local status="unknown"
  if echo "$subagent_output" | grep -qi 'success\|complete'; then
    status="success"
  elif echo "$subagent_output" | grep -qi 'fail\|error'; then
    status="failed"
  fi

  # Extract metadata blocks (JSON or YAML in code blocks)
  local metadata_blocks=$(echo "$subagent_output" | sed -n '/```json/,/```/p' | grep -v '```' || echo "{}")

  # Build summary (first 100 words of subagent output)
  local summary=$(echo "$subagent_output" | tr '\n' ' ' | awk '{for(i=1;i<=100 && i<=NF;i++) printf "%s ", $i}')

  # Build structured handoff
  local handoff_context=""
  if command -v jq &> /dev/null && [ -n "$artifact_paths" ] && [ "$artifact_paths" != "[]" ]; then
    # Extract metadata for each artifact
    local artifacts_with_metadata="[]"
    while IFS= read -r artifact_path; do
      if [ -f "$artifact_path" ]; then
        local metadata=$(load_metadata_on_demand "$artifact_path" 2>/dev/null || echo '{"error":"metadata_unavailable"}')
        # Only add if metadata is valid JSON
        if echo "$metadata" | jq -e . >/dev/null 2>&1; then
          artifacts_with_metadata=$(echo "$artifacts_with_metadata" | jq \
            --arg path "$artifact_path" \
            --argjson meta "$metadata" \
            '. += [{path: $path, metadata: $meta}]')
        else
          # Add with minimal metadata if extraction failed
          artifacts_with_metadata=$(echo "$artifacts_with_metadata" | jq \
            --arg path "$artifact_path" \
            '. += [{path: $path, metadata: {}}]')
        fi
      fi
    done < <(echo "$artifact_paths" | jq -r '.[]')

    handoff_context=$(jq -n \
      --arg phase "unknown" \
      --argjson artifacts "$artifacts_with_metadata" \
      --arg summary "${summary% }" \
      --arg status "$status" \
      '{
        phase_complete: $phase,
        artifacts: $artifacts,
        summary: $summary,
        status: $status,
        next_phase_reads: ($artifacts | map(.path))
      }')
  else
    # Fallback without artifact metadata
    handoff_context=$(jq -n \
      --arg summary "$(echo "$subagent_output" | tr '\n' ' ' | head -c 200)" \
      --arg status "$status" \
      '{
        phase_complete: "unknown",
        artifacts: [],
        summary: $summary,
        status: $status,
        next_phase_reads: []
      }')
  fi

  # Log original subagent output
  local log_dir="${CLAUDE_PROJECT_DIR}/.claude/data/logs"
  mkdir -p "$log_dir"
  local log_file="$log_dir/subagent-outputs.log"

  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] SUBAGENT OUTPUT:" >> "$log_file"
  echo "$subagent_output" >> "$log_file"
  echo "---" >> "$log_file"

  # Log handoff context
  local handoff_log="$log_dir/phase-handoffs.log"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] PHASE HANDOFF:" >> "$handoff_log"
  echo "$handoff_context" | jq '.' >> "$handoff_log" 2>/dev/null || echo "$handoff_context" >> "$handoff_log"
  echo "---" >> "$handoff_log"

  # Enable log rotation (10MB max, 5 files)
  for log in "$log_file" "$handoff_log"; do
    if [ -f "$log" ] && [ $(wc -c < "$log") -gt 10485760 ]; then
      # Rotate logs
      for i in {4..1}; do
        [ -f "${log}.$i" ] && mv "${log}.$i" "${log}.$((i+1))"
      done
      mv "$log" "${log}.1"
      touch "$log"
    fi
  done

  echo "$handoff_context"
}

parse_subagent_response() {
  local subagent_output="${1:-}"

  if [ -z "$subagent_output" ]; then
    echo "Usage: parse_subagent_response <subagent-output>" >&2
    return 1
  fi

  # Extract artifact paths (markdown files in specs/)
  local artifact_paths=$(echo "$subagent_output" | grep -oE 'specs/[^[:space:]]+\.md' | sort -u | jq -R -s -c 'split("\n") | map(select(length > 0))')

  # Extract status indicators
  local status="unknown"
  if echo "$subagent_output" | grep -qi 'success\|complete\|done'; then
    status="success"
  elif echo "$subagent_output" | grep -qi 'fail\|error'; then
    status="failed"
  elif echo "$subagent_output" | grep -qi 'in progress\|working'; then
    status="in_progress"
  fi

  # Extract JSON metadata blocks
  local metadata_blocks=$(echo "$subagent_output" | sed -n '/```json/,/```/p' | sed '1d;$d' || echo "{}")

  # Build response object
  if command -v jq &> /dev/null; then
    jq -n \
      --argjson paths "${artifact_paths:-[]}" \
      --arg status "$status" \
      --argjson meta "${metadata_blocks:-{}}" \
      '{
        artifact_paths: $paths,
        status: $status,
        metadata: $meta
      }'
  else
    cat <<EOF
{
  "artifact_paths": ${artifact_paths:-[]},
  "status": "$status",
  "metadata": ${metadata_blocks:-{}}
}
EOF
  fi
}

build_handoff_context() {
  local phase_name="${1:-unknown}"
  local artifacts_json="${2:-[]}"
  local summary="${3:-No summary provided}"

  # Limit summary to 100 words
  local summary_limited=$(echo "$summary" | tr '\n' ' ' | awk '{for(i=1;i<=100 && i<=NF;i++) printf "%s ", $i}')

  if command -v jq &> /dev/null; then
    jq -n \
      --arg phase "$phase_name" \
      --argjson artifacts "$artifacts_json" \
      --arg summary "${summary_limited% }" \
      '{
        phase_complete: $phase,
        artifacts: $artifacts,
        summary: $summary,
        next_phase_reads: ($artifacts | map(.path))
      }'
  else
    cat <<EOF
{
  "phase_complete": "$phase_name",
  "artifacts": $artifacts_json,
  "summary": "${summary_limited% }",
  "next_phase_reads": []
}
EOF
  fi
}

# Export functions
export -f invoke_sub_supervisor
export -f track_supervision_depth
export -f generate_supervision_tree
export -f forward_message
export -f parse_subagent_response
export -f build_handoff_context