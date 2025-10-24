# Alternative Library Sourcing Patterns

## Research Status
- Status: Complete
- Created: 2025-10-24
- Completed: 2025-10-24
- Topic: Alternative approaches for library sourcing in AI agent contexts

## Executive Summary

Analyzed 6 alternative approaches for library sourcing in AI agent contexts to avoid bash escaping failures. Research examined 58 library files, 15+ command implementations, and documented patterns across the codebase.

**Recommended Solution**: Pre-calculate all paths in parent command before delegating to agents (Reliability: 10/10). This approach:
- Eliminates bash sourcing complexity in agent context
- Maintains clear separation of concerns (parent orchestrates, agent executes)
- Leverages existing unified-location-detection.sh library
- Consistent with all existing command patterns (/report, /plan, /orchestrate)

**Key Findings**:
1. All successful commands calculate paths in parent, pass absolute paths to agents
2. Bash escaping issues occur when combining: sourcing + function call + variable capture + JSON parsing in agent context
3. 6 alternatives identified with reliability scores (4/10 to 10/10)
4. Wrapper scripts are viable alternative (9/10) for complex reusable logic
5. Inline path calculation should be avoided (defeats unified library purpose)

**Performance Impact**: Library-based approach maintains 85% token reduction (11k vs 75.6k) and 25x speed improvement over agent-based detection.

## Problem Statement
The /research command fails when attempting to:
1. Source .claude/lib/unified-location-detection.sh
2. Call perform_location_detection function
3. Capture output in a variable

Root cause: Bash escaping issues in AI agent context when combining sourcing + function calls + variable capture.

## Research Findings

### Current Bash Integration Pattern (Successful in Commands)

All workflow commands (/report, /plan, /orchestrate, /research) successfully use this pattern:

**File**: `/home/benjamin/.config/.claude/commands/research.md:84-87`
```bash
# Source unified location detection library
source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/unified-location-detection.sh"

# Perform location detection using unified library
LOCATION_JSON=$(perform_location_detection "$RESEARCH_TOPIC" "false")
```

**Success Factors**:
1. Direct sourcing in bash code block (not in agent context)
2. Simple variable capture with $()
3. No nested quoting or complex escaping
4. Function returns plain JSON string

**Performance**: <1s execution, <11k tokens vs 75.6k for agent-based detection
**Source**: `/home/benjamin/.config/.claude/docs/reference/library-api.md:44-106`

### Why This Fails in Agent Context

When commands delegate to agents, the pattern breaks because:
1. Agents cannot directly source bash libraries
2. Bash tool in agent context requires string escaping
3. Combining source + function call + variable capture creates nested escaping
4. JSON output with quotes creates additional escaping complexity

## Alternatives Analysis

### Alternative 1: Pre-Calculate Paths in Parent Command

**Approach**: Calculate all paths in parent command BEFORE delegating to agent

**Pattern**:
```bash
# In parent command (NOT in agent)
source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/unified-location-detection.sh"
LOCATION_JSON=$(perform_location_detection "$RESEARCH_TOPIC" "false")

# Extract all needed paths
TOPIC_DIR=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
TOPIC_NAME=$(echo "$LOCATION_JSON" | jq -r '.topic_name')
REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')

# Calculate subtopic report paths upfront
SUBTOPIC_1_PATH="${REPORTS_DIR}/001_report_name/001_subtopic_name.md"
SUBTOPIC_2_PATH="${REPORTS_DIR}/001_report_name/002_subtopic_name.md"

# Pass absolute paths to agent (no calculation needed in agent)
invoke_agent "research-specialist" \
  --topic "Subtopic 1" \
  --report-path "$SUBTOPIC_1_PATH"
```

**Pros**:
- Eliminates need for library sourcing in agent context
- Agent receives absolute paths ready to use
- No escaping issues (simple string parameters)
- Clear separation: parent orchestrates, agent executes

**Cons**:
- Parent command must know all paths ahead of time
- Reduces agent flexibility
- Requires parent to handle path calculations

**Examples**: `/home/benjamin/.config/.claude/commands/plan.md:619-623` (fallback pattern)

**Reliability**: 10/10 (no bash complexity in agent)

---

### Alternative 2: Wrapper Script Execution

**Approach**: Create standalone wrapper script that handles sourcing + function call

**Pattern**:
```bash
# Create wrapper: .claude/lib/get-location-json.sh
#!/usr/bin/env bash
source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/unified-location-detection.sh"
perform_location_detection "$1" "${2:-false}"

# Make executable
chmod +x .claude/lib/get-location-json.sh

# In agent context - simple script execution
LOCATION_JSON=$(bash .claude/lib/get-location-json.sh "workflow description")
```

**Pros**:
- Encapsulates sourcing complexity
- Simple one-line invocation in agent
- No nested escaping issues
- Script can be tested independently

**Cons**:
- Requires creating additional wrapper scripts
- Maintenance overhead (2 files instead of 1)
- Less direct than function calls

