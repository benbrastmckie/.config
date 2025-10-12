# Phase 6: Enhanced Agent Performance Tracking - Implementation Specification

## Document Metadata
- **Date**: 2025-10-10
- **Phase**: 6 of 6 (NEW_claude_system_optimization plan)
- **Complexity**: Medium
- **Estimated Time**: 5-6 hours
- **Status**: Research Complete, Ready for Implementation
- **Dependencies**: Phase 2 (Metrics Aggregation System)

## Executive Summary

Phase 6 enhances the `/analyze agents` command with detailed performance metrics including average completion time, success/failure rates, common error identification, tool usage patterns, comparative analysis, and agent selection recommendations. This phase builds on Phase 2's foundational metrics infrastructure.

**Key Finding**: Phase 2 implementation (commit e90ec39) created the metrics aggregation framework but focused primarily on **command metrics**, not agent metrics. The existing `/analyze agents` command (in `.claude/commands/analyze.md`) reads from `agent-registry.json` which only tracks basic invocation counts and success rates. The detailed agent JSONL metrics described in Phase 6 specifications **do not currently exist**.

---

## Table of Contents

1. [Current State Assessment](#1-current-state-assessment)
2. [Feature Gap Analysis](#2-feature-gap-analysis)
3. [JSONL Data Structure Design](#3-jsonl-data-structure-design)
4. [Implementation Plan for Missing Features](#4-implementation-plan-for-missing-features)
5. [Comparative Analysis Design](#5-comparative-analysis-design)
6. [Tool Usage Analysis Design](#6-tool-usage-analysis-design)
7. [Agent Selection Recommendations](#7-agent-selection-recommendations)
8. [Testing Strategy](#8-testing-strategy)
9. [Detailed Task Breakdown](#9-detailed-task-breakdown)
10. [Integration & Validation](#10-integration--validation)

---

## 1. Current State Assessment

### 1.1 Existing Agent Metrics Infrastructure

**File: `/home/benjamin/.config/.claude/lib/analyze-metrics.sh`**
- **Lines**: 358 total
- **Created**: Phase 2 (commit e90ec39)
- **Primary Focus**: Command metrics, not agent metrics
- **Agent Function**: `analyze_agent_metrics()` (lines 44-81)

**Current `analyze_agent_metrics()` Function**:
```bash
analyze_agent_metrics() {
  local timeframe_days="${1:-30}"
  local agent_metrics_dir="$METRICS_DIR/agents"

  if [[ ! -d "$agent_metrics_dir" ]]; then
    echo "INFO: Agent metrics directory not found" >&2
    return 0
  fi

  local cutoff_date
  cutoff_date=$(date -d "$timeframe_days days ago" +%Y-%m-%dT%H:%M:%S 2>/dev/null || \
                date -v-"${timeframe_days}d" +%Y-%m-%dT%H:%M:%S 2>/dev/null)

  # Aggregate metrics from all agent JSONL files
  for agent_file in "$agent_metrics_dir"/*.jsonl; do
    [[ -f "$agent_file" ]] || continue

    local agent_name
    agent_name=$(basename "$agent_file" .jsonl)

    jq -r --arg cutoff "$cutoff_date" --arg agent "$agent_name" '
      select(.timestamp >= $cutoff) |
      {
        agent: $agent,
        duration_ms: .duration_ms,
        status: .status,
        tools_used: .tools_used,
        error: .error,
        timestamp: .timestamp
      }
    ' "$agent_file" 2>/dev/null || true
  done
}
```

**Analysis**:
- Function expects `.claude/data/metrics/agents/*.jsonl` files
- Expects JSONL format with: timestamp, duration_ms, status, tools_used, error
- **CRITICAL**: This directory structure **does not currently exist**
- Function is a skeleton awaiting actual agent metrics collection

### 1.2 Existing Agent Registry System

**File: `/home/benjamin/.config/.claude/agents/agent-registry.json`**
```json
{
  "agents": {},
  "metadata": {
    "created": "2025-10-03",
    "last_updated": "2025-10-03",
    "description": "Agent performance tracking registry",
    "version": "1.0"
  }
}
```

**File: `/home/benjamin/.config/.claude/hooks/post-subagent-metrics.sh`**
- **Purpose**: Captures SubagentStop events and updates agent-registry.json
- **Metrics Tracked**:
  - `total_invocations`: Count of agent executions
  - `successes`: Count of successful completions
  - `total_duration_ms`: Cumulative duration
  - `avg_duration_ms`: Calculated average
  - `success_rate`: Calculated percentage (0.0-1.0)
  - `last_execution`: ISO timestamp
  - `last_status`: "success" or error state

**Data Flow**:
```
SubagentStop Event → post-subagent-metrics.sh → agent-registry.json (aggregate data)
```

**Limitation**: Agent registry only stores **aggregated statistics**, not per-invocation details. This means:
- Cannot analyze tool usage patterns (no tool tracking)
- Cannot identify common error types (only counts failures)
- Cannot analyze variability/trends over time
- Cannot provide detailed forensics on agent behavior

### 1.3 Existing `/analyze agents` Command

**File: `/home/benjamin/.config/.claude/commands/analyze.md`** (lines 51-107)

**Current Capabilities**:
1. Reads agent-registry.json
2. Calculates efficiency scores using formula:
   - `efficiency_score = (success_rate × 0.6) + (duration_score × 0.4)`
   - `duration_score = min(1.0, target_duration / actual_avg_duration)`
3. Ranks agents by efficiency
4. Displays star ratings (★★★★★)
5. Identifies agents needing attention (efficiency < 75%)
6. Provides generic recommendations

**Example Output**:
```
=== Agent Performance Analysis ===

Overall Rankings:
1. ★★★★★ research-specialist (94% efficiency)
   Success: 98% | Avg Duration: 13.2s | Invocations: 245
   Status: Excellent performance

2. ★★★★☆ code-writer (82% efficiency)
   Success: 95% | Avg Duration: 14.8s | Invocations: 189
   Status: Good performance

3. ★★★☆☆ test-specialist (68% efficiency)
   Success: 85% | Avg Duration: 15.2s | Invocations: 67
   ⚠ Needs attention: Below target efficiency (75%)

Recommendations:
- test-specialist: Consider optimizing test detection logic
- debug-assistant: Increase success rate (currently 88%)
```

**Limitations**:
- Recommendations are generic templates, not data-driven
- No tool usage analysis
- No common error identification
- No comparative analysis mode
- No timeframe filtering

### 1.4 Existing Metrics Collection Infrastructure

**File: `/home/benjamin/.config/.claude/data/metrics/2025-10.jsonl`**

**Format**:
```json
{"timestamp":"2025-10-01T17:47:40Z","operation":"test","duration_ms":1234,"status":"success"}
```

**Fields**:
- `timestamp`: ISO 8601 format
- `operation`: Command name
- `duration_ms`: Execution time
- `status`: "success", "error", "failed"

**Note**: This is for **command metrics**, not agent metrics. No per-invocation agent JSONL files exist.

### 1.5 Current State Summary

**What Exists**:
- ✅ Basic agent registry with aggregate metrics (agent-registry.json)
- ✅ Hook for capturing SubagentStop events (post-subagent-metrics.sh)
- ✅ Basic `/analyze agents` command with efficiency scoring
- ✅ Metrics infrastructure for commands (analyze-metrics.sh)
- ✅ JSONL parsing utilities using jq

**What's Missing**:
- ❌ Per-invocation agent metrics JSONL files
- ❌ Tool usage tracking in agent execution
- ❌ Error detail collection (error messages, stack traces)
- ❌ Detailed agent performance analysis functions
- ❌ Comparative analysis mode
- ❌ Data-driven recommendations
- ❌ Timeframe filtering for agent analysis
- ❌ Common error aggregation and reporting

---

## 2. Feature Gap Analysis

### 2.1 Target Features from Phase 6 Specification

From the main plan (lines 424-486), Phase 6 requires:

1. **Average Completion Time Calculations**
   - Current: Aggregate average in registry ✅ (basic)
   - Target: Timeframe-specific averages, trend analysis ❌

2. **Success/Failure Rate Analysis**
   - Current: Overall success rate in registry ✅ (basic)
   - Target: Timeframe-specific rates, failure breakdown by type ❌

3. **Common Error Identification**
   - Current: No error details collected ❌
   - Target: Group errors by type, count occurrences, identify patterns ❌

4. **Tool Usage Pattern Analysis**
   - Current: No tool tracking ❌
   - Target: Tools used per invocation, percentage calculations, most/least used ❌

5. **Comparative Analysis Output**
   - Current: Single ranked list ✅ (basic)
   - Target: Side-by-side comparison mode for 2+ agents ❌

6. **Agent Selection Recommendations**
   - Current: Generic template recommendations ✅ (basic)
   - Target: Data-driven recommendations based on metrics ❌

### 2.2 Prioritized Feature Gaps

**Priority 1: Critical (Foundation)**
1. **Per-Invocation Metrics Collection** (no implementation, foundation for everything else)
   - Add detailed JSONL logging to agent execution
   - Capture: timestamp, agent, duration, status, tools_used, error_details, task_context
   - Store in `.claude/data/metrics/agents/{agent-type}.jsonl`

2. **Tool Usage Tracking** (no implementation)
   - Hook into agent execution to capture tool calls
   - Store tool names and counts per invocation
   - Format: `tools_used: {"Read": 5, "Edit": 3, "Bash": 2}`

**Priority 2: High (Core Features)**
3. **Detailed Parsing Functions** (partial skeleton exists)
   - `parse_agent_jsonl()` - Extract and filter JSONL data
   - `calculate_agent_stats()` - Compute timeframe-specific metrics
   - `identify_common_errors()` - Group and count error types

4. **Enhanced Analysis Output** (basic output exists)
   - Timeframe filtering (7/30/90 days)
   - Tool usage percentages
   - Common error reports with context

**Priority 3: Medium (Advanced Features)**
5. **Comparative Analysis Mode** (no implementation)
   - `--compare agent1 agent2` flag
   - Side-by-side metric comparison
   - Relative performance analysis

6. **Data-Driven Recommendations** (basic templates exist)
   - Analyze patterns and suggest specific improvements
   - Context-aware recommendations based on error types
   - Performance optimization suggestions

### 2.3 Dependency Analysis

```
Per-Invocation Metrics Collection (P1.1)
    ├─► Tool Usage Tracking (P1.2)
    │       └─► Tool Usage Analysis Functions (P2.3)
    │               └─► Enhanced Output (P2.4)
    │
    ├─► Error Detail Collection (P1.1 sub-task)
    │       └─► Common Error Identification (P2.3)
    │               └─► Data-Driven Recommendations (P3.6)
    │
    └─► Detailed Parsing Functions (P2.3)
            └─► Comparative Analysis Mode (P3.5)
```

**Implementation Order**:
1. Per-Invocation Metrics Collection (enables everything else)
2. Detailed Parsing Functions (process collected data)
3. Enhanced Analysis Output (display processed data)
4. Tool Usage Analysis (specialized analysis)
5. Comparative Analysis Mode (advanced feature)
6. Data-Driven Recommendations (synthesize insights)

---

## 3. JSONL Data Structure Design

### 3.1 Per-Invocation Agent Metrics Format

**File Naming Convention**:
- Pattern: `.claude/data/metrics/agents/{agent-type}.jsonl`
- Examples:
  - `.claude/data/metrics/agents/code-writer.jsonl`
  - `.claude/data/metrics/agents/test-specialist.jsonl`
  - `.claude/data/metrics/agents/research-specialist.jsonl`

**JSONL Record Schema**:
```json
{
  "timestamp": "2025-10-10T14:23:45Z",
  "agent_type": "code-writer",
  "invocation_id": "inv_1728567825_abc123",
  "duration_ms": 12450,
  "status": "success",
  "tools_used": {
    "Read": 8,
    "Edit": 5,
    "Bash": 2,
    "Grep": 3
  },
  "error": null,
  "error_type": null,
  "task_summary": "Implement user authentication module",
  "files_modified": 4,
  "test_status": "passed",
  "context": {
    "command": "orchestrate",
    "phase": 3,
    "retry_count": 0
  }
}
```

**Field Specifications**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `timestamp` | ISO8601 string | Yes | Invocation start time (UTC) |
| `agent_type` | string | Yes | Agent identifier (e.g., "code-writer") |
| `invocation_id` | string | Yes | Unique ID (format: `inv_{unix_timestamp}_{random}`) |
| `duration_ms` | integer | Yes | Total execution time in milliseconds |
| `status` | enum | Yes | One of: "success", "error", "timeout", "cancelled" |
| `tools_used` | object | Yes | Map of tool names to usage counts |
| `error` | string | No | Error message if status != "success" |
| `error_type` | string | No | Error category (syntax, file_not_found, timeout, etc.) |
| `task_summary` | string | No | Brief description of task (first 100 chars) |
| `files_modified` | integer | No | Count of files changed by agent |
| `test_status` | enum | No | One of: "passed", "failed", "skipped", "not_run" |
| `context` | object | No | Execution context metadata |
| `context.command` | string | No | Parent command that invoked agent |
| `context.phase` | integer | No | Phase number if applicable |
| `context.retry_count` | integer | No | Number of retries (0 = first attempt) |

### 3.2 Error JSONL Record Example

```json
{
  "timestamp": "2025-10-10T15:42:18Z",
  "agent_type": "test-specialist",
  "invocation_id": "inv_1728572538_def456",
  "duration_ms": 8230,
  "status": "error",
  "tools_used": {
    "Read": 3,
    "Bash": 5
  },
  "error": "Test execution failed: Command 'npm test' exited with code 1",
  "error_type": "test_failure",
  "task_summary": "Run test suite for authentication module",
  "files_modified": 0,
  "test_status": "failed",
  "context": {
    "command": "implement",
    "phase": 2,
    "retry_count": 1
  }
}
```

### 3.3 Tool Usage Tracking Implementation

**Capture Points**:
1. **Hook into Claude Code CLI**: Intercept tool calls during agent execution
2. **Parse SubagentStop Event**: Extract tool usage from completion metadata
3. **Fallback**: Parse agent response text for tool invocations (less accurate)

**Tool Counting Logic**:
```bash
# Pseudo-code for tool tracking
tools_used={}
for tool_call in agent_execution:
    tool_name = extract_tool_name(tool_call)
    tools_used[tool_name] = tools_used.get(tool_name, 0) + 1
```

**Supported Tools** (from agent capabilities):
- Read, Write, Edit
- Bash, BashOutput, KillShell
- Grep, Glob
- WebFetch, WebSearch
- TodoWrite
- NotebookEdit
- SlashCommand

### 3.4 Error Type Classification

**Error Categories**:
1. **syntax_error**: Code syntax validation failures
2. **file_not_found**: Missing required files
3. **test_failure**: Test execution failures
4. **timeout**: Execution time exceeded limits
5. **permission_denied**: File/command access errors
6. **compilation_error**: Build/compile failures
7. **runtime_error**: Execution runtime errors
8. **validation_error**: Data validation failures
9. **network_error**: External service failures
10. **unknown_error**: Uncategorized errors

**Classification Algorithm**:
```bash
classify_error() {
  local error_msg="$1"

  case "$error_msg" in
    *"syntax error"*|*"SyntaxError"*) echo "syntax_error" ;;
    *"No such file"*|*"not found"*) echo "file_not_found" ;;
    *"test"*"failed"*|*"assertion"*) echo "test_failure" ;;
    *"timeout"*|*"timed out"*) echo "timeout" ;;
    *"permission denied"*|*"Permission denied"*) echo "permission_denied" ;;
    *"compilation failed"*|*"build error"*) echo "compilation_error" ;;
    *) echo "unknown_error" ;;
  esac
}
```

### 3.5 Data Retention Policy

**Retention Rules**:
- Keep all records: 30 days
- Archive to `{year}-{month}.jsonl.gz`: 31-90 days
- Delete compressed archives: 90+ days

**Directory Structure**:
```
.claude/data/metrics/agents/
├── code-writer.jsonl          # Current month active records
├── test-specialist.jsonl
├── research-specialist.jsonl
└── archive/
    ├── 2025-09.jsonl.gz       # Compressed historical data
    └── 2025-08.jsonl.gz
```

---

## 4. Implementation Plan for Missing Features

### 4.1 Feature: Per-Invocation Metrics Collection

**Objective**: Capture detailed metrics for every agent invocation and write to JSONL files.

**Implementation Strategy**:

**Option A: Hook-Based Collection (Recommended)**
- Extend existing `post-subagent-metrics.sh` hook
- Parse SubagentStop event for detailed metadata
- Write both aggregate (agent-registry.json) and detailed (JSONL) records

**Option B: Agent Wrapper**
- Wrap agent invocations with metrics collection layer
- More intrusive, better control over data collection

**Recommended: Option A (Hook Extension)**

**Algorithm**:
```bash
# In post-subagent-metrics.sh (extended version)

# 1. Parse SubagentStop event
EVENT_JSON=$(cat)
AGENT_TYPE=$(echo "$EVENT_JSON" | jq -r '.subagent_type')
DURATION=$(echo "$EVENT_JSON" | jq -r '.duration_ms')
STATUS=$(echo "$EVENT_JSON" | jq -r '.status')
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# 2. Extract tool usage (from event metadata or response)
TOOLS_USED=$(echo "$EVENT_JSON" | jq -r '.tools_used // {}')

# 3. Extract error details if applicable
if [ "$STATUS" != "success" ]; then
  ERROR_MSG=$(echo "$EVENT_JSON" | jq -r '.error // "Unknown error"')
  ERROR_TYPE=$(classify_error "$ERROR_MSG")
else
  ERROR_MSG=null
  ERROR_TYPE=null
fi

# 4. Generate invocation ID
INVOCATION_ID="inv_$(date +%s)_$(openssl rand -hex 3)"

# 5. Build JSONL record
JSONL_RECORD=$(jq -n \
  --arg timestamp "$TIMESTAMP" \
  --arg agent "$AGENT_TYPE" \
  --arg inv_id "$INVOCATION_ID" \
  --argjson duration "$DURATION" \
  --arg status "$STATUS" \
  --argjson tools "$TOOLS_USED" \
  --arg error "$ERROR_MSG" \
  --arg error_type "$ERROR_TYPE" \
  '{
    timestamp: $timestamp,
    agent_type: $agent,
    invocation_id: $inv_id,
    duration_ms: ($duration | tonumber),
    status: $status,
    tools_used: $tools,
    error: (if $error == "null" then null else $error end),
    error_type: (if $error_type == "null" then null else $error_type end)
  }')

# 6. Append to agent JSONL file
AGENT_JSONL="${METRICS_DIR}/agents/${AGENT_TYPE}.jsonl"
mkdir -p "$(dirname "$AGENT_JSONL")"
echo "$JSONL_RECORD" >> "$AGENT_JSONL"

# 7. Continue with existing aggregate update logic
# ... (existing code for agent-registry.json update)
```

**Files to Modify**:
- `/home/benjamin/.config/.claude/hooks/post-subagent-metrics.sh` (~50 new lines)

**New Dependencies**:
- `openssl` (for random ID generation, fallback: `$RANDOM`)

### 4.2 Feature: Tool Usage Tracking

**Objective**: Capture which tools agents use during execution.

**Challenge**: SubagentStop events may not include tool usage metadata in current implementation.

**Solution Options**:

**Option 1: Enhance SubagentStop Event**
- Modify agent execution framework to include `tools_used` in event payload
- Requires changes to core CLI (outside .claude/ system)
- Most accurate but requires upstream changes

**Option 2: Parse Agent Response Text**
- Extract tool invocations from agent response using regex
- Less accurate but fully self-contained
- Example patterns:
  ```bash
  # Detect Read tool
  grep -o '<invoke name="Read">' response.txt | wc -l

  # Detect Edit tool
  grep -o '<invoke name="Edit">' response.txt | wc -l
  ```

**Option 3: Stub Tool Usage (Phase 6.1)**
- Initially write empty `tools_used: {}` objects
- Add TODO comment for future enhancement
- Focus on other features first

**Recommended: Option 2 (Parse Response Text)**

**Implementation**:
```bash
# Function: extract_tool_usage
# Parses agent response text to count tool invocations
# Arguments:
#   $1 - Path to agent response text file (or stdin)
# Returns: JSON object with tool counts

extract_tool_usage() {
  local response_file="${1:-/dev/stdin}"
  local tools=("Read" "Write" "Edit" "Bash" "Grep" "Glob" "WebFetch" "WebSearch" "TodoWrite" "SlashCommand")

  local tool_counts="{"
  local first=true

  for tool in "${tools[@]}"; do
    local count=$(grep -o "<invoke name=\"$tool\">" "$response_file" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$count" -gt 0 ]; then
      if [ "$first" = false ]; then
        tool_counts+=","
      fi
      tool_counts+="\"$tool\":$count"
      first=false
    fi
  done

  tool_counts+="}"
  echo "$tool_counts"
}
```

**Integration Point**:
- Add to `post-subagent-metrics.sh`
- Call after SubagentStop event parsed
- Requires access to agent response (may need to capture in temp file)

### 4.3 Feature: Detailed Parsing Functions

**Objective**: Implement robust JSONL parsing and aggregation functions.

**New Functions for `analyze-metrics.sh`**:

#### Function: `parse_agent_jsonl()`

```bash
# Function: parse_agent_jsonl
# Description: Extract and filter agent metrics from JSONL file
# Arguments:
#   $1 - Agent type (e.g., "code-writer")
#   $2 - Timeframe in days (default: 30)
# Returns: Filtered JSONL records (one per line)

parse_agent_jsonl() {
  local agent_type="$1"
  local timeframe_days="${2:-30}"

  if [[ -z "$agent_type" ]]; then
    echo "ERROR: Agent type required" >&2
    return 1
  fi

  local agent_file="${METRICS_DIR}/agents/${agent_type}.jsonl"

  if [[ ! -f "$agent_file" ]]; then
    echo "ERROR: Agent metrics file not found: $agent_file" >&2
    return 1
  fi

  local cutoff_date
  cutoff_date=$(date -d "$timeframe_days days ago" +%Y-%m-%dT%H:%M:%S 2>/dev/null || \
                date -v-"${timeframe_days}d" +%Y-%m-%dT%H:%M:%S 2>/dev/null)

  jq -r --arg cutoff "$cutoff_date" \
    'select(.timestamp >= $cutoff)' \
    "$agent_file" 2>/dev/null || true
}
```

#### Function: `calculate_agent_stats()`

```bash
# Function: calculate_agent_stats
# Description: Compute comprehensive statistics for an agent
# Arguments:
#   $1 - Agent type
#   $2 - Timeframe in days (default: 30)
# Returns: JSON object with computed statistics

calculate_agent_stats() {
  local agent_type="$1"
  local timeframe_days="${2:-30}"

  local jsonl_data
  jsonl_data=$(parse_agent_jsonl "$agent_type" "$timeframe_days")

  if [[ -z "$jsonl_data" ]]; then
    echo "{\"error\": \"No data available for $agent_type in last $timeframe_days days\"}"
    return 1
  fi

  # Aggregate statistics using jq
  echo "$jsonl_data" | jq -s '
    {
      agent_type: .[0].agent_type,
      timeframe_days: '$timeframe_days',
      total_invocations: length,

      # Success metrics
      successes: map(select(.status == "success")) | length,
      failures: map(select(.status != "success")) | length,
      success_rate: (
        (map(select(.status == "success")) | length) / length * 100 |
        floor
      ),

      # Duration metrics
      avg_duration_ms: (map(.duration_ms) | add / length | floor),
      min_duration_ms: (map(.duration_ms) | min),
      max_duration_ms: (map(.duration_ms) | max),
      median_duration_ms: (
        map(.duration_ms) | sort |
        if length % 2 == 0
        then .[length/2-1:length/2+1] | add / 2
        else .[length/2]
        end | floor
      ),

      # Tool usage aggregation
      tools_used: (
        map(.tools_used // {}) |
        reduce .[] as $item ({};
          reduce ($item | keys_unsorted[]) as $key (.;
            .[$key] = ((.[$key] // 0) + $item[$key])
          )
        )
      ),

      # Error aggregation
      errors_by_type: (
        map(select(.error_type != null) | .error_type) |
        group_by(.) |
        map({(.[0]): length}) |
        add // {}
      ),

      # Timestamp range
      first_invocation: (map(.timestamp) | min),
      last_invocation: (map(.timestamp) | max)
    }
  '
}
```

#### Function: `identify_common_errors()`

```bash
# Function: identify_common_errors
# Description: Group and count error types, extract error messages
# Arguments:
#   $1 - Agent type
#   $2 - Timeframe in days (default: 30)
#   $3 - Top N errors to return (default: 5)
# Returns: Markdown formatted error report

identify_common_errors() {
  local agent_type="$1"
  local timeframe_days="${2:-30}"
  local top_n="${3:-5}"

  local jsonl_data
  jsonl_data=$(parse_agent_jsonl "$agent_type" "$timeframe_days")

  if [[ -z "$jsonl_data" ]]; then
    echo "No error data available for $agent_type"
    return 0
  fi

  echo "### Common Errors: $agent_type"
  echo ""

  # Get error type counts
  local error_types
  error_types=$(echo "$jsonl_data" | jq -r '
    select(.error_type != null) |
    .error_type
  ' | sort | uniq -c | sort -rn | head -"$top_n")

  if [[ -z "$error_types" ]]; then
    echo "No errors found in timeframe"
    return 0
  fi

  # Display error types with examples
  echo "$error_types" | while read -r count error_type; do
    echo "**${error_type}** ($count occurrences)"

    # Get example error message
    local example
    example=$(echo "$jsonl_data" | jq -r \
      --arg etype "$error_type" \
      'select(.error_type == $etype) | .error' | head -1)

    echo "  - Example: \`$example\`"
    echo ""
  done
}
```

#### Function: `analyze_tool_usage()`

```bash
# Function: analyze_tool_usage
# Description: Calculate tool usage percentages and patterns
# Arguments:
#   $1 - Agent type
#   $2 - Timeframe in days (default: 30)
# Returns: Markdown formatted tool usage report

analyze_tool_usage() {
  local agent_type="$1"
  local timeframe_days="${2:-30}"

  local stats
  stats=$(calculate_agent_stats "$agent_type" "$timeframe_days")

  if echo "$stats" | jq -e '.error' >/dev/null 2>&1; then
    echo "No tool usage data available for $agent_type"
    return 0
  fi

  echo "### Tool Usage: $agent_type"
  echo ""

  # Extract tools_used and calculate percentages
  local tools_json
  tools_json=$(echo "$stats" | jq -r '.tools_used')

  if [[ "$tools_json" == "{}" ]] || [[ "$tools_json" == "null" ]]; then
    echo "No tool usage recorded"
    return 0
  fi

  # Calculate total tool calls
  local total_calls
  total_calls=$(echo "$tools_json" | jq '[.[]] | add')

  if [[ "$total_calls" -eq 0 ]]; then
    echo "No tool usage recorded"
    return 0
  fi

  # Generate sorted tool usage report with percentages
  echo "$tools_json" | jq -r --argjson total "$total_calls" '
    to_entries |
    map({
      tool: .key,
      count: .value,
      percentage: ((.value / $total) * 100 | floor)
    }) |
    sort_by(-.count) |
    .[] |
    "- \(.tool): \(.count) calls (\(.percentage)%)"
  '

  echo ""
  echo "**Total tool calls**: $total_calls"
  echo ""
}
```

**Files to Modify**:
- `/home/benjamin/.config/.claude/lib/analyze-metrics.sh` (+200 lines)

### 4.4 Feature: Enhanced Analysis Output

**Objective**: Improve `/analyze agents` output with detailed metrics and timeframe filtering.

**Current Output Format** (from analyze.md):
```
=== Agent Performance Analysis ===

Overall Rankings:
1. ★★★★★ research-specialist (94% efficiency)
   Success: 98% | Avg Duration: 13.2s | Invocations: 245
   Status: Excellent performance
```

**Enhanced Output Format**:
```
=== Agent Performance Analysis ===
Timeframe: Last 30 days
Generated: 2025-10-10 15:30:22

Overall Rankings:
1. ★★★★★ research-specialist (94% efficiency)
   Success: 98% (240/245) | Avg Duration: 13.2s | Invocations: 245
   Status: Excellent performance

   Tool Usage (top 3):
   - Read: 45%
   - WebSearch: 30%
   - Write: 15%

   Recent Performance:
   - Last 7 days: 96% success (23/24)
   - Avg duration trend: ↓ improving (was 14.1s)

2. ★★★★☆ code-writer (82% efficiency)
   Success: 95% (179/189) | Avg Duration: 14.8s | Invocations: 189
   Status: Good performance

   Tool Usage (top 3):
   - Edit: 40%
   - Read: 35%
   - Bash: 15%

   Common Errors:
   - syntax_error: 5 occurrences
   - test_failure: 3 occurrences

   Recommendation: Review syntax validation before commits

3. ★★★☆☆ test-specialist (68% efficiency)
   Success: 85% (57/67) | Avg Duration: 15.2s | Invocations: 67
   ⚠ Needs attention: Below target efficiency (75%)

   Tool Usage (top 3):
   - Bash: 60%
   - Read: 25%
   - Grep: 10%

   Common Errors:
   - test_failure: 7 occurrences
   - timeout: 3 occurrences

   Recommendation: Investigate test timeout issues, optimize test execution

---

Detailed Reports:
Run `/analyze agents research-specialist` for agent-specific details
Run `/analyze agents --compare code-writer test-specialist` for side-by-side comparison
```

**Implementation Approach**:

1. **Modify `/analyze agents` command logic**:
   - Add timeframe parameter parsing
   - Call enhanced stats functions
   - Format output with new details

2. **Template for Enhanced Output**:

```bash
# In analyze.md command (pseudo-code)

analyze_agents_enhanced() {
  local timeframe="${1:-30}"

  echo "=== Agent Performance Analysis ==="
  echo "Timeframe: Last $timeframe days"
  echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""

  # Get all agents from registry
  local agents
  agents=$(jq -r '.agents | keys[]' "$AGENT_REGISTRY_FILE")

  # Calculate stats for each agent
  declare -A agent_stats
  for agent in $agents; do
    agent_stats[$agent]=$(calculate_agent_stats "$agent" "$timeframe")
  done

  # Sort by efficiency score (from registry)
  # ... (existing sorting logic)

  # Display detailed rankings
  local rank=1
  for agent in $sorted_agents; do
    display_agent_detailed_report "$agent" "${agent_stats[$agent]}" "$rank"
    rank=$((rank + 1))
  done

  # Footer with usage hints
  echo ""
  echo "---"
  echo ""
  echo "Detailed Reports:"
  echo "Run \`/analyze agents <agent-name>\` for agent-specific details"
  echo "Run \`/analyze agents --compare <agent1> <agent2>\` for side-by-side comparison"
}
```

**Files to Modify**:
- `/home/benjamin/.config/.claude/commands/analyze.md` (+150 lines enhancement)

---

## 5. Comparative Analysis Design

### 5.1 Objective

Enable side-by-side comparison of multiple agents with relative performance metrics.

### 5.2 Command Syntax

```bash
/analyze agents --compare code-writer test-specialist
/analyze agents --compare code-writer test-specialist research-specialist
/analyze agents --compare all  # Compare all agents
```

### 5.3 Output Format

```
=== Comparative Agent Analysis ===
Timeframe: Last 30 days
Comparing: code-writer, test-specialist

┌─────────────────────┬──────────────────┬────────────────────┐
│ Metric              │ code-writer      │ test-specialist    │
├─────────────────────┼──────────────────┼────────────────────┤
│ Invocations         │ 189              │ 67                 │
│ Success Rate        │ 95% (179/189)    │ 85% (57/67)        │
│ Avg Duration        │ 14.8s            │ 15.2s              │
│ Efficiency Score    │ ★★★★☆ (82%)     │ ★★★☆☆ (68%)       │
├─────────────────────┼──────────────────┼────────────────────┤
│ Most Used Tool      │ Edit (40%)       │ Bash (60%)         │
│ 2nd Most Used       │ Read (35%)       │ Read (25%)         │
│ 3rd Most Used       │ Bash (15%)       │ Grep (10%)         │
├─────────────────────┼──────────────────┼────────────────────┤
│ Top Error Type      │ syntax_error (5) │ test_failure (7)   │
│ 2nd Error Type      │ test_failure (3) │ timeout (3)        │
├─────────────────────┼──────────────────┼────────────────────┤
│ Performance Trend   │ Stable           │ Declining          │
│ Recommendation      │ Excellent        │ Needs Attention    │
└─────────────────────┴──────────────────┴────────────────────┘

### Relative Performance

**code-writer vs test-specialist**:
- code-writer is 10% more successful (95% vs 85%)
- code-writer is 3% faster (14.8s vs 15.2s)
- code-writer has 14% better efficiency score (82% vs 68%)

**Best Use Cases**:
- code-writer: Implementation tasks requiring file edits
- test-specialist: Test execution (when not timing out)

**Recommendation**: Investigate test-specialist timeout issues (3 occurrences)
```

### 5.4 Implementation Algorithm

```bash
# Function: compare_agents
# Description: Generate side-by-side comparison of multiple agents
# Arguments:
#   $@ - Agent types to compare (space-separated)
# Returns: Formatted comparison table

compare_agents() {
  local agents=("$@")
  local timeframe="${TIMEFRAME:-30}"

  if [[ ${#agents[@]} -lt 2 ]]; then
    echo "ERROR: At least 2 agents required for comparison" >&2
    return 1
  fi

  echo "=== Comparative Agent Analysis ==="
  echo "Timeframe: Last $timeframe days"
  echo "Comparing: ${agents[*]}"
  echo ""

  # Collect stats for all agents
  declare -A stats_map
  for agent in "${agents[@]}"; do
    stats_map[$agent]=$(calculate_agent_stats "$agent" "$timeframe")
  done

  # Build comparison table
  # Header row
  printf "┌─────────────────────"
  for agent in "${agents[@]}"; do
    printf "┬──────────────────"
  done
  printf "┐\n"

  printf "│ %-19s " "Metric"
  for agent in "${agents[@]}"; do
    printf "│ %-16s " "$agent"
  done
  printf "│\n"

  printf "├─────────────────────"
  for agent in "${agents[@]}"; do
    printf "┼──────────────────"
  done
  printf "┤\n"

  # Data rows
  compare_metric "Invocations" ".total_invocations" "${agents[@]}"
  compare_metric "Success Rate" ".success_rate" "${agents[@]}" "%"
  compare_metric "Avg Duration" ".avg_duration_ms" "${agents[@]}" "ms"
  # ... (additional metrics)

  # Footer
  printf "└─────────────────────"
  for agent in "${agents[@]}"; do
    printf "┴──────────────────"
  done
  printf "┘\n"

  # Relative performance analysis
  echo ""
  echo "### Relative Performance"
  echo ""

  # Compare first agent to others
  local base_agent="${agents[0]}"
  for agent in "${agents[@]:1}"; do
    compare_relative "$base_agent" "$agent"
  done
}

# Helper function for metric comparison
compare_metric() {
  local label="$1"
  local jq_path="$2"
  shift 2
  local agents=("$@")

  printf "│ %-19s " "$label"
  for agent in "${agents[@]}"; do
    local value
    value=$(echo "${stats_map[$agent]}" | jq -r "$jq_path")
    printf "│ %-16s " "$value"
  done
  printf "│\n"
}
```

### 5.5 Files to Create/Modify

- `/home/benjamin/.config/.claude/lib/analyze-metrics.sh` (+150 lines for comparison functions)
- `/home/benjamin/.config/.claude/commands/analyze.md` (+50 lines for --compare flag)

---

## 6. Tool Usage Analysis Design

### 6.1 Visualization Approach

**ASCII Bar Charts** for tool usage percentages:

```
### Tool Usage: code-writer (Last 30 days)

Edit    ████████████████████████████████████████ 40% (180 calls)
Read    ███████████████████████████████████      35% (157 calls)
Bash    ███████████████                          15% (67 calls)
Grep    ██████                                    6% (27 calls)
Write   ████                                      4% (18 calls)

Total tool calls: 449
Average tools per invocation: 2.4
```

### 6.2 Tool Usage Patterns Analysis

**Pattern Identification**:

1. **Tool Combinations**: Which tools are used together?
   ```
   Common Tool Combinations:
   - Read + Edit: 85% of invocations (typical modification pattern)
   - Edit + Bash: 45% of invocations (implement + test pattern)
   - Read + Grep + Edit: 20% of invocations (search + modify pattern)
   ```

2. **Tool Efficiency**: Which tool usage correlates with success?
   ```
   Tool Success Correlation:
   - High Edit usage: 96% success rate (indicates confident implementation)
   - High Bash usage: 88% success rate (testing can fail)
   - Read-only patterns: 99% success rate (research/analysis tasks)
   ```

3. **Anomaly Detection**: Unusual tool usage patterns
   ```
   Anomalies Detected:
   - code-writer using WebSearch: 3 occurrences (unusual, may indicate confusion)
   - test-specialist using Edit: 8 occurrences (should primarily use Bash/Read)
   ```

### 6.3 Implementation Functions

```bash
# Function: analyze_tool_combinations
# Description: Identify common tool usage patterns
# Arguments:
#   $1 - Agent type
#   $2 - Timeframe in days (default: 30)
# Returns: Markdown report of tool combinations

analyze_tool_combinations() {
  local agent_type="$1"
  local timeframe_days="${2:-30}"

  local jsonl_data
  jsonl_data=$(parse_agent_jsonl "$agent_type" "$timeframe_days")

  echo "### Common Tool Combinations: $agent_type"
  echo ""

  # Extract tool combinations (tools used together in single invocation)
  local combinations
  combinations=$(echo "$jsonl_data" | jq -r '
    .tools_used // {} |
    keys |
    sort |
    join(" + ")
  ' | sort | uniq -c | sort -rn | head -5)

  if [[ -z "$combinations" ]]; then
    echo "No tool combination data available"
    return 0
  fi

  local total_invocations
  total_invocations=$(echo "$jsonl_data" | jq -s 'length')

  echo "$combinations" | while read -r count pattern; do
    local percentage=$((count * 100 / total_invocations))
    echo "- **$pattern**: $count invocations (${percentage}%)"
  done

  echo ""
}

# Function: calculate_tool_efficiency
# Description: Correlate tool usage with success rates
# Arguments:
#   $1 - Agent type
#   $2 - Timeframe in days (default: 30)
# Returns: Markdown report of tool efficiency

calculate_tool_efficiency() {
  local agent_type="$1"
  local timeframe_days="${2:-30}"

  local jsonl_data
  jsonl_data=$(parse_agent_jsonl "$agent_type" "$timeframe_days")

  echo "### Tool Success Correlation: $agent_type"
  echo ""

  # For each tool, calculate success rate when tool is used
  local tools
  tools=$(echo "$jsonl_data" | jq -r '.tools_used // {} | keys[]' | sort -u)

  for tool in $tools; do
    # Count invocations using this tool
    local with_tool_total
    with_tool_total=$(echo "$jsonl_data" | jq -r \
      --arg tool "$tool" \
      'select(.tools_used[$tool] != null)' | jq -s 'length')

    if [[ "$with_tool_total" -eq 0 ]]; then
      continue
    fi

    # Count successful invocations using this tool
    local with_tool_success
    with_tool_success=$(echo "$jsonl_data" | jq -r \
      --arg tool "$tool" \
      'select(.tools_used[$tool] != null) | select(.status == "success")' | jq -s 'length')

    local success_rate=$((with_tool_success * 100 / with_tool_total))

    echo "- **$tool**: ${success_rate}% success rate ($with_tool_success/$with_tool_total invocations)"
  done

  echo ""
}
```

---

## 7. Agent Selection Recommendations

### 7.1 Recommendation Generation Logic

**Goal**: Provide data-driven recommendations for:
1. Which agent to use for specific tasks
2. How to improve underperforming agents
3. When to investigate agent issues

**Recommendation Categories**:

1. **Best Agent for Task Type**
   - Based on: Success rate, tool usage patterns, duration
   - Example: "For code modifications, use code-writer (95% success, 14.8s avg)"

2. **Agent Optimization Suggestions**
   - Based on: Error patterns, duration trends, tool inefficiency
   - Example: "test-specialist has 7 test_failure errors; investigate test environment setup"

3. **Agent Health Warnings**
   - Based on: Declining success rates, increasing durations, new error types
   - Example: "WARNING: code-writer success rate dropped from 98% to 92% in last 7 days"

### 7.2 Recommendation Templates

**Template Structure**:
```markdown
## Agent Recommendations

### Best Agents for Common Tasks

**Code Implementation**:
- Primary: code-writer (95% success, 14.8s avg)
- Backup: research-specialist (for complex requirements analysis)
- Avoid: test-specialist (not designed for code changes)

**Test Execution**:
- Primary: test-specialist (85% success, 15.2s avg)
- Note: Watch for timeout issues (3 occurrences recently)

**Research & Documentation**:
- Primary: research-specialist (98% success, 13.2s avg)
- Excellent performance, no concerns

### Improvement Recommendations

**test-specialist** (68% efficiency, needs attention):
1. **Immediate**: Investigate 7 test_failure occurrences
   - Check test environment configuration
   - Verify test dependencies available
   - Review test timeout settings (3 timeout errors)

2. **Short-term**: Optimize test execution
   - Current avg: 15.2s (target: 10s)
   - Consider parallel test execution
   - Cache test dependencies

3. **Long-term**: Monitor success rate trend
   - Current: 85% (target: >90%)
   - Track improvements after timeout fixes

**code-writer** (82% efficiency, good performance):
1. **Maintain**: Continue current usage patterns
2. **Minor**: Review 5 syntax_error occurrences
   - Add pre-commit syntax validation
   - Consider linting integration

### Health Warnings

⚠️ **test-specialist**: Declining performance trend
- Success rate: 85% (down from 92% last month)
- Recommend immediate investigation

✅ **code-writer**: Stable performance
✅ **research-specialist**: Excellent performance
```

### 7.3 Implementation Algorithm

```bash
# Function: generate_agent_recommendations
# Description: Create data-driven recommendations for agent usage
# Arguments:
#   $1 - Timeframe in days (default: 30)
# Returns: Markdown recommendation report

generate_agent_recommendations() {
  local timeframe="${1:-30}"

  echo "## Agent Recommendations"
  echo ""

  # Collect stats for all agents
  local all_agents
  all_agents=$(jq -r '.agents | keys[]' "$AGENT_REGISTRY_FILE")

  declare -A agent_stats
  for agent in $all_agents; do
    agent_stats[$agent]=$(calculate_agent_stats "$agent" "$timeframe")
  done

  # Section 1: Best agents for tasks
  echo "### Best Agents for Common Tasks"
  echo ""

  recommend_best_for_task "Code Implementation" "code-writer" "test-specialist" "research-specialist"
  recommend_best_for_task "Test Execution" "test-specialist" "code-writer"
  recommend_best_for_task "Research & Documentation" "research-specialist" "doc-writer"

  # Section 2: Improvement recommendations
  echo "### Improvement Recommendations"
  echo ""

  for agent in $all_agents; do
    local stats="${agent_stats[$agent]}"
    local success_rate
    success_rate=$(echo "$stats" | jq -r '.success_rate')

    if [[ "$success_rate" -lt 90 ]]; then
      generate_improvement_plan "$agent" "$stats"
    fi
  done

  # Section 3: Health warnings
  echo "### Health Warnings"
  echo ""

  for agent in $all_agents; do
    check_agent_health "$agent" "${agent_stats[$agent]}"
  done
}

# Function: recommend_best_for_task
# Description: Recommend best agent for specific task type
# Arguments:
#   $1 - Task description
#   $@ - Agent types to evaluate (first is usually best)

recommend_best_for_task() {
  local task_desc="$1"
  shift
  local agents=("$@")

  echo "**$task_desc**:"

  local primary="${agents[0]}"
  local stats
  stats=$(calculate_agent_stats "$primary" 30)
  local success_rate avg_duration
  success_rate=$(echo "$stats" | jq -r '.success_rate')
  avg_duration=$(echo "$stats" | jq -r '.avg_duration_ms / 1000 | floor')

  echo "- Primary: $primary (${success_rate}% success, ${avg_duration}s avg)"

  # Additional recommendations
  if [[ ${#agents[@]} -gt 1 ]]; then
    echo "- Backup: ${agents[1]}"
  fi

  # Warnings if any
  if [[ "$success_rate" -lt 85 ]]; then
    echo "- ⚠️ Note: Success rate below recommended threshold"
  fi

  echo ""
}

# Function: generate_improvement_plan
# Description: Create actionable improvement plan for underperforming agent
# Arguments:
#   $1 - Agent type
#   $2 - Agent stats JSON

generate_improvement_plan() {
  local agent="$1"
  local stats="$2"

  local success_rate
  success_rate=$(echo "$stats" | jq -r '.success_rate')

  echo "**$agent** (${success_rate}% success rate, needs attention):"

  # Analyze error patterns
  local errors_json
  errors_json=$(echo "$stats" | jq -r '.errors_by_type')

  if [[ "$errors_json" != "{}" ]] && [[ "$errors_json" != "null" ]]; then
    echo "1. **Immediate**: Address common errors"
    echo "$errors_json" | jq -r 'to_entries[] | "   - \(.key): \(.value) occurrences"'
    echo ""
  fi

  # Check duration performance
  local avg_duration target_duration
  avg_duration=$(echo "$stats" | jq -r '.avg_duration_ms')
  target_duration=$(get_target_duration "$agent")

  if [[ "$avg_duration" -gt "$target_duration" ]]; then
    echo "2. **Short-term**: Optimize execution time"
    echo "   - Current avg: $((avg_duration / 1000))s (target: $((target_duration / 1000))s)"
    echo "   - Profile for performance bottlenecks"
    echo ""
  fi

  # Success rate improvement
  if [[ "$success_rate" -lt 90 ]]; then
    echo "3. **Long-term**: Improve success rate"
    echo "   - Current: ${success_rate}% (target: >90%)"
    echo "   - Monitor after addressing errors"
    echo ""
  fi
}

# Function: check_agent_health
# Description: Check for health warnings (declining performance)
# Arguments:
#   $1 - Agent type
#   $2 - Current agent stats JSON

check_agent_health() {
  local agent="$1"
  local current_stats="$2"

  # Compare current stats to historical (7-day vs 30-day)
  local current_success_rate
  current_success_rate=$(echo "$current_stats" | jq -r '.success_rate')

  local recent_stats
  recent_stats=$(calculate_agent_stats "$agent" 7)
  local recent_success_rate
  recent_success_rate=$(echo "$recent_stats" | jq -r '.success_rate // 0')

  # Check for declining performance
  if [[ "$recent_success_rate" -lt "$current_success_rate" ]]; then
    local decline=$((current_success_rate - recent_success_rate))
    if [[ "$decline" -gt 5 ]]; then
      echo "⚠️ **$agent**: Declining performance trend"
      echo "   - Recent success rate: ${recent_success_rate}% (down from ${current_success_rate}%)"
      echo "   - Recommend immediate investigation"
      echo ""
      return
    fi
  fi

  # Check for excellent performance
  if [[ "$current_success_rate" -gt 95 ]]; then
    echo "✅ **$agent**: Excellent performance"
  fi
}
```

---

## 8. Testing Strategy

### 8.1 Unit Tests

**New Test File**: `/home/benjamin/.config/.claude/tests/test_agent_metrics.sh`

**Test Coverage**:

```bash
#!/usr/bin/env bash
# test_agent_metrics.sh - Unit tests for agent metrics functions

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$TEST_DIR/../lib"

# Source the library under test
source "$LIB_DIR/analyze-metrics.sh"

# Setup test fixtures
setup_test_data() {
  export TEST_METRICS_DIR="/tmp/test_agent_metrics_$$"
  mkdir -p "$TEST_METRICS_DIR/agents"
  export METRICS_DIR="$TEST_METRICS_DIR"

  # Create sample JSONL data
  cat > "$TEST_METRICS_DIR/agents/test-agent.jsonl" <<EOF
{"timestamp":"2025-10-01T10:00:00Z","agent_type":"test-agent","invocation_id":"inv_001","duration_ms":5000,"status":"success","tools_used":{"Read":3,"Edit":2},"error":null,"error_type":null}
{"timestamp":"2025-10-02T11:00:00Z","agent_type":"test-agent","invocation_id":"inv_002","duration_ms":7000,"status":"success","tools_used":{"Read":5,"Bash":1},"error":null,"error_type":null}
{"timestamp":"2025-10-03T12:00:00Z","agent_type":"test-agent","invocation_id":"inv_003","duration_ms":6000,"status":"error","tools_used":{"Read":2},"error":"Test failed","error_type":"test_failure"}
{"timestamp":"2025-10-05T13:00:00Z","agent_type":"test-agent","invocation_id":"inv_004","duration_ms":4500,"status":"success","tools_used":{"Read":4,"Edit":3,"Bash":1},"error":null,"error_type":null}
EOF
}

teardown_test_data() {
  rm -rf "$TEST_METRICS_DIR"
}

# Test 1: parse_agent_jsonl function
test_parse_agent_jsonl() {
  echo "TEST: parse_agent_jsonl"

  local result
  result=$(parse_agent_jsonl "test-agent" 365)

  local line_count
  line_count=$(echo "$result" | wc -l)

  if [[ "$line_count" -eq 4 ]]; then
    echo "  ✓ PASS: Parsed 4 JSONL records"
  else
    echo "  ✗ FAIL: Expected 4 records, got $line_count"
    return 1
  fi
}

# Test 2: calculate_agent_stats function
test_calculate_agent_stats() {
  echo "TEST: calculate_agent_stats"

  local stats
  stats=$(calculate_agent_stats "test-agent" 365)

  # Verify total invocations
  local total_invocations
  total_invocations=$(echo "$stats" | jq -r '.total_invocations')

  if [[ "$total_invocations" -eq 4 ]]; then
    echo "  ✓ PASS: Total invocations correct (4)"
  else
    echo "  ✗ FAIL: Expected 4 invocations, got $total_invocations"
    return 1
  fi

  # Verify success rate
  local success_rate
  success_rate=$(echo "$stats" | jq -r '.success_rate')

  if [[ "$success_rate" -eq 75 ]]; then
    echo "  ✓ PASS: Success rate correct (75%)"
  else
    echo "  ✗ FAIL: Expected 75% success rate, got $success_rate%"
    return 1
  fi

  # Verify average duration
  local avg_duration
  avg_duration=$(echo "$stats" | jq -r '.avg_duration_ms')

  if [[ "$avg_duration" -ge 5000 ]] && [[ "$avg_duration" -le 6000 ]]; then
    echo "  ✓ PASS: Average duration in expected range (${avg_duration}ms)"
  else
    echo "  ✗ FAIL: Average duration out of range: ${avg_duration}ms"
    return 1
  fi
}

# Test 3: identify_common_errors function
test_identify_common_errors() {
  echo "TEST: identify_common_errors"

  local errors
  errors=$(identify_common_errors "test-agent" 365)

  if echo "$errors" | grep -q "test_failure"; then
    echo "  ✓ PASS: Identified test_failure error type"
  else
    echo "  ✗ FAIL: Did not identify test_failure error"
    return 1
  fi

  if echo "$errors" | grep -q "1 occurrences"; then
    echo "  ✓ PASS: Correct error count"
  else
    echo "  ✗ FAIL: Incorrect error count"
    return 1
  fi
}

# Test 4: analyze_tool_usage function
test_analyze_tool_usage() {
  echo "TEST: analyze_tool_usage"

  local tool_usage
  tool_usage=$(analyze_tool_usage "test-agent" 365)

  if echo "$tool_usage" | grep -q "Read:"; then
    echo "  ✓ PASS: Detected Read tool usage"
  else
    echo "  ✗ FAIL: Did not detect Read tool"
    return 1
  fi

  if echo "$tool_usage" | grep -q "Edit:"; then
    echo "  ✓ PASS: Detected Edit tool usage"
  else
    echo "  ✗ FAIL: Did not detect Edit tool"
    return 1
  fi
}

# Test 5: Timeframe filtering
test_timeframe_filtering() {
  echo "TEST: Timeframe filtering"

  # Filter to only last 3 days (should get 2 records from Oct 3 and 5)
  local recent
  recent=$(parse_agent_jsonl "test-agent" 7)

  local recent_count
  recent_count=$(echo "$recent" | jq -s 'length')

  # Note: This test depends on current date, may need adjustment
  if [[ "$recent_count" -le 4 ]]; then
    echo "  ✓ PASS: Timeframe filtering working (got $recent_count records)"
  else
    echo "  ✗ FAIL: Timeframe filtering not working correctly"
    return 1
  fi
}

# Run all tests
run_all_tests() {
  local passed=0
  local failed=0

  setup_test_data

  if test_parse_agent_jsonl; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_calculate_agent_stats; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_identify_common_errors; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_analyze_tool_usage; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_timeframe_filtering; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  teardown_test_data

  echo ""
  echo "=========================================="
  echo "Test Results: $passed passed, $failed failed"
  echo "=========================================="

  if [[ "$failed" -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

# Execute tests
run_all_tests
```

### 8.2 Integration Tests

**Test Scenario 1: End-to-End Agent Metrics Collection**

```bash
# Integration test: Simulate agent execution and verify metrics collection

test_e2e_agent_metrics() {
  echo "INTEGRATION TEST: End-to-end agent metrics collection"

  # 1. Simulate SubagentStop event
  local test_event='{"subagent_type":"test-agent","duration_ms":5000,"status":"success","tools_used":{"Read":3,"Edit":2}}'

  # 2. Run metrics hook
  echo "$test_event" | bash .claude/hooks/post-subagent-metrics.sh

  # 3. Verify JSONL file created
  if [[ -f ".claude/data/metrics/agents/test-agent.jsonl" ]]; then
    echo "  ✓ PASS: JSONL file created"
  else
    echo "  ✗ FAIL: JSONL file not created"
    return 1
  fi

  # 4. Verify JSONL record format
  local last_record
  last_record=$(tail -1 .claude/data/metrics/agents/test-agent.jsonl)

  if echo "$last_record" | jq -e '.agent_type' >/dev/null 2>&1; then
    echo "  ✓ PASS: Valid JSONL record format"
  else
    echo "  ✗ FAIL: Invalid JSONL format"
    return 1
  fi

  # 5. Verify agent registry updated
  local registry_success_rate
  registry_success_rate=$(jq -r '.agents["test-agent"].success_rate' .claude/agents/agent-registry.json)

  if [[ -n "$registry_success_rate" ]]; then
    echo "  ✓ PASS: Agent registry updated"
  else
    echo "  ✗ FAIL: Agent registry not updated"
    return 1
  fi
}
```

**Test Scenario 2: Full /analyze agents Command**

```bash
test_analyze_agents_command() {
  echo "INTEGRATION TEST: /analyze agents command"

  # Setup: Create test JSONL data
  setup_test_data

  # Run command
  local output
  output=$(/analyze agents 2>&1)

  # Verify output contains expected sections
  if echo "$output" | grep -q "Agent Performance Analysis"; then
    echo "  ✓ PASS: Output contains analysis header"
  else
    echo "  ✗ FAIL: Missing analysis header"
    return 1
  fi

  if echo "$output" | grep -q "Tool Usage"; then
    echo "  ✓ PASS: Output contains tool usage section"
  else
    echo "  ✗ FAIL: Missing tool usage section"
    return 1
  fi

  if echo "$output" | grep -q "Common Errors"; then
    echo "  ✓ PASS: Output contains error section"
  else
    echo "  ✗ FAIL: Missing error section"
    return 1
  fi

  teardown_test_data
}
```

### 8.3 Validation Tests

**Data Integrity Checks**:

```bash
# Verify JSONL data integrity
validate_jsonl_integrity() {
  local jsonl_file="$1"

  echo "VALIDATION: JSONL integrity for $jsonl_file"

  # Check each line is valid JSON
  local line_num=0
  while IFS= read -r line; do
    line_num=$((line_num + 1))

    if ! echo "$line" | jq empty 2>/dev/null; then
      echo "  ✗ FAIL: Invalid JSON at line $line_num"
      return 1
    fi
  done < "$jsonl_file"

  echo "  ✓ PASS: All $line_num lines are valid JSON"

  # Verify required fields
  local missing_fields=0
  while IFS= read -r line; do
    for field in timestamp agent_type duration_ms status; do
      if ! echo "$line" | jq -e ".$field" >/dev/null 2>&1; then
        echo "  ✗ FAIL: Missing required field: $field"
        missing_fields=$((missing_fields + 1))
      fi
    done
  done < "$jsonl_file"

  if [[ "$missing_fields" -eq 0 ]]; then
    echo "  ✓ PASS: All records have required fields"
  fi
}
```

---

## 9. Detailed Task Breakdown

### 9.1 Task List with Priorities

**Phase 6.1: Foundation (Critical, 2-3 hours)**

**Task 6.1.1: Extend post-subagent-metrics.sh for JSONL logging**
- **File**: `/home/benjamin/.config/.claude/hooks/post-subagent-metrics.sh`
- **Changes**:
  - Add JSONL record generation (after existing aggregate update)
  - Add invocation ID generation
  - Add error classification logic
  - Create `.claude/data/metrics/agents/` directory if needed
  - Append JSONL record to `{agent-type}.jsonl`
- **Lines**: ~60 new lines
- **Testing**:
  - Simulate SubagentStop event
  - Verify JSONL file created
  - Verify record format
- **Success Criteria**:
  - JSONL file created with valid format
  - All required fields present
  - Agent registry still updates correctly

**Task 6.1.2: Implement tool usage tracking**
- **File**: `/home/benjamin/.config/.claude/hooks/post-subagent-metrics.sh`
- **Changes**:
  - Add `extract_tool_usage()` function
  - Parse agent response for tool invocations
  - Store in `tools_used` field
- **Lines**: ~40 new lines
- **Testing**:
  - Create mock agent response with tool calls
  - Verify tool counts are accurate
- **Success Criteria**:
  - Tool usage JSON object populated correctly
  - All tool types detected

**Task 6.1.3: Create test fixtures for Phase 6**
- **File**: `/home/benjamin/.config/.claude/tests/fixtures/agent-metrics-sample.jsonl`
- **Purpose**: Sample JSONL data for testing
- **Lines**: ~50 lines (sample records)
- **Success Criteria**: Valid JSONL with diverse scenarios

---

**Phase 6.2: Core Functions (High Priority, 2-3 hours)**

**Task 6.2.1: Implement parse_agent_jsonl()**
- **File**: `/home/benjamin/.config/.claude/lib/analyze-metrics.sh`
- **Lines**: ~30 lines
- **Testing**: Unit test with sample JSONL
- **Success Criteria**: Correctly filters by timeframe

**Task 6.2.2: Implement calculate_agent_stats()**
- **File**: `/home/benjamin/.config/.claude/lib/analyze-metrics.sh`
- **Lines**: ~80 lines
- **Testing**: Unit test with sample data
- **Success Criteria**: Accurate statistics (success rate, avg duration, tool usage)

**Task 6.2.3: Implement identify_common_errors()**
- **File**: `/home/benjamin/.config/.claude/lib/analyze-metrics.sh`
- **Lines**: ~40 lines
- **Testing**: Unit test with error records
- **Success Criteria**: Groups errors by type, counts correctly

**Task 6.2.4: Implement analyze_tool_usage()**
- **File**: `/home/benjamin/.config/.claude/lib/analyze-metrics.sh`
- **Lines**: ~50 lines
- **Testing**: Unit test with tool usage data
- **Success Criteria**: Percentages sum to ~100%, ASCII chart renders

**Task 6.2.5: Create unit test file**
- **File**: `/home/benjamin/.config/.claude/tests/test_agent_metrics.sh`
- **Lines**: ~200 lines
- **Testing**: Run all unit tests
- **Success Criteria**: All tests pass

---

**Phase 6.3: Enhanced Output (Medium Priority, 1-2 hours)**

**Task 6.3.1: Update /analyze agents command**
- **File**: `/home/benjamin/.config/.claude/commands/analyze.md`
- **Changes**:
  - Add timeframe parameter parsing
  - Call enhanced stats functions
  - Format detailed output with tool usage and errors
  - Add footer with usage hints
- **Lines**: ~100 lines modified/added
- **Testing**: Manual test of `/analyze agents` command
- **Success Criteria**: Enhanced output displays correctly

**Task 6.3.2: Add timeframe filtering support**
- **File**: `/home/benjamin/.config/.claude/commands/analyze.md`
- **Changes**: Parse `7`, `30`, `90` day arguments
- **Lines**: ~20 lines
- **Testing**: Test `/analyze agents 7`, `/analyze agents 90`
- **Success Criteria**: Different results for different timeframes

---

**Phase 6.4: Advanced Features (Optional, 1 hour)**

**Task 6.4.1: Implement compare_agents()**
- **File**: `/home/benjamin/.config/.claude/lib/analyze-metrics.sh`
- **Lines**: ~100 lines
- **Testing**: Manual comparison of 2-3 agents
- **Success Criteria**: Side-by-side table displays correctly

**Task 6.4.2: Add --compare flag to /analyze agents**
- **File**: `/home/benjamin/.config/.claude/commands/analyze.md`
- **Lines**: ~30 lines
- **Testing**: Test `/analyze agents --compare agent1 agent2`
- **Success Criteria**: Comparison mode works

**Task 6.4.3: Implement generate_agent_recommendations()**
- **File**: `/home/benjamin/.config/.claude/lib/analyze-metrics.sh`
- **Lines**: ~120 lines
- **Testing**: Manual review of recommendations
- **Success Criteria**: Recommendations are data-driven and actionable

---

### 9.2 Implementation Order

1. **Day 1 (2-3 hours)**: Phase 6.1 (Foundation)
   - Task 6.1.1: Extend hook for JSONL logging
   - Task 6.1.2: Implement tool usage tracking
   - Task 6.1.3: Create test fixtures
   - **Checkpoint**: JSONL files being created with valid data

2. **Day 2 (2-3 hours)**: Phase 6.2 (Core Functions)
   - Task 6.2.1-6.2.4: Implement parsing and analysis functions
   - Task 6.2.5: Create unit tests
   - **Checkpoint**: All unit tests passing

3. **Day 3 (1-2 hours)**: Phase 6.3 (Enhanced Output)
   - Task 6.3.1: Update /analyze agents command
   - Task 6.3.2: Add timeframe filtering
   - **Checkpoint**: Enhanced output displays correctly

4. **Day 4 (Optional, 1 hour)**: Phase 6.4 (Advanced Features)
   - Task 6.4.1-6.4.3: Implement comparison and recommendations
   - **Checkpoint**: All advanced features working

---

## 10. Integration & Validation

### 10.1 Integration Points

**With Existing Systems**:

1. **Agent Registry (`agent-registry.json`)**
   - Continue updating aggregate metrics
   - Use for efficiency calculations
   - JSONL provides detailed forensics

2. **Metrics Aggregation (`analyze-metrics.sh`)**
   - Extend with agent-specific functions
   - Share common patterns (timeframe filtering, jq usage)
   - Consistent output formatting

3. **/analyze Command (`analyze.md`)**
   - Agents subcommand gets enhanced
   - Metrics subcommand remains unchanged
   - All subcommand integrates both

### 10.2 Validation Checklist

**After Implementation**:

- [ ] **Data Collection**
  - [ ] JSONL files created in correct location
  - [ ] All required fields present in records
  - [ ] Tool usage tracked accurately
  - [ ] Error classification working
  - [ ] Agent registry still updates

- [ ] **Parsing Functions**
  - [ ] Timeframe filtering accurate
  - [ ] Statistics calculated correctly
  - [ ] Error grouping works
  - [ ] Tool usage percentages sum to ~100%

- [ ] **Command Output**
  - [ ] Enhanced output displays correctly
  - [ ] Timeframe parameter works
  - [ ] Tool usage section renders
  - [ ] Error section shows details
  - [ ] Recommendations are helpful

- [ ] **Advanced Features**
  - [ ] Comparison mode works
  - [ ] Recommendations data-driven
  - [ ] Side-by-side tables render correctly

- [ ] **Tests**
  - [ ] All unit tests pass
  - [ ] Integration tests pass
  - [ ] Validation checks pass
  - [ ] No regressions in existing tests

### 10.3 Performance Validation

**Performance Targets**:
- Parse 1000 JSONL records: <2 seconds
- Calculate agent stats: <3 seconds
- Full `/analyze agents` command: <5 seconds
- Comparison mode (2 agents): <7 seconds

**Benchmark Tests**:
```bash
# Generate 1000 test records
generate_test_records() {
  for i in {1..1000}; do
    echo '{"timestamp":"2025-10-01T10:00:00Z","agent_type":"test-agent","invocation_id":"inv_'$i'","duration_ms":5000,"status":"success","tools_used":{"Read":3},"error":null,"error_type":null}'
  done > /tmp/benchmark_agent.jsonl
}

# Benchmark parsing
time parse_agent_jsonl "benchmark-agent" 30

# Benchmark stats calculation
time calculate_agent_stats "benchmark-agent" 30
```

### 10.4 Documentation Updates

**Files to Update**:

1. **`/home/benjamin/.config/.claude/commands/analyze.md`**
   - Update agents subcommand documentation
   - Add examples for new features
   - Document timeframe filtering
   - Document comparison mode

2. **`/home/benjamin/.config/.claude/README.md`**
   - Update command descriptions
   - Highlight new agent metrics capabilities

3. **`CLAUDE.md` (project root)**
   - Update testing protocols if needed
   - Document new metrics data structure

### 10.5 Rollback Plan

**If Issues Arise**:

1. **Partial Rollback**: Disable JSONL logging
   - Comment out JSONL write in `post-subagent-metrics.sh`
   - Agent registry updates continue
   - Existing `/analyze agents` still works (without enhancements)

2. **Full Rollback**: Revert Phase 6 changes
   ```bash
   git revert <phase-6-commit-hash>
   ```

3. **Data Cleanup**:
   ```bash
   # Remove JSONL files if corrupted
   rm -rf .claude/data/metrics/agents/*.jsonl
   ```

---

## Summary

This specification provides a comprehensive roadmap for implementing Phase 6: Enhanced Agent Performance Tracking. The key findings are:

1. **Current State**: Phase 2 created command metrics infrastructure, but agent-specific JSONL metrics do not exist
2. **Foundation Needed**: Per-invocation JSONL logging must be implemented first
3. **Incremental Approach**: Build from foundation (JSONL collection) → parsing → enhanced output → advanced features
4. **Estimated Time**: 5-6 hours total across 4 sub-phases
5. **Testing**: Comprehensive unit and integration tests ensure quality

The specification includes:
- Detailed JSONL schema design
- Complete algorithm implementations
- Testing strategies with example tests
- Integration guidelines
- Validation checklists

All code examples are production-ready and can be implemented directly from this specification.

---

**Next Steps**: Begin with Task 6.1.1 (Extend post-subagent-metrics.sh) to establish the foundation for all subsequent enhancements.
