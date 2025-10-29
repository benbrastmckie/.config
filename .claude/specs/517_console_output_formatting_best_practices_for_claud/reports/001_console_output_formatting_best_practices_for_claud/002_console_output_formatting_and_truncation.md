# Console Output Formatting and Truncation Best Practices

## Metadata
- **Date**: 2025-10-29
- **Agent**: research-specialist
- **Topic**: Console Output Formatting and Truncation
- **Report Type**: Best practices research and pattern recognition
- **Overview Report**: [OVERVIEW.md](OVERVIEW.md)
- **Related Reports**:
  - [Bash Error Handling and Variable Validation](001_bash_error_handling_and_variable_validation.md)
  - [Visual Clarity and Progress Display](003_visual_clarity_and_progress_display.md)

## Executive Summary

Console output truncation in CLI tools is a widespread challenge requiring careful balance between information completeness and readability. Best practices emphasize terminal width detection using `tput cols`, selective information display over fighting width constraints, and clean formatting through tools like `cut`, `fold`, and `printf` with width-aware formatting. The /coordinate command's current issues stem from visible Bash tool invocations and verbose library output that should be suppressed, while file paths should use intelligent truncation or multiple-line display rather than mid-string ellipsis truncation.

## Findings

### 1. Terminal Width Detection Best Practices

**Standard Approaches** (from Unix/Linux CLI tools):

1. **tput cols** (Most Reliable):
   - Command: `cols=$(tput cols)` or `width=${COLUMNS:-$(tput cols)}`
   - Part of ncurses library, installed by default on most systems
   - Returns current terminal column count
   - Used in: /home/benjamin/.config/.claude/lib/progress-dashboard.sh:41

