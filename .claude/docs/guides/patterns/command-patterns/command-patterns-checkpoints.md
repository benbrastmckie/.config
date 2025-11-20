# Command Patterns: Checkpoints and Error Handling

**Related Documents**:
- [Overview](command-patterns-overview.md) - Pattern index
- [Agent Patterns](command-patterns-agents.md) - Agent invocation
- [Integration](command-patterns-integration.md) - Testing and PR

---

## Checkpoint Management

### Checkpoint Save Pattern

```bash
save_workflow_checkpoint() {
  local workflow="$1"

  CHECKPOINT=$(cat <<EOF
{
  "workflow_id": "$(uuidgen)",
  "phase": "$CURRENT_PHASE",
  "plan_path": "$PLAN_PATH",
  "completed_phases": $(printf '%s\n' "${COMPLETED[@]}" | jq -R . | jq -s .),
  "created_at": "$(date -Iseconds)",
  "updated_at": "$(date -Iseconds)"
}
EOF
  )

  save_checkpoint "$workflow" "$CHECKPOINT"
}
```

### Checkpoint Load Pattern

```bash
load_workflow_checkpoint() {
  local workflow="$1"

  if CHECKPOINT=$(load_checkpoint "$workflow"); then
    CURRENT_PHASE=$(echo "$CHECKPOINT" | jq -r '.phase')
    PLAN_PATH=$(echo "$CHECKPOINT" | jq -r '.plan_path')
    readarray -t COMPLETED < <(echo "$CHECKPOINT" | jq -r '.completed_phases[]')
    return 0
  fi

  return 1
}
```

### Resume Pattern

```bash
resume_or_start() {
  local workflow="$1"

  if load_workflow_checkpoint "$workflow"; then
    echo "Resuming from: $CURRENT_PHASE"
    return 0
  else
    echo "Starting fresh"
    initialize_workflow
    return 1
  fi
}
```

### Checkpoint Update Pattern

```bash
update_checkpoint() {
  local workflow="$1"
  local key="$2"
  local value="$3"

  CHECKPOINT=$(load_checkpoint "$workflow")
  CHECKPOINT=$(echo "$CHECKPOINT" | jq --arg k "$key" --arg v "$value" '.[$k] = $v')
  CHECKPOINT=$(echo "$CHECKPOINT" | jq --arg t "$(date -Iseconds)" '.updated_at = $t')

  save_checkpoint "$workflow" "$CHECKPOINT"
}
```

---

## Error Recovery Patterns

### Basic Retry Pattern

```bash
execute_with_retry() {
  local cmd="$1"
  local max_retries="${2:-3}"
  local delay="${3:-2}"
  local attempt=0

  while [ $attempt -lt $max_retries ]; do
    ((attempt++))
    echo "Attempt $attempt/$max_retries"

    if eval "$cmd"; then
      return 0
    fi

    echo "Failed, waiting ${delay}s..."
    sleep "$delay"
  done

  echo "All attempts failed"
  return 1
}
```

### Progressive Backoff Pattern

```bash
execute_with_backoff() {
  local cmd="$1"
  local max_retries=5
  local delay=1

  for attempt in $(seq 1 $max_retries); do
    if eval "$cmd"; then
      return 0
    fi

    echo "Attempt $attempt failed, waiting ${delay}s"
    sleep "$delay"
    ((delay *= 2))  # Double delay each time
  done

  return 1
}
```

### Fallback Pattern

```bash
execute_with_fallback() {
  local primary="$1"
  local fallback="$2"

  if eval "$primary"; then
    return 0
  fi

  echo "Primary failed, using fallback"
  eval "$fallback"
}
```

### Graceful Degradation Pattern

```bash
execute_with_degradation() {
  local levels=("full" "partial" "minimal")

  for level in "${levels[@]}"; do
    if execute_at_level "$level"; then
      return 0
    fi
    echo "Level $level failed, degrading..."
  done

  return 1
}
```

---

## Error Classification

### Classify Error Type

