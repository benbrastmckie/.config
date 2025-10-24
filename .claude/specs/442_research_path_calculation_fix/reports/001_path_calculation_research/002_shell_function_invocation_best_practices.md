# Shell Function Invocation Best Practices

## Research Overview

**Topic**: Best practices for shell function invocation in AI agent contexts
**Created**: 2025-10-24
**Status**: Complete

## Executive Summary

This report analyzes best practices for shell function invocation with focus on command substitution patterns, error handling, and complex data return patterns. Analysis of 65+ shell library files in `.claude/lib/` reveals consistent patterns: `$()` syntax universally preferred over backticks (100% usage), robust error handling with `-z` checks and `|| echo ""` fallbacks, and JSON-based complex data return via stdout. Key findings: command substitution provides independent quoting contexts preventing escaping issues, `local` declarations can mask function exit codes requiring explicit status checks, and AI agent contexts benefit from defensive patterns like fallback values and explicit error messages. Performance analysis shows 85% token reduction with metadata-only passing vs full content passing in hierarchical agent workflows.

## Research Questions

1. What are the most robust patterns for capturing function output?
2. How should functions return complex data (JSON, arrays, etc.)?
3. What are common pitfalls with command substitution in AI agent contexts?
4. Are there alternative patterns that avoid `$(...)` syntax entirely?

## Findings

### 1. Command Substitution Patterns: `$()` vs Backticks

**Industry Standard: Use `$()` exclusively**

The `$()` form is the POSIX-standard replacement for backticks and is universally preferred in modern bash scripting:

**Advantages of `$()`:**
- **Better Nesting**: Each `$()` creates independent quoting context, no escaping needed
- **Cleaner Backslash Handling**: Predictable behavior with backslashes
- **Improved Readability**: Backticks camouflaged near quotes, `$()` visually clear
- **Editor Support**: Treated as shell script syntax, better highlighting/completion
- **POSIX Compliance**: Required standard, backticks deprecated (30+ year old syntax)

**Codebase Analysis**: 100% usage of `$()` in `.claude/lib/` (0 backtick instances found)

**Example from unified-location-detection.sh:52**
```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel)
```

**Example from error-handling.sh:360**
```bash
local timestamp=$(date -u +%Y%m%d_%H%M%S)
```

### 2. Function Sourcing Best Practices

**Pattern Analysis from Codebase:**

**Standard Sourcing Pattern** (`.claude/commands/report.md:42-44`)
```bash
source .claude/lib/topic-decomposition.sh
source .claude/lib/artifact-operations.sh
source .claude/lib/template-integration.sh
```

**Absolute Path Sourcing** (`.claude/commands/report.md:84`)
```bash
source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/unified-location-detection.sh"
```

**Script-Relative Sourcing** (`.claude/lib/metadata-extraction.sh:7-9`)
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base-utils.sh"
source "${SCRIPT_DIR}/unified-logger.sh"
```

**Best Practices:**
1. **Use `SCRIPT_DIR` pattern for libraries** - Works regardless of caller's pwd
2. **Use environment variable fallbacks** - `${CLAUDE_CONFIG:-default}`
3. **Source base utilities first** - Break circular dependencies
4. **Fail fast on source errors** - Use `set -euo pipefail`

**Anti-Pattern to Avoid:**
```bash
# DON'T: Relative paths break when called from different directories
source ./lib/utils.sh
```

### 3. Variable Capture Patterns

**Robust Pattern #1: Capture with Fallback** (`.claude/lib/checkbox-utils.sh:85,96-97`)
```bash
local plan_dir=$(get_plan_directory "$plan_path" 2>/dev/null || echo "")
local plan_name=$(basename "$plan_dir")
local main_plan="$(dirname "$plan_dir")/$plan_name.md"
```

**Analysis**: Provides empty string fallback if function fails, prevents undefined variable errors

**Robust Pattern #2: Check Before Use** (`.claude/lib/validation-utils.sh:257`)
```bash
if [ -z "$path" ]; then
  error "Path parameter required"
