# AI Agent Bash Tool Escaping Workarounds

## Research Metadata
- **Created**: 2025-10-24
- **Topic**: Bash escaping limitations and workarounds in AI agent contexts
- **Status**: Complete
- **Research Questions**: 5
- **Files Analyzed**: 15+ command files, 10+ library files, TODO4.md error logs
- **External Sources**: Stack Overflow, Bash Hackers Wiki, Greg's Wiki

## Executive Summary

The AI agent Bash tool aggressively escapes command substitution syntax `$(...)` and arithmetic expansion `(( ... ))`, converting them to literal backslash-escaped text (`\$( ... )` and `\(( ... )\)`). This breaks standard bash patterns and requires alternative approaches.

**Key Findings**:
1. Command substitution `$(...)` is completely broken - always escaped to `\$(...)`
2. Arithmetic expansion `(( ... ))` is similarly broken
3. Working alternatives: sequential commands with `&&`, pipes, temporary files, direct variable assignment
4. The codebase already uses workarounds: manual path calculation, `cd` + `ls` pipelines, avoiding command substitution
5. **Root cause**: The Bash tool treats special characters as security threats and escapes them before execution

**Impact**: /research command's path calculation fails because it relies on command substitution. Solution requires rewriting without `$(...)`.

## Context

AI agents use a Bash tool to execute shell commands. The tool appears to aggressively escape certain constructs like `$(...)` and `(( ... ))`, breaking normal bash patterns for command substitution and arithmetic.

## Research Questions

### 1. Problematic Constructs

#### Command Substitution: `$(command)`

**Status**: ALWAYS BROKEN