**Examples**: All 58 libraries in `/home/benjamin/.config/.claude/lib/*.sh` use `#!/usr/bin/env bash` shebang for standalone execution

**Reliability**: 9/10 (adds script creation overhead)

---

### Alternative 3: Multi-Step Sequential Bash Calls

**Approach**: Break sourcing and execution into separate Bash tool calls

**Pattern**:
```bash
# Step 1: Source library (separate call)
source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/unified-location-detection.sh"

# Step 2: Execute function (separate call, wait for step 1)
LOCATION_JSON=$(perform_location_detection "$TOPIC" "false")
```

**Pros**:
- Separates concerns (sourcing vs execution)
- Each step simpler to escape
- May avoid nested complexity

**Cons**:
- Unclear if Bash tool maintains environment between calls
- May require session management
- Not proven pattern in existing codebase

**Examples**: `/home/benjamin/.config/.claude/commands/implement.md:686-688` shows sequential sourcing + execution pattern works in commands

**Reliability**: 6/10 (unproven in agent context)

---

### Alternative 4: Temporary File Communication

**Approach**: Write function output to temp file, read in agent

**Pattern**:
```bash
# Parent command: Write location to temp file
TEMP_LOCATION=$(mktemp)
source .claude/lib/unified-location-detection.sh
perform_location_detection "$TOPIC" > "$TEMP_LOCATION"

# Agent: Read from temp file
LOCATION_JSON=$(cat "$TEMP_LOCATION")
TOPIC_DIR=$(echo "$LOCATION_JSON" | jq -r '.topic_path')

# Cleanup
rm "$TEMP_LOCATION"
```

**Pros**:
- No escaping issues (file I/O is simple)
- Proven pattern for data passing
- Agent context doesn't need bash complexity

**Cons**:
- Requires temp file management
- Cleanup complexity (trap handlers)
- More moving parts to fail

**Examples**:
- `/home/benjamin/.config/.claude/lib/checkbox-utils.sh:38` - `mktemp` for temp file creation
- `/home/benjamin/.config/.claude/lib/checkbox-utils.sh:192-233` - Multiple temp file usage patterns
- `/home/benjamin/.config/.claude/lib/substitute-variables.sh:18-21` - Temp file with trap cleanup

**Reliability**: 7/10 (proven but adds complexity)

---

### Alternative 5: Environment Variable Export

**Approach**: Parent sets environment variables, agent reads them

**Pattern**:
```bash
# Parent command: Export location data
source .claude/lib/unified-location-detection.sh
LOCATION_JSON=$(perform_location_detection "$TOPIC")
export TOPIC_DIR=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
export TOPIC_NAME=$(echo "$LOCATION_JSON" | jq -r '.topic_name')
export REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')

# Agent: Read from environment
REPORT_PATH="${REPORTS_DIR}/001_report.md"
```

**Pros**:
- Simple read access in agent
- No file I/O overhead
- Standard Unix pattern

**Cons**:
- Environment scope unclear in agent context
- May not persist across Bash tool calls
- Limited examples in codebase

**Examples**:
- `/home/benjamin/.config/.claude/lib/validate-orchestrate.sh:15` - `export CLAUDE_PROJECT_DIR`
- Only 1 instance found in entire `.claude/lib/` directory

**Reliability**: 4/10 (unclear scope in agent context)

---

### Alternative 6: Inline Path Calculation

**Approach**: Duplicate path calculation logic in agent (avoid library entirely)

**Pattern**:
```bash
# In agent: Inline minimal path logic (no external dependencies)
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SPECS_DIR="${PROJECT_ROOT}/.claude/specs"
TOPIC_NAME=$(echo "$RESEARCH_TOPIC" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | sed 's/[^a-z0-9_]//g')
TOPIC_NUM=$(ls -1d ${SPECS_DIR}/*_${TOPIC_NAME} 2>/dev/null | tail -1 | grep -o '[0-9]*' | head -1)
TOPIC_DIR="${SPECS_DIR}/${TOPIC_NUM}_${TOPIC_NAME}"
```

**Pros**:
- No external dependencies
- No sourcing/escaping issues
- Self-contained agent logic

**Cons**:
- Code duplication (violates DRY)
- Must maintain logic in multiple places
- Loses benefits of unified library
- Error-prone (subtle differences in implementations)

**Examples**: This was the OLD pattern before unified-location-detection.sh was created. Commands had duplicate logic.

**Reliability**: 8/10 (works but defeats purpose of library)

---

## Recommendations

### Rank 1: Pre-Calculate Paths in Parent Command (RECOMMENDED)

**Why**: Cleanest separation of concerns, no escaping issues, leverages existing library

