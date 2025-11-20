# Command Patterns: Integration

**Related Documents**:
- [Overview](command-patterns-overview.md) - Pattern index
- [Agent Patterns](command-patterns-agents.md) - Agent invocation
- [Checkpoints](command-patterns-checkpoints.md) - State management

---

## Testing Integration

### Test Discovery Pattern

```bash
discover_tests() {
  local base_dir="$1"

  # Find all test files
  find "$base_dir" \
    -name "*_spec.lua" -o \
    -name "test_*.sh" -o \
    -name "*_test.lua" \
    2>/dev/null
}

# Usage
TESTS=$(discover_tests ".claude/tests")
```

### Test Command Pattern

```bash
get_test_command() {
  local project_root="$1"

  # Check for test configurations
  if [ -f "$project_root/.busted" ]; then
    echo "busted"
  elif [ -f "$project_root/package.json" ]; then
    echo "npm test"
  elif [ -f "$project_root/Makefile" ]; then
    echo "make test"
  else
    echo "lua tests/run.lua"
  fi
}
```

### Test Execution Pattern

```bash
run_tests() {
  local cmd=$(get_test_command ".")

  echo "Running: $cmd"

  if ! eval "$cmd"; then
    echo "FAIL: Tests failed"
    return 1
  fi

  echo "PASS: Tests passed"
  return 0
}
```

### Test Result Parsing

```bash
parse_test_results() {
  local output="$1"

  PASSED=$(echo "$output" | grep -c "PASS\|success" || echo "0")
  FAILED=$(echo "$output" | grep -c "FAIL\|error" || echo "0")
  TOTAL=$((PASSED + FAILED))

  echo "Results: $PASSED passed, $FAILED failed, $TOTAL total"
}
```

---

## Standards Discovery

### Find CLAUDE.md Pattern

```bash
find_claude_md() {
  local dir="$1"

  while [ "$dir" != "/" ]; do
    if [ -f "$dir/CLAUDE.md" ]; then
      echo "$dir/CLAUDE.md"
      return 0
    fi
    dir=$(dirname "$dir")
  done

  return 1
}
```

### Load Standards Pattern

```bash
load_standards() {
  local claude_md="$1"

  if [ ! -f "$claude_md" ]; then
    echo "WARN: No CLAUDE.md found, using defaults"
    return 1
  fi

  # Parse relevant sections
  TEST_COMMAND=$(grep -A1 "Test Command:" "$claude_md" | tail -1)
  CODE_STYLE=$(grep -A1 "Code Style:" "$claude_md" | tail -1)

  return 0
}
```

### Standards Merge Pattern

```bash
merge_standards() {
  local parent="$1"
  local child="$2"

  # Child overrides parent
  if [ -f "$child" ]; then
    source "$child"
  elif [ -f "$parent" ]; then
    source "$parent"
  fi
}
```

---

## Logger Initialization

### Logger Setup Pattern

```bash
init_logger() {
  local log_level="${1:-INFO}"
  local log_file="${2:-/dev/null}"

  export LOG_LEVEL="$log_level"
  export LOG_FILE="$log_file"

  log_info "Logger initialized: level=$LOG_LEVEL"
}

log_info() {
  echo "[INFO] $(date '+%H:%M:%S') $*" | tee -a "$LOG_FILE"
}

log_error() {
  echo "[ERROR] $(date '+%H:%M:%S') $*" | tee -a "$LOG_FILE" >&2
}

log_debug() {
  if [ "$LOG_LEVEL" = "DEBUG" ]; then
    echo "[DEBUG] $(date '+%H:%M:%S') $*" | tee -a "$LOG_FILE"
  fi
}
```

### Structured Logging Pattern

```bash
log_structured() {
  local level="$1"
  local event="$2"
  shift 2

  # Build JSON log entry
  local json=$(jq -n \
    --arg level "$level" \
    --arg event "$event" \
    --arg time "$(date -Iseconds)" \
    '{level: $level, event: $event, time: $time}')

  # Add extra fields
  for field in "$@"; do
    local key=$(echo "$field" | cut -d'=' -f1)
    local value=$(echo "$field" | cut -d'=' -f2-)
    json=$(echo "$json" | jq --arg k "$key" --arg v "$value" '. + {($k): $v}')
  done

  echo "$json" >> "$LOG_FILE"
}

# Usage
log_structured "INFO" "phase_complete" "phase=research" "duration=45s"
```

---

## Pull Request Creation

### PR Creation Pattern

```bash
create_pull_request() {
  local title="$1"
  local summary="$2"
  local branch="$3"

  # Ensure on correct branch
  git checkout -b "$branch" 2>/dev/null || git checkout "$branch"

  # Push to remote
  git push -u origin "$branch"

  # Create PR
  gh pr create \
    --title "$title" \
    --body "$(cat <<EOF
## Summary
$summary

## Test Plan
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing complete

## Changes
$(git log --oneline origin/main..$branch)

Generated with Claude Code
EOF
)"
}
```

### PR Template Pattern

```bash
generate_pr_body() {
  local summary="$1"
  local test_plan="$2"
  local breaking="${3:-none}"

  cat <<EOF
## Summary
$summary

## Test Plan
$test_plan

## Breaking Changes
$breaking

## Checklist
- [ ] Tests pass
- [ ] Documentation updated
- [ ] CHANGELOG updated

Generated with Claude Code
EOF
}
```

---

## Parallel Execution Safety

### Safe Parallel Pattern

```bash
execute_parallel_safe() {
  local -a pids
  local -a cmds=("$@")

  # Launch all commands
  for cmd in "${cmds[@]}"; do
    eval "$cmd" &
    pids+=($!)
  done

  # Wait for all and collect results
  local failed=0
  for pid in "${pids[@]}"; do
    if ! wait "$pid"; then
      ((failed++))
    fi
  done

  return $failed
}
```

### Resource Locking Pattern

```bash
acquire_lock() {
  local lock_file="$1"
  local timeout="${2:-30}"

  local elapsed=0
  while [ -f "$lock_file" ]; do
    if [ $elapsed -ge $timeout ]; then
      echo "ERROR: Lock timeout"
      return 1
    fi
    sleep 1
    ((elapsed++))
  done

  touch "$lock_file"
  return 0
}

release_lock() {
  local lock_file="$1"
  rm -f "$lock_file"
}
```

### Parallel with Limit Pattern

```bash
execute_parallel_limited() {
  local max_parallel="$1"
  shift
  local -a cmds=("$@")

  local running=0
  local -a pids

  for cmd in "${cmds[@]}"; do
    # Wait if at limit
    while [ $running -ge $max_parallel ]; do
      wait -n
      ((running--))
    done

    eval "$cmd" &
    pids+=($!)
    ((running++))
  done

  # Wait for remaining
  wait "${pids[@]}"
}
```

---

## Git Integration

### Safe Git Commit Pattern

```bash
safe_git_commit() {
  local message="$1"

  # Check for changes
  if git diff --quiet && git diff --cached --quiet; then
    echo "No changes to commit"
    return 0
  fi

  # Stage and commit
  git add -A
  git commit -m "$message

Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>"
}
```

### Branch Management Pattern

```bash
ensure_branch() {
  local branch="$1"

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    git checkout "$branch"
  else
    git checkout -b "$branch"
  fi
}
```

---

## Related Documentation

- [Overview](command-patterns-overview.md)
- [Agent Patterns](command-patterns-agents.md)
- [Checkpoints](command-patterns-checkpoints.md)
- [Testing Protocols](../reference/standards/testing-protocols.md)