2. **stty size** (Alternative):
   - Command: `stty size | cut -d' ' -f2`
   - Returns height and width
   - Less portable (POSIX doesn't mandate size operand)

3. **Environment Variables** ($COLUMNS, $LINES):
   - Bash sets these automatically on terminal resize
   - Only available to bash scripts, not to child programs
   - Can be unreliable in non-interactive shells

**Current State Analysis**:
- /home/benjamin/.config/.claude/lib/progress-dashboard.sh:20-48 implements proper terminal capability detection
- Checks TERM environment variable (rejects "dumb" terminals)
- Tests for interactive shell (`[[ ! -t 1 ]]`)
- Verifies tput availability and color support
- Returns JSON with capability status
- **Status**: Best practice implementation already present

### 2. Text Truncation vs Wrapping Strategies

**Industry Patterns** (from research and popular CLI tools):

1. **Truncation with cut** (Simple, Predictable):
   - Pattern: `cut -c 1-$(tput cols)`
   - Used for: Single-line output that must not wrap
   - Examples in codebase:
     - /home/benjamin/.config/.claude/lib/topic-utils.sh:54 - `cut -c1-50` for topic names
     - /home/benjamin/.config/.claude/lib/unified-location-detection.sh:213 - `cut -c1-50` for sanitization
     - /home/benjamin/.config/.claude/tests/test_auto_debug_integration.sh:167 - `cut -c 1-80` for summaries

2. **Smart Wrapping with fold/fmt** (Content-Aware):
   - `fold`: Simple character-based wrapping at specified width
   - `fmt`: Paragraph-aware formatting, preserves indentation
   - Use case: Multi-line text that should wrap intelligently

3. **Printf Width Formatting** (Alignment):
   - Pattern: `printf "%-40s" "$text"` (left-align, 40 chars wide)
   - Examples in codebase:
     - /home/benjamin/.config/.claude/tests/test_all_fixes_integration.sh:153 - `printf "${CYAN}║${NC} ${color}%-4s${NC} %-40s %10s ${CYAN}║${NC}\n"`
     - /home/benjamin/.config/.claude/lib/analyze-metrics.sh:198 - `printf "%-25s %3d %s\n"`
     - /home/benjamin/.config/.claude/specs/plans/073_plan_072_validation.md:735 - `printf "%-40s: %4d lines\n"`

4. **Horizontal Scrolling** (Viewer-Based):
   - Command: `less -S` enables horizontal scrolling
   - Use case: Log files, tabular data where truncation loses meaning
   - Not applicable to command output (requires viewer)

**Key Insight from qmacro.org**:
- **Selective Information Display** > Fighting terminal width constraints
- Embed formatting into functions/config for consistency
- Prioritize readability over complete information display
- Example: Docker's psFormat in ~/.docker/config.json uses Go templates to specify exact columns

### 3. File Path Formatting Challenges

**The Truncation Problem**:
- /home/benjamin/.config/.claude/specs/coordinate_output.md shows problematic mid-string truncation
- Line 2: "ormatting_improvements/plans/002_coordinate_remaining_formatting_improvements.md clear to see, creating a plan to refactor the"
- Ellipsis "…" characters indicate text was cut off mid-word
- Makes paths unusable (can't copy-paste, unclear what was truncated)

**Best Practices for Long Paths**:

1. **Path Shortening Strategies**:
   - **Basename only**: `$(basename "$path")` when directory context is clear
   - **Relative paths**: `${path#$PROJECT_ROOT/}` to remove common prefix
   - **Middle truncation**: "~/.config/.../510_coordinate/plans/002_plan.md"
   - **Multi-line display**: Break at directory separators

2. **Width-Aware Path Display**:
   ```bash
   # Detect terminal width
   WIDTH=$(tput cols)

   # If path longer than width, truncate intelligently
   if [ ${#PATH} -gt $WIDTH ]; then
     # Option 1: Show basename + parent dir
     echo "...$(basename $(dirname "$PATH"))/$(basename "$PATH")"

     # Option 2: Truncate from middle
     KEEP=$((WIDTH - 10))
     HEAD=$((KEEP / 2))
     TAIL=$((KEEP / 2))
     echo "${PATH:0:$HEAD}...${PATH: -$TAIL}"

     # Option 3: Multiple lines
     echo "Path:"
     echo "  $PATH"
   fi
   ```

3. **Never Truncate Critical Information**:
   - File paths should always be complete or clearly abbreviated
   - Error messages should never truncate error details
   - Use `fold -s` (word boundaries) not character truncation

### 4. Current /coordinate Output Issues Analysis

**Issue F-01: Visible Bash Tool Invocations** (Critical):
- Root cause: Claude Code displays Bash tool syntax in output stream
- Example: `Bash(cat > /tmp/...` visible to users
- Solution: Suppress library function output, display only user-facing summaries
- Related file: /home/benjamin/.config/.claude/lib/workflow-initialization.sh (should be silent)

**Issue F-03: Verbose Workflow Scope Output** (71 lines → 5-10 lines):
- Root cause: workflow-initialization.sh echoes detailed explanations
- Current: 30+ lines of scope detection explanation per workflow
- Plan 002 solution (lines 187-211): Remove ALL library echo statements
- Philosophy: Libraries silent, commands display user-facing output
- Target format: Simple "Workflow Scope Detection" report showing phases to run/skip

**Ellipsis Truncation Issue** (from coordinate_output.md):
- Lines showing "…" mid-string truncation
- Likely from text wrapping in terminal or capture tool
- Not from /coordinate code itself (no ellipsis in bash commands found)
- May be display artifact from viewer/terminal width
- Solution: Ensure adequate terminal width or use multi-line display for long paths

### 5. Progress Markers and Visual Feedback

**Current Implementation**:
- /home/benjamin/.config/.claude/lib/progress-dashboard.sh provides comprehensive dashboard
- ANSI escape codes for cursor movement, colors, box-drawing
- Unicode box-drawing characters: ┌─┐│└┘├┤
- Status icons: ✓ (complete), → (in progress), ⬚ (pending), ⊘ (skipped), ✗ (failed)
- Graceful fallback to PROGRESS markers when ANSI not supported

**Best Practices Observed**:
1. **Capability Detection First** (lines 20-48):
   - Check TERM variable, interactive shell, tput availability
   - Test color support (minimum 8 colors)
   - Return JSON with capabilities

2. **Fallback for Non-ANSI Terminals**:
   - Simple PROGRESS markers when ANSI not supported
   - Ensures compatibility with dumb terminals, pipes, log files

3. **Fixed-Width Dashboard**:
   - Width: 65 characters (progress-dashboard.sh:129)
   - Prevents wrapping on standard 80-column terminals
   - Leaves margin for safety

### 6. Popular CLI Tools Output Patterns

**Git**:
- Uses terminal width detection for formatting
- Truncates with `...` when needed
- Supports `--no-pager` for full output
- Colorizes by default in TTY, plain text in pipes

**NPM**:
- Adapts to terminal width
- Uses progress bars with percentage
- Verbose mode (`npm install --verbose`) for full output
- Flattened dependency tree reduces path depth (npm v3+)

**Docker**:
- Configurable output format (JSON, table, custom templates)
- `~/.docker/config.json` psFormat for custom columns
- Truncates container IDs by default (12 chars vs full 64)
- `docker ps --no-trunc` for full output

**Common Patterns**:
1. Detect TTY vs pipe (different formatting for each)
2. Respect terminal width for interactive output
3. Provide verbose/debug flags for full output
4. Use color coding for status (errors red, success green)
5. Truncate IDs/hashes (show shortened version by default)

### 7. Claude Code Specific Context

**Plan 510-002 Formatting Improvements**:
- Objective: Clean, concise output while maintaining diagnostic verbosity on failures
- Target: 40-50% context usage reduction
- Maintain >95% file creation reliability

**Key Changes Implemented** (from plan Phase 1, lines 162-332):
1. Remove all library echo statements (silent by default)
2. Keep error messages on stderr
3. coordinate.md displays user-facing output
4. Simple "Workflow Scope" report (5-10 lines, not 71)

**Philosophy** (from plan lines 207-211):
- Libraries MUST be silent (no output)
- Commands display what users see
- Simpler than verbose/silent modes
- No environment variables needed

## Recommendations

### 1. Implement Width-Aware Path Display (High Priority)

**Problem**: File paths truncated mid-string with ellipsis (unusable)

**Solution**:
```bash
# Add to .claude/lib/output-formatting.sh (new utility library)

format_path_for_display() {
  local path="$1"
  local max_width="${2:-$(tput cols)}"
  local path_length=${#path}

  # If path fits, return as-is
  if [ $path_length -le $max_width ]; then
    echo "$path"
    return
  fi

  # Strategy 1: Show full path on separate line with label
  if [ $max_width -ge 60 ]; then
    echo "Path:"
    echo "  $path"
    return
  fi

  # Strategy 2: Middle truncation (keep start and end)
  local keep=$((max_width - 5))  # Reserve 5 chars for "..."
  local head=$((keep * 2 / 3))    # Keep 2/3 at start
  local tail=$((keep - head))      # Keep 1/3 at end
  echo "${path:0:$head}...${path: -$tail}"
}

# Usage in coordinate.md and other commands:
PLAN_PATH=$(format_path_for_display "$PLAN_PATH")
echo "Implementation plan: $PLAN_PATH"
```

**Benefits**:
- Paths always complete or clearly abbreviated
- Copy-paste functionality preserved
- Consistent formatting across all commands

### 2. Adopt "Silent Libraries, Verbose Commands" Pattern (Critical)

**Current Issue**: workflow-initialization.sh produces 30+ lines of output

**Solution** (Already planned in 510-002 Phase 1):
- Remove ALL echo statements from library functions
- Libraries return data via exports, exit codes
- Commands (coordinate.md, orchestrate.md, etc.) display user output
- Error messages only on stderr

**Implementation**:
```bash
# In libraries (.claude/lib/*.sh):
# ❌ DON'T: echo "Calculating paths..."
# ✅ DO: Calculate silently, export results

initialize_workflow_paths() {
  # Silent calculation
  export TOPIC_DIR="/path/to/topic"
  export PLAN_PATH="/path/to/plan"
  # No echo statements (except errors to stderr)
}

# In commands (.claude/commands/*.md):
# Display user-facing output
source .claude/lib/workflow-initialization.sh
initialize_workflow_paths "$WORKFLOW_DESC" "$SCOPE"

# Command displays what matters:
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Workflow Scope Detection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Workflow: $SCOPE"
echo "Phases: 0-2 (Location, Research, Planning)"
echo "Topic: $TOPIC_NUM - $TOPIC_NAME"
echo ""
```

**Benefits**:
- Separation of concerns (libraries compute, commands display)
- Easier to test libraries (no output pollution)
- Commands control user experience
- Reduced context usage (no redundant output)

### 3. Standardize Concise Verification Format (High Priority)

**Current Issue**: MANDATORY VERIFICATION boxes (10-15 lines per verification)

**Solution** (from plan 510-002 Phase 2):
```bash
# Replace box-drawing verification with concise format

# ❌ OLD (15 lines):
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "MANDATORY VERIFICATION: Research Reports"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Expected files: 2"
echo "  1. /path/to/report1.md"
echo "  2. /path/to/report2.md"
echo ""
echo "Verification status:"
echo "  [✓] File 1 exists (2048 bytes)"
echo "  [✓] File 2 exists (1536 bytes)"
echo ""
echo "Result: All files created successfully"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ✅ NEW (1-2 lines):
echo "Verifying research reports (2): "
echo -n "✓✓ (all passed)"
echo ""
echo "Successful reports: 2/2"
```

**Helper Function**:
```bash
verify_file_created() {
  local file_path="$1"
  local file_type="${2:-file}"

  if [ ! -f "$file_path" ]; then
    echo "✗"
    return 1
  fi

  local size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path")
  if [ "$size" -lt 100 ]; then
    echo "✗"
    return 1
  fi

  echo -n "✓"
  return 0
}

# Usage:
echo -n "Verifying research reports (${#REPORT_PATHS[@]}): "
for path in "${REPORT_PATHS[@]}"; do
  verify_file_created "$path" "report" || FAILURE=1
done
echo " ($SUCCESS_COUNT/${#REPORT_PATHS[@]} passed)"
```

**Benefits**:
- 90% reduction in verification output
- Faster visual scanning (symbols > text)
- Still provides count and status
- Detailed diagnostics only on failure

### 4. Implement Progressive Disclosure for Errors (Medium Priority)

**Principle**: Show minimal information on success, detailed diagnostics on failure

**Pattern**:
```bash
# Success path (concise)
if run_tests; then
  echo "✓ Tests passed (15/15)"
else
  # Failure path (verbose)
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test Failures Detected"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Failed tests: 3/15"
  echo ""
  echo "Failure details:"
  cat "$TEST_OUTPUT" | grep "FAILED"
  echo ""
  echo "Full test log: $TEST_OUTPUT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi
```

**Application Areas**:
1. Research report creation (1 line success, 10+ lines on failure)
2. Plan creation (1 line success, detailed diagnostics on failure)
3. Implementation phases (progress markers success, full output on errors)
4. Test execution (pass count success, failure details on errors)

**Benefits**:
- Clean output during successful workflows
- Detailed diagnostics when needed
- Users see problems without digging through logs
- Reduced context usage (40-50% as targeted)

### 5. Create Shared Output Formatting Library (Medium Priority)

**Rationale**: Consistent formatting across all commands

**Proposed Library**: `.claude/lib/output-formatting.sh`

**Functions**:
```bash
# Width detection
get_terminal_width() {
  tput cols 2>/dev/null || echo "80"
}

# Path formatting
format_path_for_display() {
  # (See Recommendation 1)
}

# Text truncation
truncate_text() {
  local text="$1"
  local max_width="${2:-$(get_terminal_width)}"

  if [ ${#text} -le $max_width ]; then
    echo "$text"
  else
    echo "${text:0:$((max_width-3))}..."
  fi
}

# Word wrapping (respects word boundaries)
wrap_text() {
  local text="$1"
  local width="${2:-$(get_terminal_width)}"
  echo "$text" | fold -s -w "$width"
}

# Box drawing
draw_header() {
  local title="$1"
  local width="${2:-$(get_terminal_width)}"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "$title"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Status symbols
status_symbol() {
  local status="$1"
  case "$status" in
    success|passed|complete) echo "✓" ;;
    failure|failed|error) echo "✗" ;;
    pending|waiting) echo "⬚" ;;
    skipped) echo "⊘" ;;
    running|progress) echo "→" ;;
    *) echo "•" ;;
  esac
}
```

**Integration**:
```bash
# In commands (.claude/commands/*.md):
source .claude/lib/output-formatting.sh

# Use consistent formatting
FORMATTED_PATH=$(format_path_for_display "$PLAN_PATH")
echo "Plan: $FORMATTED_PATH"

SYMBOL=$(status_symbol "success")
echo "$SYMBOL Tests passed"
```

**Benefits**:
- DRY principle (don't repeat formatting logic)
- Consistent user experience across commands
- Easier to update formatting globally
- Testable formatting functions

### 6. Respect TTY vs Non-TTY Contexts (Low Priority)

**Use Case**: Different formatting for interactive terminals vs pipes/logs

**Detection**:
```bash
if [ -t 1 ]; then
  # TTY: Use colors, ANSI codes, progress bars
  USE_COLOR=true
  USE_ANSI=true
else
  # Non-TTY: Plain text, no ANSI codes
  USE_COLOR=false
  USE_ANSI=false
fi
```

**Application**:
```bash
if $USE_COLOR; then
  echo "${GREEN}✓${NC} Success"
else
  echo "[PASS] Success"
fi

if $USE_ANSI; then
  # Show progress dashboard with cursor movement
  render_dashboard
else
  # Show simple PROGRESS markers
  echo "PROGRESS: Running tests"
fi
```

**Benefits**:
- Log files remain readable (no ANSI escape codes)
- Piped output works with standard tools
- Interactive terminals get rich formatting
- Automated systems get parseable output

### 7. Document Output Formatting Standards (Low Priority)

**Location**: `.claude/docs/guides/output-formatting-guide.md`

**Content**:
1. When to use truncation vs wrapping vs multi-line display
2. Width detection best practices
3. Progressive disclosure pattern (concise success, verbose failure)
4. Path formatting conventions
5. Status symbol standards (✓ ✗ ⬚ ⊘ →)
6. Box-drawing character usage
7. Color coding conventions (errors red, success green, info blue)

**Benefits**:
- Consistent implementation across commands
- New command developers have clear guidance
- Reduces ad-hoc formatting decisions
- Reference for refactoring existing commands

## References

### Codebase Files Analyzed

1. `/home/benjamin/.config/.claude/specs/coordinate_output.md` - Example of truncation issues (line 2 shows ellipsis truncation)

2. `/home/benjamin/.config/.claude/lib/progress-dashboard.sh` - Terminal capability detection and ANSI formatting implementation
   - Lines 20-48: Terminal capability detection
   - Lines 54-99: ANSI escape codes and Unicode box-drawing
   - Lines 105-150: Dashboard rendering with width awareness

3. `/home/benjamin/.config/.claude/lib/workflow-initialization.sh` - Initialization library producing verbose output
   - Lines 79-150: initialize_workflow_paths() function
   - Lines 95-108: Scope detection (currently verbose, should be silent)

4. `/home/benjamin/.config/.claude/commands/coordinate.md` - Orchestration command with formatting issues
   - Lines 1-200: Command structure and architectural patterns

5. `/home/benjamin/.config/.claude/specs/510_coordinate_error_and_formatting_improvements/plans/002_coordinate_remaining_formatting_improvements.md` - Detailed formatting fix plan
   - Lines 1-332: Complete formatting improvement strategy
   - Lines 162-211: Phase 1 library silencing approach
   - Lines 186-211: Philosophy and simplified solution

6. `/home/benjamin/.config/.claude/lib/topic-utils.sh:54` - Example of `cut -c1-50` for sanitization

7. `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:213` - Example of `cut -c1-50` for path truncation

8. `/home/benjamin/.config/.claude/tests/test_all_fixes_integration.sh:153` - Example of `printf` width formatting for aligned output

9. `/home/benjamin/.config/.claude/lib/analyze-metrics.sh:198` - Example of `printf "%-25s %3d %s\n"` for metric display

### External Resources

10. "Truncation and neat terminal output" by DJ Adams (https://qmacro.org/blog/posts/2021/12/23/truncation-and-neat-terminal-output/)
    - Key insight: Selective information display > fighting width constraints
    - Three solutions: trunc script, function wrappers, native config options
    - Examples: Docker psFormat, BTP CLI wrapping

11. Unix/Linux Stack Exchange - "Getting console width using a bash script" (https://unix.stackexchange.com/questions/299067/getting-console-width-using-a-bash-script)
    - Primary method: `tput cols`
    - Alternative: `stty size`
    - Environment variables: $COLUMNS, $LINES

12. Stack Overflow - "How do I find the width & height of a terminal window?" (https://stackoverflow.com/questions/263890/how-do-i-find-the-width-height-of-a-terminal-window)
    - Multiple methods across languages
    - Portability considerations

13. Steve's Data Tips and Tricks - "The Complete Guide to Formatting Output in Linux" (https://www.spsanderson.com/steveondata/posts/2025-01-24/)
    - fold and fmt commands for wrapping
    - fmt is paragraph-aware, fold is character-based

14. WebbyLab Blog - "Best practices for building CLI and publishing it to NPM" (https://webbylab.com/blog/best-practices-for-building-cli-and-publishing-it-to-npm/)
    - Standardized parameters and arguments
    - Clear API and informative output
    - Examples: Docker, htop, Webpack, PM2

### Best Practice Patterns Observed

15. Git CLI: Terminal width detection, truncation with `...`, `--no-pager` flag, color in TTY

16. NPM CLI: Terminal width adaptation, progress bars, verbose mode flag, flattened dependency tree (v3+)

17. Docker CLI: Configurable output format (JSON/table/template), psFormat config, ID truncation, `--no-trunc` flag

18. Common CLI patterns: TTY detection, width-aware formatting, verbose/debug flags, color coding, ID/hash shortening