**Implementation**:
```bash
# In /research command (parent), BEFORE delegating to agents:

# Step 1: Calculate main topic directory (already done)
source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/unified-location-detection.sh"
LOCATION_JSON=$(perform_location_detection "$RESEARCH_TOPIC" "false")
TOPIC_DIR=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')

# Step 2: EXECUTE NOW - Calculate ALL subtopic report paths upfront
MAIN_REPORT_DIR="${REPORTS_DIR}/$(printf '%03d' 1)_${SANITIZED_MAIN_TOPIC_NAME}"
mkdir -p "$MAIN_REPORT_DIR"  # Create parent directory

# Step 3: Pre-calculate absolute paths for each subtopic
for i in $(seq 1 $NUM_SUBTOPICS); do
  SUBTOPIC_PATH="${MAIN_REPORT_DIR}/$(printf '%03d' $i)_${SANITIZED_SUBTOPIC_NAMES[$i]}.md"
  SUBTOPIC_PATHS[$i]="$SUBTOPIC_PATH"
done

# Step 4: Pass absolute paths to agent (no calculation needed)
invoke_agent "research-specialist" \
  --topic "$SUBTOPIC_1" \
  --report-path "${SUBTOPIC_PATHS[1]}"
```

**Advantages over current approach**:
- Parent command handles ALL path logic (orchestration responsibility)
- Agents receive absolute paths as simple strings (execution responsibility)
- No bash complexity in agent context
- Consistent with existing command patterns

**Evidence**: All commands using unified-location-detection.sh do calculation in parent command, not in agents.

---

### Rank 2: Wrapper Script Execution

**Why**: Encapsulates complexity, proven pattern with executable scripts

**Implementation**:
```bash
# Create: .claude/lib/calculate-report-path.sh
#!/usr/bin/env bash
MAIN_REPORT_DIR="$1"
SUBTOPIC_NUMBER="$2"
SUBTOPIC_NAME="$3"
SANITIZED=$(echo "$SUBTOPIC_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | sed 's/[^a-z0-9_]//g')
echo "${MAIN_REPORT_DIR}/$(printf '%03d' $SUBTOPIC_NUMBER)_${SANITIZED}.md"

# Make executable
chmod +x .claude/lib/calculate-report-path.sh

# In agent context:
REPORT_PATH=$(bash .claude/lib/calculate-report-path.sh "$MAIN_REPORT_DIR" "1" "$SUBTOPIC_NAME")
```

**Use when**: Path calculation logic is complex and reusable across multiple commands

---

### Rank 3: Temporary File Communication

**Why**: Fallback for complex data structures, proven pattern in checkbox-utils.sh

**Use when**: Passing complex JSON or multi-line data between parent and agent

**Implementation**: See Alternative 4 pattern above with trap cleanup

---

### Rank 4: Inline Path Calculation (NOT RECOMMENDED)

**Why**: Defeats purpose of unified library, creates maintenance burden

**Only use when**: Absolute last resort, all other options exhausted

---

## Implementation Decision Matrix

| Scenario | Recommended Approach | Rationale |
|----------|---------------------|-----------|
| Simple path calculation | Pre-calculate in parent | No complexity needed in agent |
| Complex reusable logic | Wrapper script | Encapsulation + testability |
| Multi-line data passing | Temp file communication | Avoids escaping issues |
| Emergency fix needed | Inline calculation | Quick fix (refactor later) |

## References

### Successful Patterns

1. **Unified Location Detection in Commands**:
   - `/home/benjamin/.config/.claude/commands/research.md:84-87`
   - `/home/benjamin/.config/.claude/commands/plan.md:485`
   - `/home/benjamin/.config/.claude/commands/orchestrate.md:428-431`

2. **Fallback Directory Creation**:
   - `/home/benjamin/.config/.claude/commands/plan.md:619-623`
   - Shows ensure_artifact_directory pattern after sourcing

3. **Temporary File Patterns**:
   - `/home/benjamin/.config/.claude/lib/checkbox-utils.sh:38,192,231,237,295`
   - `/home/benjamin/.config/.claude/lib/substitute-variables.sh:18-21`
   - `/home/benjamin/.config/.claude/lib/plan-core-bundle.sh:199,242,289,334,378,408,450,494,548,569-570`

4. **Sequential Sourcing + Execution**:
   - `/home/benjamin/.config/.claude/commands/implement.md:686-688`
   - Shows pattern works in command context

5. **Executable Script Pattern**:
   - All 58 libraries in `/home/benjamin/.config/.claude/lib/*.sh` use `#!/usr/bin/env bash`
   - Support both sourcing AND standalone execution

### Library Documentation

1. **Library API Reference**:
   - `/home/benjamin/.config/.claude/docs/reference/library-api.md:44-106`
   - Complete perform_location_detection documentation

2. **Unified Location Detection Implementation**:
   - `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:1-100`
   - Core functions: detect_project_root, detect_specs_directory, perform_location_detection

### Performance Metrics

- **Library-based detection**: <1s, <11k tokens
- **Agent-based detection**: 75.6k tokens baseline
- **Token reduction**: 85% (11k vs 75.6k)
- **Speed improvement**: 25x faster

**Source**: `/home/benjamin/.config/.claude/docs/reference/library-api.md:45`