fi
```

**Robust Pattern #3: Arithmetic Without Quotes** (`.claude/lib/context-metrics.sh:56,102`)
```bash
local token_estimate=$((char_count / 4))
local reduction=$(( (before - after) * 100 / before ))
```

**Analysis**: Arithmetic expansion doesn't require quotes, cleaner syntax

**Robust Pattern #4: Capture with Conditional Execution** (`.claude/lib/checkbox-utils.sh:157-158`)
```bash
local main_checkboxes=$(grep -E '^[[:space:]]*- \[([ x])\]' "$main_plan" | sort)
local phase_checkboxes=$(grep -E '^[[:space:]]*- \[([ x])\]' "$phase_file" | sort)
```

**Analysis**: Pipeline ensures processing even if grep returns empty results

### 4. Error Handling in Command Substitution

**CRITICAL CAVEAT: `local` Masks Exit Codes**

**Problem Pattern** (from WebSearch - serverfault.com/questions/387014):
```bash
local output=$(command)  # Exit code of 'local', NOT 'command'
```

**The `local` builtin returns its own exit code (usually 0), masking the actual function's exit code.**

**Solution Pattern #1: Separate Declaration and Assignment**
```bash
local output
output=$(command)
if [ $? -ne 0 ]; then
  error "Command failed"
fi
```

**Solution Pattern #2: Check Before Capture**
```bash
if ! output=$(command); then
  error "Command failed"
fi
```

**Solution Pattern #3: Use Fallback Value** (common in `.claude/lib/`)
```bash
local count=$(grep -c "pattern" "$file" || echo "0")
```

**Codebase Examples:**

**validate-orchestrate.sh:68**
```bash
local execute_count=$(grep -c "^\*\*EXECUTE NOW" "$COMMAND_FILE" || echo "0")
```

**artifact-creation.sh:182**
```bash
local word_count=$(echo "$summary_text" | wc -w | tr -d ' ')
```

**Best Practices:**
1. **Use `|| echo ""` or `|| echo "0"`** for expected failures
2. **Separate `local` from assignment** when exit code matters
3. **Use `set -euo pipefail`** to catch unexpected failures
4. **Redirect stderr when intentional**: `2>/dev/null` for expected failures

### 5. Escaping Rules and Context

**Key Principle: Independent Quoting in `$()`**

From WebSearch (unix.stackexchange.com/questions/118433):
> "$(...)-style command substitutions are unique in that the quoting of their contents is completely independent to their surroundings"

**Example: Nested Quotes Work Naturally**
```bash
echo "$(ls "$DIR")"  # Inner and outer quotes are independent
```

**Quoting Rules Summary:**

**Double Quotes (`"..."`)**: Escape most characters except `"`, `` ` ``, `$`, `\`, `!`
- Used for: Variable expansion, command substitution, preventing word splitting

**Single Quotes (`'...'`)**: Literal, no escaping except single quote itself
- Cannot nest single quotes: use `'\''` pattern (end quote, escaped quote, start quote)
- Used for: Literal strings, regex patterns

**Command Substitution Context**: Creates fresh quoting environment
```bash
# Outer double quotes don't affect inner quotes
result="$(grep -E "pattern" "$file")"
```

**Codebase Examples:**

**checkbox-utils.sh:46,51**
```bash
local task_desc=$(echo "$line" | sed 's/^[[:space:]]*- \[[[:space:]x]\] //')
local updated_line=$(echo "$line" | sed "s@\\[[ x]\\]@[$new_state]@")
```

**Analysis**: Mixing single and double quotes in sed for different escaping needs

**plan-core-bundle.sh:72**
```bash
local name=$(echo "$heading" | sed "s/^### Phase ${phase_num}:* //" |
             sed 's/ \[.*\]$//' | tr '[:upper:]' '[:lower:]' |
             tr ' ' '_' | tr -d '/:*?"<>|&')
```

**Analysis**: Complex pipeline with variable expansion in double quotes, literal regex in single quotes

## Code Examples from Codebase

### Pattern 1: SCRIPT_DIR Detection (11 instances)

**File**: `.claude/lib/metadata-extraction.sh:7`
**File**: `.claude/lib/checkbox-utils.sh:15`
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

**Purpose**: Get absolute path to script's directory, works regardless of caller location