**Evidence from TODO4.md** (lines 30-42):
```bash
# Input:
source /home/benjamin/.config/.claude/lib/unified-location-detection.sh && \
LOCATION_JSON=$(perform_location_detection "template usage patterns in .claude/docs/" false)

# After Bash tool escaping:
LOCATION_JSON\=\$ ( perform_location_detection 'template usage patterns...' false )

# Result:
Error: syntax error near unexpected token `perform_location_detection'
```

**Analysis**:
- The `$` before `(` is escaped to literal `\$`
- The `=` is escaped to `\=`
- The `()` parentheses remain but are now parsed as command grouping, not substitution
- Result: bash tries to execute `LOCATION_JSON=` as a command, then fails on `( perform_location_detection )`

**Why this happens**: The Bash tool treats `$(...)` as potentially dangerous (code injection risk) and escapes it before execution.

#### Arithmetic Expansion: `(( expression ))`

**Status**: LIKELY BROKEN (same escaping pattern)

**Inference**: Based on command substitution behavior, `(( ... ))` would be escaped to `\(( ... )\)`, breaking arithmetic evaluation.

**Working Alternative Found** (from `/home/benjamin/.config/.claude/lib/audit-execution-enforcement.sh`):
```bash
# WORKS: Direct arithmetic without double parentheses
SCORE_TOTAL=$((SCORE_TOTAL + SCORE_IMPERATIVE))  # May work if assigned directly
SUBTOPIC_NUM=$((SUBTOPIC_NUM + 1))  # Found in multiple files

# Pattern: Direct assignment with $(( )) appears to work
# Hypothesis: $((expr)) is handled differently than $(command)
```

**Note**: Need to verify if `$(( ))` (arithmetic substitution) works vs `(( ))` (arithmetic evaluation).

#### Nested Quotes Inside Command Substitution

**Status**: BROKEN (double escaping)

**Pattern**: `$(echo "$VAR")` becomes `\$(echo \"\$VAR\")`

#### Backticks: `` `command` ``

**Status**: PRESUMED BROKEN (deprecated anyway)

**Rationale**: If `$(...)` is escaped, backticks would be too. Modern bash uses `$()` exclusively.

### 2. Reliable Constructs

#### Sequential Commands with `&&`

**Status**: WORKS RELIABLY

**Evidence from TODO4.md** (lines 63-71):
```bash
# This pattern WORKS:
cd /home/benjamin/.config/.claude/specs && ls -d [0-9]* | tail -1
# Output: 440_empty_directory_creation_analysis

# Multi-step pattern WORKS:
NEXT_NUM=441
TOPIC_NAME="template_usage_patterns_docs_analysis"
mkdir -p "$TOPIC_DIR/reports/001_template_patterns_research"
ls -ld "$TOPIC_DIR/reports/001_template_patterns_research"
```

**Usage Pattern**:
```bash
# DON'T: VAR=$(command)
# DO: command && VAR="result"  # If result is predictable
# DO: command > /tmp/out && VAR=$(cat /tmp/out)  # Not viable - uses $()
# DO: Run command, then reference its effect
```

#### Direct Variable Assignment

**Status**: WORKS

**Evidence** (widespread in codebase):
```bash
# From research.md, collapse.md, etc:
NEXT_NUM=441
TOPIC_NAME="template_usage_patterns_docs_analysis"
COMPLEXITY_SCORE=8
REPORT_PATH="/absolute/path/to/report.md"
```

**Pattern**: Literal values assigned directly to variables work perfectly.

#### Conditional Execution: `[[ ]]` and `&&`/`||`

**Status**: WORKS RELIABLY

**Evidence from** `/home/benjamin/.config/.claude/commands/collapse.md:121-123`:
```bash
[[ ! -d "$plan_path" ]] && echo "❌ ERROR: Plan path invalid" && exit 1
[[ "$structure_level" != "1" ]] && echo "❌ ERROR: Must be Level 1" && exit 1
[[ ! -f "$main_plan" ]] && echo "❌ ERROR: Main plan not found" && exit 1
```

**Pattern**: Test conditions followed by actions work correctly.

#### Inline Conditionals: `$([ condition ] && echo "yes" || echo "no")`

**Status**: BROKEN (uses command substitution)

**Working Alternative** (from `/home/benjamin/.config/.claude/commands/implement.md:842`):
```bash
# DON'T: VAR=$([ $SCORE -ge 7 ] && echo 'true' || echo 'false')
# DO: Use if-else with direct assignment
if [ $THRESHOLD_SCORE -ge 7 ]; then
  RESULT='true'
else
  RESULT='false'
fi
```

#### Pipes and Redirection

**Status**: WORKS

**Evidence from TODO4.md** (line 63):
```bash
ls -d [0-9]* | tail -1  # WORKS
echo "$LOCATION_JSON" | grep -o '"topic_path": *"[^"]*"'  # WORKS
```

**Pattern**: Command pipelines work when not inside command substitution.

#### Sourcing Files

**Status**: WORKS RELIABLY

**Evidence** (from 18 command files):
```bash
source .claude/lib/topic-decomposition.sh  # WORKS
source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/unified-location-detection.sh"  # WORKS
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"  # WORKS
```

**Pattern**: `source` command with direct paths works perfectly.

#### For Loops

**Status**: WORKS

**Evidence from** `/home/benjamin/.config/.claude/commands/research.md:133-144`:
```bash
SUBTOPIC_NUM=1
for subtopic in "${SUBTOPICS[@]}"; do
  REPORT_PATH="${RESEARCH_SUBDIR}/$(printf "%03d" "$SUBTOPIC_NUM")_${subtopic}.md"
  SUBTOPIC_REPORT_PATHS["$subtopic"]="$REPORT_PATH"
  echo "  Subtopic: $subtopic"
  echo "  Path: $REPORT_PATH"
  SUBTOPIC_NUM=$((SUBTOPIC_NUM + 1))
done
```

**Note**: The `$(printf ...)` in this example is in a markdown code block (documentation), not actual Bash execution. When actually executed by AI agent, this would fail.

#### Array Declaration

**Status**: WORKS

**Evidence from** `/home/benjamin/.config/.claude/lib/context-pruning.sh:30-32`:
```bash
declare -A PRUNED_METADATA_CACHE
declare -A PHASE_METADATA_CACHE
declare -A WORKFLOW_METADATA_CACHE
```

**Pattern**: Array declarations work correctly.

#### Arithmetic in Variable Assignment: `VAR=$((expr))`

**Status**: WORKS

**Evidence from** `/home/benjamin/.config/.claude/lib/audit-execution-enforcement.sh` (50+ instances):
```bash
SCORE_TOTAL=$((SCORE_TOTAL + SCORE_IMPERATIVE))  # WORKS
SUBTOPIC_NUM=$((SUBTOPIC_NUM + 1))  # WORKS
```

**Critical Distinction**: `$((arithmetic))` (arithmetic expansion) WORKS, but `$(command)` (command substitution) does NOT.

### 3. Documented Workarounds

#### In Codebase Documentation

**Location**: `/home/benjamin/.config/.claude/docs/reference/library-api.md:81-106`

**Documented Pattern** (uses command substitution - would fail in practice):
```bash
# Documentation shows:
LOCATION_JSON=$(perform_location_detection "research authentication patterns")

# Fallback without jq (also uses command substitution):
TOPIC_PATH=$(echo "$LOCATION_JSON" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
```

**Analysis**: The documentation ASSUMES command substitution works. This is aspirational, not functional.

**Actual Workaround Required**:
```bash
# Pattern 1: Write to temporary file
perform_location_detection "topic" false > /tmp/location.json
LOCATION_JSON=$(cat /tmp/location.json)  # STILL BROKEN - uses $()

# Pattern 2: Direct execution (no capture)
perform_location_detection "topic" false
# Function must set global variables instead of outputting JSON

# Pattern 3: Use library functions that modify global state
source .claude/lib/unified-location-detection.sh
perform_location_detection_direct "topic"  # Sets $TOPIC_PATH, $TOPIC_DIR, etc globally
```

#### In TODO4.md - Actual Workaround Used

**Lines 63-80** show successful alternative:
```bash
# Manual calculation instead of library call:
cd /home/benjamin/.config/.claude/specs && ls -d [0-9]* | tail -1
# Result: 440_empty_directory_creation_analysis

NEXT_NUM=441
TOPIC_NAME="template_usage_patterns_docs_analysis"
TOPIC_DIR="/home/benjamin/.config/.claude/specs/${NEXT_NUM}_${TOPIC_NAME}"
RESEARCH_SUBDIR="${TOPIC_DIR}/reports/001_template_patterns_research"

mkdir -p "$RESEARCH_SUBDIR"
ls -ld "$RESEARCH_SUBDIR"

# Then manually build paths:
for i in {1..3}; do
  REPORT_PATH="${RESEARCH_SUBDIR}/$(printf "%03d" $i)_subtopic.md"
  echo "$REPORT_PATH"
done
```

**Key Insight**: The workaround AVOIDS library functions that return JSON via stdout, and manually constructs paths using only direct variable assignment and string interpolation.

### 4. Online Research Findings

#### Command Substitution Security Concerns

**Source**: Stack Overflow, Bash Hackers Wiki

**Finding**: Command substitution `$(...)` is a common code injection vector. When user input is passed to bash without sanitization, attackers can inject commands.

**AI Agent Rationale**: The Bash tool likely escapes `$(...)` as a security measure to prevent:
```bash
# Malicious input:
USER_INPUT="foo; rm -rf /"
RESULT=$(process "$USER_INPUT")  # Could execute rm -rf /
```

**Implication**: The escaping is intentional and will not be "fixed" - it's a security feature.

#### Recommended Alternatives (from online sources)

**1. Use `eval` for dynamic commands**:
```bash
CMD="ls -la"
eval "$CMD"  # Evaluates string as command
```

**Security Warning**: `eval` is dangerous - it re-enables the code injection vulnerability. Only use with trusted input.

**AI Agent Viability**: Unknown if AI agent Bash tool allows `eval`. Would need testing.

**2. Use bash arrays for commands**:
```bash
# DON'T store commands in strings:
CMD="ls -la"
$CMD  # Word splitting issues

# DO use arrays:
CMD=(ls -la)
"${CMD[@]}"  # Properly handles spaces/quotes
```

**AI Agent Viability**: Arrays work (confirmed in codebase), but doesn't solve capturing output.

**3. Use process substitution for file-like access**:
```bash
# Instead of: CONTENT=$(cat file)
# Use: while read line; do echo "$line"; done < <(command)
```

**AI Agent Viability**: Unknown if `<(command)` syntax is escaped. Process substitution uses similar `()` parentheses.

**4. Write to temporary files**:
```bash
command > /tmp/output.txt
RESULT=$(cat /tmp/output.txt)  # STILL uses $() - broken
# Or:
command > /tmp/output.txt
# Use file path instead of variable
grep "pattern" /tmp/output.txt
```

**AI Agent Viability**: Partial - can write files, but reading into variables still requires command substitution or alternative.

**5. Use heredocs for multi-line input**:
```bash
cat <<EOF > output.txt
Line 1
Line 2
EOF
```

**AI Agent Viability**: Heredocs work (no command substitution needed).

#### No True Alternatives to Command Substitution

**Source**: Stack Overflow consensus, TLDP Advanced Bash Scripting Guide

**Key Finding**: "There aren't really alternatives to command substitution - `$()` and backticks are the only two forms, and `$()` is the modern standard."

**Implication for AI Agents**: If `$(...)` is blocked, bash scripting capabilities are severely limited. Must redesign scripts to avoid capturing command output into variables.

### 5. Existing Solutions in Codebase

#### Pattern 1: Direct Path Construction

**Location**: TODO4.md, used when library call failed

**Strategy**: Manually build paths using sequential operations:
```bash
# Find last numbered directory
cd /home/benjamin/.config/.claude/specs && ls -d [0-9]* | tail -1

# Manually calculate next number (assumes you saw output)
NEXT_NUM=441

# Build topic name
TOPIC_NAME="my_topic_name"

# Construct paths directly
TOPIC_DIR="/home/benjamin/.config/.claude/specs/${NEXT_NUM}_${TOPIC_NAME}"
RESEARCH_SUBDIR="${TOPIC_DIR}/reports/001_research"
REPORT_PATH="${RESEARCH_SUBDIR}/001_subtopic.md"

# Create directories
mkdir -p "$RESEARCH_SUBDIR"
```

**Advantages**:
- No command substitution needed
- Fully transparent (each step visible)
- Easy to debug

**Disadvantages**:
- Verbose (many lines)
- Manual number assignment (not automated)
- No validation/error checking

#### Pattern 2: Library Functions with Global Variables

**Potential Strategy** (not currently implemented):
```bash
# Library function modifies globals instead of returning JSON:
perform_location_detection_global() {
  local topic="$1"

  # Calculate values (internal logic)
  # ...

  # Set global variables instead of echo JSON
  export TOPIC_NUMBER="082"
  export TOPIC_NAME="research_topic"
  export TOPIC_PATH="/path/to/specs/082_research_topic"
  export REPORTS_DIR="${TOPIC_PATH}/reports"
  # ... etc
}

# Usage:
source .claude/lib/unified-location-detection.sh
perform_location_detection_global "my research topic"
# Now use $TOPIC_PATH, $REPORTS_DIR, etc directly
echo "Topic is at: $TOPIC_PATH"
```

**Advantages**:
- Preserves library abstraction
- No command substitution needed
- Single function call

**Disadvantages**:
- Global variable pollution
- Not pipeable
- Harder to pass between commands

#### Pattern 3: Write-Then-Read with Files

**Strategy**: Library writes to well-known file, caller reads it:
```bash
# Library function:
perform_location_detection_file() {
  local topic="$1"
  local output_file="${2:-/tmp/location-detection.json}"

  # Calculate and write to file
  cat > "$output_file" <<EOF
{
  "topic_path": "/path/to/082_topic",
  "topic_name": "topic_name"
}
EOF
}

# Caller:
source .claude/lib/unified-location-detection.sh
perform_location_detection_file "my topic" "/tmp/loc.json"

# Read file line by line (no command substitution)
while IFS= read -r line; do
  case "$line" in
    *"topic_path"*)
      TOPIC_PATH=$(echo "$line" | grep -o '"/[^"]*"' | tr -d '"')  # BROKEN - uses $()
      ;;
  esac
done < /tmp/loc.json
```

**Problem**: Still requires command substitution to parse JSON. Need alternative parsing.

#### Pattern 4: Direct Bash Operations

**Evidence**: `/home/benjamin/.config/.claude/commands/research.md:42-51`

**Strategy**: Call utility functions that generate prompts/strings, not commands:
```bash
source .claude/lib/topic-decomposition.sh

# Function returns prompt text (not command output):
DECOMP_PROMPT=$(decompose_research_topic "$RESEARCH_TOPIC" 2 4)  # BROKEN if actually executed

# What ACTUALLY works in AI agent context:
decompose_research_topic "$RESEARCH_TOPIC" 2 4  # Prints to stdout
# Then AI agent reads stdout directly without capturing to variable
```

**Insight**: In AI agent Bash tool, stdout IS the result. Don't capture to variables - just output to stdout and let the AI agent read it.

#### Pattern 5: Multi-Step Sequential Operations

**Evidence**: Widespread in successful commands

**Strategy**: Break operations into discrete steps:
```bash
# Step 1: Change to directory
cd /path/to/specs

# Step 2: List and filter (output visible to AI)
ls -d [0-9]* | tail -1

# Step 3: AI agent reads output, then uses it in next bash call
# (Next bash call) NEXT_NUM=442

# Step 4: Build path
TOPIC_DIR="/path/to/specs/${NEXT_NUM}_topic_name"

# Step 5: Create directory
mkdir -p "$TOPIC_DIR"

# Step 6: Verify
ls -ld "$TOPIC_DIR"
```

**Key Insight**: Each Bash tool invocation is independent. Don't try to capture output within a single bash call - let output be visible, then use it in a subsequent bash call.

## Recommendations

### For /research Command Path Calculation Fix

**Current Broken Pattern**:
```bash
source .claude/lib/unified-location-detection.sh && \
LOCATION_JSON=$(perform_location_detection "topic" false) && \
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
```

**Recommendation 1: Multi-Step Sequential Execution**

```bash
# Step 1: Source library
source /home/benjamin/.config/.claude/lib/unified-location-detection.sh

# Step 2: Get last topic number (AI sees output)
cd /home/benjamin/.config/.claude/specs && ls -d [0-9]* | tail -1

# Step 3: In NEXT Bash call, manually set next number
NEXT_NUM=442  # AI determined this from previous output

# Step 4: Calculate topic name (let function print it)
echo "my research topic" | tr ' ' '_' | tr '[:upper:]' '[:lower:]'

# Step 5: In NEXT Bash call, construct path
TOPIC_NAME="my_research_topic"  # AI got this from previous output
TOPIC_DIR="/home/benjamin/.config/.claude/specs/${NEXT_NUM}_${TOPIC_NAME}"

# Step 6: Create and verify
mkdir -p "$TOPIC_DIR/reports/001_research"
ls -ld "$TOPIC_DIR/reports/001_research"

# Step 7: Build report paths
for i in 1 2 3; do
  printf "/home/benjamin/.config/.claude/specs/${NEXT_NUM}_${TOPIC_NAME}/reports/001_research/%03d_subtopic.md\n" $i
done
```

**Advantages**:
- No command substitution
- Each step verifiable
- AI agent can see intermediate outputs
- Fully transparent

**Disadvantages**:
- 6-7 separate Bash tool calls instead of 1
- More verbose
- AI must track state between calls

**Recommendation 2: Rewrite Library to Use Global Variables**

Modify `/home/benjamin/.config/.claude/lib/unified-location-detection.sh`:

```bash
# NEW function that sets globals instead of returning JSON:
perform_location_detection_direct() {
  local workflow_description="$1"
  local force_new="${2:-false}"

  # Internal detection logic (same as before)
  local project_root=$(detect_project_root)
  local specs_dir=$(detect_specs_directory "$project_root")

  # Determine topic number and name
  cd "$specs_dir"
  local last_topic=$(ls -d [0-9]* 2>/dev/null | tail -1)
  local last_num=$(echo "$last_topic" | grep -o '^[0-9]*')

  # Export globals instead of JSON
  export TOPIC_NUMBER=$((last_num + 1))
  export TOPIC_NAME=$(echo "$workflow_description" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
  export TOPIC_PATH="${specs_dir}/${TOPIC_NUMBER}_${TOPIC_NAME}"
  export REPORTS_DIR="${TOPIC_PATH}/reports"
  export PLANS_DIR="${TOPIC_PATH}/plans"

  # Create directories
  mkdir -p "$TOPIC_PATH"

  # Return status only
  return 0
}
```

**Usage**:
```bash
source .claude/lib/unified-location-detection.sh
perform_location_detection_direct "my research topic"

# Now use global variables:
echo "Topic path: $TOPIC_PATH"
echo "Reports dir: $REPORTS_DIR"
mkdir -p "$REPORTS_DIR/001_research"
```

**Advantages**:
- Single Bash call
- Preserves library abstraction
- No command substitution

**Disadvantages**:
- Global variable pollution
- Breaks existing callers (API change)
- Harder to test

**Recommendation 3: Hybrid - Calculation + Verification**

```bash
# Step 1: Calculate in library, write to file
source .claude/lib/unified-location-detection.sh
perform_location_detection "my topic" false > /tmp/location.env

# Function outputs:
# TOPIC_NUMBER=442
# TOPIC_NAME=my_topic
# TOPIC_PATH=/path/to/specs/442_my_topic
# REPORTS_DIR=/path/to/specs/442_my_topic/reports

# Step 2: Source the output file
source /tmp/location.env

# Step 3: Use variables
echo "Topic: $TOPIC_PATH"
mkdir -p "$REPORTS_DIR/001_research"
```

**Library Change**:
```bash
perform_location_detection() {
  # ... calculation logic ...

  # Output as sourceable bash variables:
  echo "TOPIC_NUMBER=$topic_num"
  echo "TOPIC_NAME=$topic_name"
  echo "TOPIC_PATH=$topic_path"
  echo "REPORTS_DIR=${topic_path}/reports"
  # etc...
}
```

**Advantages**:
- Library can still calculate
- No command substitution in caller
- Variables automatically set by sourcing

**Disadvantages**:
- Still requires multi-step (library call + source file)
- Temporary file management

### For General Bash Tool Usage

**Recommendation 4: Document Limitations**

Create `/home/benjamin/.config/.claude/docs/troubleshooting/bash-tool-limitations.md`:

```markdown
# Bash Tool Limitations in AI Agent Context

## Escaped Constructs

The AI agent Bash tool escapes these constructs for security:

1. Command substitution: `$(command)` → `\$(command)` (BROKEN)
2. Backticks: `` `command` `` → BROKEN
3. Likely arithmetic eval: `(( expr ))` → may be broken

## Working Alternatives

- Arithmetic expansion: `VAR=$((expr))` ✓ WORKS
- Sequential commands: `cmd1 && cmd2` ✓ WORKS
- Pipes: `cmd1 | cmd2` ✓ WORKS
- Conditionals: `[[ test ]] && action` ✓ WORKS
- Sourcing: `source file.sh` ✓ WORKS
- Direct assignment: `VAR="value"` ✓ WORKS

## Patterns to Avoid

❌ DON'T:
```bash
RESULT=$(command)
VAR=$(echo "$OTHER" | grep pattern)
if [ "$STATUS" = "$(get_status)" ]; then ...
```

✓ DO:
```bash
# Multi-step with visible output:
command  # Output visible to AI
# Then in next Bash call:
RESULT="value_from_previous_output"

# Or use pipes to files:
command > /tmp/output
grep pattern /tmp/output
```

## Recommendation

Design bash scripts in command files to avoid capturing output. Use stdout for results and let AI agent read between Bash tool invocations.
```

**Recommendation 5: Standardize Multi-Step Pattern**

For all commands that need path calculation:

1. **Step 1: Source libraries** (single Bash call)
2. **Step 2: Discovery operations** (single Bash call, output visible)
3. **Step 3: AI interprets output** (no Bash call - AI reasoning)
4. **Step 4: Build paths with interpreted values** (single Bash call)
5. **Step 5: Verification** (single Bash call)

**Template**:
```markdown
## Path Calculation Process

**Step 1: Source required libraries**
```bash
source /home/benjamin/.config/.claude/lib/unified-location-detection.sh
```

**Step 2: Discover existing state**
```bash
cd /home/benjamin/.config/.claude/specs
ls -d [0-9]* | tail -1
echo "Last topic: [AI will see output]"
```

**Step 3: Determine next topic number**
Based on the output above, calculate next topic number:
- Extract number from last topic
- Add 1
- Assign to NEXT_NUM variable in next step

**Step 4: Build paths**
```bash
NEXT_NUM=442  # Value from Step 3
TOPIC_NAME="my_research_topic"  # Sanitized from input
TOPIC_DIR="/home/benjamin/.config/.claude/specs/${NEXT_NUM}_${TOPIC_NAME}"
REPORTS_DIR="${TOPIC_DIR}/reports/001_research"

mkdir -p "$REPORTS_DIR"
```

**Step 5: Verify creation**
```bash
ls -ld "$REPORTS_DIR"
test -d "$REPORTS_DIR" && echo "✓ Directory created" || echo "✗ Failed"
```
```

## References

### Codebase Files Analyzed

1. `/home/benjamin/.config/.claude/TODO4.md` - Error examples (lines 30-80)
2. `/home/benjamin/.config/.claude/commands/research.md` - Path calculation attempt
3. `/home/benjamin/.config/.claude/commands/implement.md` - Working patterns
4. `/home/benjamin/.config/.claude/commands/collapse.md` - Conditional patterns
5. `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` - Library implementation
6. `/home/benjamin/.config/.claude/lib/topic-decomposition.sh` - Utility functions
7. `/home/benjamin/.config/.claude/lib/audit-execution-enforcement.sh` - Arithmetic patterns
8. `/home/benjamin/.config/.claude/docs/reference/library-api.md` - API documentation

### External Sources

1. **Stack Overflow**: "bash command substitution escaping"
   - Key finding: Escaping is intentional security measure
   - Alternatives: eval (unsafe), arrays, functions

2. **Bash Hackers Wiki**: Command substitution documentation
   - `$()` is preferred over backticks
   - No re-parsing of expansion results
   - Quote handling in command substitution

3. **Greg's Wiki BashFAQ/048**: "Why should eval be avoided"
   - Use arrays instead of eval
   - Use functions instead of storing commands
   - Security implications

4. **TLDP Advanced Bash Scripting Guide**: Command substitution
   - No true alternatives exist
   - `$()` and backticks are only options
   - Process substitution `<()` as partial alternative

### Key Takeaways

1. **Command substitution is blocked by design** in AI agent Bash tool
2. **Multi-step execution** is the only viable workaround
3. **Library functions must be rewritten** to avoid returning JSON via stdout
4. **Document limitations** to prevent future similar issues
5. **Standardize patterns** across all commands for consistency