```bash
classify_error() {
  local error="$1"

  if [[ "$error" =~ "network\|timeout\|connection" ]]; then
    echo "network"
  elif [[ "$error" =~ "permission\|access\|denied" ]]; then
    echo "permission"
  elif [[ "$error" =~ "not found\|missing" ]]; then
    echo "not_found"
  elif [[ "$error" =~ "syntax\|parse\|invalid" ]]; then
    echo "syntax"
  else
    echo "unknown"
  fi
}
```

### Error-Specific Recovery

```bash
recover_from_error() {
  local error="$1"
  local type=$(classify_error "$error")

  case "$type" in
    "network")
      echo "Retrying with backoff..."
      execute_with_backoff "$CMD"
      ;;
    "permission")
      echo "CRITICAL: Permission error, cannot recover"
      exit 1
      ;;
    "not_found")
      echo "Creating missing resource..."
      create_resource
      ;;
    *)
      echo "Unknown error, saving checkpoint"
      save_checkpoint
      exit 1
      ;;
  esac
}
```

---

## Artifact Referencing

### Artifact Path Pattern

```bash
get_artifact_path() {
  local topic_dir="$1"
  local artifact_type="$2"  # reports, plans, summaries
  local name="$3"

  echo "${topic_dir}/${artifact_type}/${name}.md"
}

# Usage
REPORT=$(get_artifact_path "$TOPIC_DIR" "reports" "001_auth")
PLAN=$(get_artifact_path "$TOPIC_DIR" "plans" "001_impl")
```

### Topic Directory Pattern

```bash
get_or_create_topic_dir() {
  local desc="$1"
  local base="$2"

  # Get next number
  local num=$(find "$base" -maxdepth 1 -type d | wc -l)
  local padded=$(printf "%03d" $num)

  # Create slug
  local slug=$(echo "$desc" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | cut -c1-30)

  # Create directory
  local dir="${base}/${padded}_${slug}"
  mkdir -p "$dir"/{reports,plans,summaries,debug}

  echo "$dir"
}
```

### Cross-Reference Pattern

```bash
create_cross_reference() {
  local source="$1"
  local target="$2"
  local label="$3"

  # Add link to source file
  echo "" >> "$source"
  echo "**Related**: [$label]($target)" >> "$source"
}
```

---

## State Persistence

### State File Pattern

```bash
init_state_file() {
  local id="$1"
  STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${id}.sh"

  echo "WORKFLOW_ID=$id" > "$STATE_FILE"
  echo "CREATED_AT=$(date -Iseconds)" >> "$STATE_FILE"
}

append_state() {
  local key="$1"
  local value="$2"

  echo "${key}=${value}" >> "$STATE_FILE"
}

load_state() {
  local key="$1"

  grep "^${key}=" "$STATE_FILE" | tail -1 | cut -d'=' -f2-
}
```

### Atomic State Update

```bash
atomic_state_update() {
  local key="$1"
  local value="$2"

  # Write to temp file
  local temp=$(mktemp)
  echo "${key}=${value}" > "$temp"

  # Atomic move
  mv "$temp" "$STATE_FILE"
}
```

---

## Progress Streaming

### Basic Progress Pattern

```bash
emit_progress() {
  local phase="$1"
  local message="$2"

  echo "PROGRESS: [$phase] $message"
}

# Usage
emit_progress "research" "Starting codebase analysis..."
emit_progress "research" "Found 15 relevant files"
emit_progress "research" "Creating report..."
```

### Checkpoint Progress Pattern

```bash
emit_checkpoint() {
  local phase="$1"
  local status="$2"

  cat <<EOF
CHECKPOINT: $phase
- Status: $status
- Time: $(date -Iseconds)
EOF
}
```

---

## Related Documentation

- [Overview](command-patterns-overview.md)
- [Agent Patterns](command-patterns-agents.md)
- [Integration](command-patterns-integration.md)
- [State Orchestration](../architecture/state-orchestration-transitions.md)