### Pattern 2: Fallback on Command Failure (15+ instances)

**File**: `.claude/lib/validate-orchestrate.sh:68,84,100,123`
```bash
local execute_count=$(grep -c "^\*\*EXECUTE NOW" "$COMMAND_FILE" || echo "0")
local task_research=$(sed -n '/^### Research Phase/,/^### Planning Phase/p' "$COMMAND_FILE" |
                      grep -E "Task tool|Task \{" | wc -l || echo "0")
```

**Purpose**: Provide safe default when command has no matches

### Pattern 3: JSON Processing Pipelines

**File**: `.claude/lib/analyze-metrics.sh:102,115,147,152`
```bash
echo "$metrics_data" | jq -r '...'
failures=$(echo "$metrics_data" | jq -r '...')
template_avg=$(echo "$command_data" | jq -r '...')
```

**Purpose**: Extract specific fields from JSON data structures

### Pattern 4: Conditional Directory Creation

**File**: `.claude/lib/unified-location-detection.sh:96`
```bash
mkdir -p "$specs_dir" || {
  echo "ERROR: Failed to create specs directory: $specs_dir" >&2
  return 1
}
```

**Purpose**: Create directory with explicit error handling

### Pattern 5: Input Validation Pattern

**File**: `.claude/lib/git-utils.sh:16,31,38,45`
```bash
if [ -z "$topic_number" ]; then
  error "Topic number is required"
fi
```

**Purpose**: Fail fast on missing required parameters

## External Best Practices

### 1. Always Use `$()` Over Backticks (POSIX Standard)

**Sources**:
- Stack Overflow: "What is the benefit of using $() instead of backticks"
- Red Hat Sysadmin: "Bash scripting: Moving from backtick operator to $() parentheses"
- Greg's Wiki BashFAQ/082

**Rationale**: Deprecated 30+ year old syntax, poor nesting, confusing escaping

### 2. Quote Command Substitutions to Prevent Word Splitting

**Source**: Unix & Linux Stack Exchange
```bash
# GOOD: Preserves spaces and special characters
files="$(find . -name '*.txt')"

# BAD: Word splitting breaks filenames with spaces
files=$(find . -name '*.txt')
```

### 3. Separate `local` Declaration from Assignment for Error Checking

**Source**: serverfault.com/questions/387014
```bash
# WRONG: Exit code is from 'local', not 'download'
local artifact=$(downloadApplication "$GROUP")

# RIGHT: Check actual command exit code
local artifact
artifact=$(downloadApplication "$GROUP")
if [ $? -ne 0 ]; then
  handle_error
fi
```

### 4. Use `set -euo pipefail` for Strict Error Handling

**Source**: dev.to "Robust error handling in Bash"
- `set -e`: Exit on any command failure
- `set -u`: Error on undefined variables
- `set -o pipefail`: Pipeline fails if any command fails

**Caveat**: Command substitution creates subshell, `-e` not inherited by default
**Solution**: Enable `inherit_errexit` (Bash 4.4+) or explicit error checks

### 5. Return Complex Data via JSON on stdout

**Source**: Multiple .claude/lib/ examples
```bash
# Function returns JSON
extract_metadata() {
  jq -n \
    --arg title "$title" \
    --arg summary "$summary" \
    '{title: $title, summary: $summary}'
}

# Caller captures and parses
metadata=$(extract_metadata "$file")
title=$(echo "$metadata" | jq -r '.title')
```

## AI Agent Context Considerations

### 1. Token Efficiency: Metadata-Only Passing

**Pattern from codebase**: `.claude/lib/metadata-extraction.sh`

**Problem**: Full file contents consume 5000+ tokens
**Solution**: Extract 50-word summary + key fields (95% reduction)

```bash
# INEFFICIENT: Pass full 5000-token report
report_content=$(cat "$report_path")

# EFFICIENT: Extract metadata only (250 tokens)
metadata=$(extract_report_metadata "$report_path")
summary=$(echo "$metadata" | jq -r '.summary')  # 50 words
```

**Impact**: Enables hierarchical agent workflows with <30% context usage

### 2. Defensive Programming: Expect Function Failures

**AI Agent Context**: LLM-generated function calls may have incorrect paths or parameters

**Pattern**: Always provide fallback values
```bash
# Defensive: Won't crash on bad path
result=$(process_file "$llm_provided_path" 2>/dev/null || echo '{"error":"not_found"}')

# Then check for error
if echo "$result" | jq -e '.error' >/dev/null; then
  # Handle error case
fi
```

### 3. Explicit Error Messages

**Pattern from error-handling.sh**
```bash
error() {
  echo "Error: $*" >&2
  exit 1
}

if [ -z "$required_param" ]; then
  error "Parameter 'required_param' is required"
fi
```

**Benefit**: LLM can parse error messages and self-correct

### 4. JSON Return Values for Structured Data

**Example from metadata-extraction.sh:59-75**
```bash
if command -v jq &> /dev/null; then
  jq -n \
    --arg title "${title:-Unknown Report}" \
    --arg summary "${summary% }" \
    --argjson paths "${file_paths:-[]}" \
    '{
      title: $title,
      summary: $summary,
      file_paths: $paths
    }'
else
  # Fallback if jq not available
  cat <<EOF
{"title":"${title:-Unknown Report}","summary":"${summary% }"}
EOF
fi
```

**Benefit**: LLM can easily parse structured data, handle missing jq gracefully

## Recommendations for /research Command

### 1. Use Standard SCRIPT_DIR Pattern for Library Sourcing

**Implementation**:
```bash
# At top of /research command
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/unified-location-detection.sh"
source "${SCRIPT_DIR}/../lib/metadata-extraction.sh"
source "${SCRIPT_DIR}/../lib/error-handling.sh"
```

**Benefit**: Works regardless of caller's working directory

### 2. Capture Location Detection with Explicit Error Check

**Current Problem** (hypothesized from bug report context):
```bash
# If this fails silently, REPORT_PATH could be empty
REPORT_PATH=$(calculate_report_path "$TOPIC")
```

**Recommended Pattern**:
```bash
# Pattern 1: Check result explicitly
REPORT_PATH=$(calculate_report_path "$TOPIC")
if [ -z "$REPORT_PATH" ]; then
  error "Failed to calculate report path for topic: $TOPIC"
fi

# Pattern 2: Use function with return check
if ! REPORT_PATH=$(calculate_report_path "$TOPIC"); then
  error "Failed to calculate report path"
fi

# Pattern 3: Defensive with fallback
REPORT_PATH=$(calculate_report_path "$TOPIC" || echo "")
if [ -z "$REPORT_PATH" ]; then
  # Fallback logic or error
  error "Report path calculation returned empty result"
fi
```

### 3. Return JSON for Complex Location Detection Results

**Recommended Pattern**:
```bash
calculate_report_path() {
  local topic="$1"

  # Validation
  if [ -z "$topic" ]; then
    jq -n '{error: "Topic parameter required"}'
    return 1
  fi

  # Calculate paths
  local topic_slug=$(echo "$topic" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
  local topic_dir="${SPECS_DIR}/${next_number}_${topic_slug}"
  local report_path="${topic_dir}/reports/001_research.md"

  # Return JSON
  jq -n \
    --arg path "$report_path" \
    --arg topic_dir "$topic_dir" \
    --arg slug "$topic_slug" \
    '{
      report_path: $path,
      topic_dir: $topic_dir,
      topic_slug: $slug,
      success: true
    }'
}

# Caller
result=$(calculate_report_path "$TOPIC")
if echo "$result" | jq -e '.error' >/dev/null; then
  error "$(echo "$result" | jq -r '.error')"
fi

REPORT_PATH=$(echo "$result" | jq -r '.report_path')
TOPIC_DIR=$(echo "$result" | jq -r '.topic_dir')
```

**Benefit**: Single function call returns all needed data, explicit error handling

### 4. Add Explicit Directory Creation Verification

**Recommended Pattern**:
```bash
# After directory creation
mkdir -p "$REPORT_DIR" || error "Failed to create directory: $REPORT_DIR"

# Verify it actually exists
if [ ! -d "$REPORT_DIR" ]; then
  error "Directory creation succeeded but directory not found: $REPORT_DIR"
fi
```

### 5. Use `perform_location_detection()` from Unified Library

**From unified-location-detection.sh:17-18**:
```bash
LOCATION_JSON=$(perform_location_detection "workflow description")
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
```

**Benefit**:
- Standardized across all workflow commands (/supervise, /orchestrate, /report, /plan)
- 85% token reduction vs agent-based detection
- Built-in lazy directory creation
- Proven reliability in production

### 6. Implement Checkpoint Pattern for Resumability

**Pattern from checkpoint-utils.sh**:
```bash
# Save state before agent invocation
save_checkpoint "$CHECKPOINT_FILE" '{
  "phase": "research",
  "report_path": "'"$REPORT_PATH"'",
  "topic": "'"$TOPIC"'",
  "timestamp": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"
}'

# On failure, can resume from checkpoint
if [ -f "$CHECKPOINT_FILE" ]; then
  REPORT_PATH=$(jq -r '.report_path' "$CHECKPOINT_FILE")
fi
```

### 7. Add Progress Markers for LLM Parsing

**Pattern**:
```bash
echo "PROGRESS: Calculating report path" >&2
REPORT_PATH=$(calculate_report_path "$TOPIC")

echo "PROGRESS: Creating report directory" >&2
mkdir -p "$(dirname "$REPORT_PATH")"

echo "PROGRESS: Invoking research specialist agent" >&2
invoke_agent "research-specialist" "$CONTEXT"
```

**Benefit**: LLM can track execution progress, useful for debugging

## Performance Metrics from Codebase

**Context Reduction (from CLAUDE.md: Hierarchical Agent Architecture)**:
- Metadata extraction: 99% context reduction (5000 tokens → 50 tokens)
- Target context usage: <30% throughout workflows
- Achieved reduction: 92-97% through metadata-only passing
- Time savings: 60-80% with parallel subagent execution

**Implementation Example**:
```bash
# Instead of passing full report content (5000+ tokens)
metadata=$(extract_report_metadata "$report_path")  # 250 tokens
title=$(echo "$metadata" | jq -r '.title')
summary=$(echo "$metadata" | jq -r '.summary')  # 50 words max
```

## Common Pitfalls in AI Agent Contexts

### Pitfall 1: Assuming Commands Succeed
**Problem**: LLM may generate invalid paths or parameters
**Solution**: Always check results with `-z` tests or `|| echo "fallback"`

### Pitfall 2: Using `local` with Assignment in Error-Critical Code
**Problem**: `local output=$(cmd)` masks exit code
**Solution**: Separate `local output` from `output=$(cmd)` when exit code matters

### Pitfall 3: Relying on Working Directory
**Problem**: Caller's pwd may not be project root
**Solution**: Use absolute paths from SCRIPT_DIR or CLAUDE_PROJECT_DIR

### Pitfall 4: Not Escaping User Input in Commands
**Problem**: Topic names with special characters can break commands
**Solution**: Use `tr` to sanitize input: `tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -d '/:*?"<>|&'`

### Pitfall 5: Passing Full Content Instead of Metadata
**Problem**: Context window overflow with large files
**Solution**: Extract metadata (title + 50-word summary) as shown in metadata-extraction.sh

## Alternative Patterns to Command Substitution

### Alternative 1: Here-Documents for Multi-Line JSON

**Pattern**:
```bash
read -r -d '' JSON_OUTPUT <<'EOF'
{
  "title": "Research Report",
  "summary": "50-word summary here",
  "status": "complete"
}
EOF
```

**When to Use**: Constructing complex JSON without jq

### Alternative 2: Read Function Output Line-by-Line

**Pattern**:
```bash
while IFS= read -r line; do
  process_line "$line"
done < <(generate_lines)
```

**When to Use**: Processing large outputs that don't fit in memory

### Alternative 3: Temporary Files for Complex Data

**Pattern**:
```bash
local temp_file=$(mktemp)
complex_function > "$temp_file"
result=$(cat "$temp_file")
rm -f "$temp_file"
```

**When to Use**: Function output too large for variable capture

### Alternative 4: Global Variables (Discouraged)

**Pattern**:
```bash
RESULT=""
set_result() {
  RESULT="calculated value"
}
set_result
echo "$RESULT"
```

**When to Use**: Avoid unless absolutely necessary (breaks function isolation)

### Alternative 5: Eval with Caution (Rarely Appropriate)

**Pattern**:
```bash
eval "$(function_that_outputs_assignments)"
```

**When to Use**: Almost never in AI contexts (security risk with untrusted input)

## Summary of Best Practices

1. **Always use `$()` over backticks** - POSIX standard, better nesting, cleaner syntax
2. **Quote command substitutions** - Prevent word splitting: `var="$(command)"`
3. **Separate `local` from assignment** - When exit code matters: `local var; var=$(cmd)`
4. **Use fallback values** - Defensive: `$(cmd || echo "default")`
5. **Source with SCRIPT_DIR** - Location-independent: `source "${SCRIPT_DIR}/lib.sh"`
6. **Return JSON for complex data** - Structured, parseable by LLM
7. **Validate inputs immediately** - Fail fast: `[ -z "$param" ] && error "Required"`
8. **Use metadata extraction** - 95%+ token reduction for hierarchical workflows
9. **Independent quoting in `$()`** - Nested quotes work naturally
10. **Set strict error handling** - `set -euo pipefail` catches failures early

## References

### Codebase Files Analyzed

- `.claude/lib/unified-location-detection.sh` - Project root and specs directory detection (lines 1-100)
- `.claude/lib/metadata-extraction.sh` - Report and plan metadata extraction (lines 1-100)
- `.claude/lib/error-handling.sh` - Error classification and recovery (complete file, 766 lines)
- `.claude/lib/base-utils.sh` - Base utility functions (complete file, 80 lines)
- `.claude/lib/plan-core-bundle.sh` - Plan parsing and structure utilities (lines 1-150)
- `.claude/lib/checkbox-utils.sh:15,38,46,51,82,85,96-97,100,136,144-145,149,157-158,161-162,182,185,192,223` - Checkbox state management
- `.claude/lib/validate-orchestrate.sh:68,84,100,123` - Orchestrate command validation
- `.claude/lib/artifact-creation.sh:45,128,147,182` - Artifact path calculation
- `.claude/lib/analyze-metrics.sh:102,115,147,152,187,209-210,240,261,281,287,404,480,496,518,528,537` - Metrics analysis
- `.claude/commands/report.md:42-44,84,219,369,573,603` - Report command sourcing patterns

**Total Files Analyzed**: 65+ shell scripts in `.claude/lib/`
**Total Command Substitution Instances Found**: 50+ examples
**Backtick Usage**: 0 instances (100% `$()` adoption)

### External Resources

1. **Stack Overflow**: "Command substitution: backticks or dollar sign / paren enclosed?"
   - https://stackoverflow.com/questions/9405478/

2. **Stack Overflow**: "What is the benefit of using $() instead of backticks in shell scripts?"
   - https://stackoverflow.com/questions/9449778/

3. **Greg's Wiki - BashFAQ/082**: Command substitution best practices
   - https://mywiki.wooledge.org/BashFAQ/082

4. **Red Hat Sysadmin**: "Bash scripting: Moving from backtick operator to $() parentheses"
   - https://www.redhat.com/sysadmin/backtick-operator-vs-parens

5. **Server Fault**: "Bash function, return value and error handling"
   - https://serverfault.com/questions/387014/

6. **Stack Overflow**: "Exit code of variable assignment to command substitution in Bash"
   - https://stackoverflow.com/questions/20157938/

7. **DEV Community**: "Error handling function in Bash by Command Substitution"
   - https://dev.to/hhlohmann/error-handling-function-in-bash-by-command-substitution-iip

8. **Unix & Linux Stack Exchange**: "Quoting within $(command substitution) in Bash"
   - https://unix.stackexchange.com/questions/118433/

9. **Unix & Linux Stack Exchange**: "nested double quotes in assignment with command substitution"
   - https://unix.stackexchange.com/questions/289574/

10. **Scripting OS X**: "Advanced Quoting in Shell Scripts"
    - https://scriptingosx.com/2020/04/advanced-quoting-in-shell-scripts/
