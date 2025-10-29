# Visual Clarity and Progress Display Research Report

## Metadata
- **Date**: 2025-10-29
- **Agent**: research-specialist
- **Topic**: Visual Clarity and Progress Display
- **Report Type**: best practices
- **Overview Report**: [OVERVIEW.md](OVERVIEW.md)
- **Related Reports**:
  - [Bash Error Handling and Variable Validation](001_bash_error_handling_and_variable_validation.md)
  - [Console Output Formatting and Truncation](002_console_output_formatting_and_truncation.md)

## Executive Summary

Visual clarity in console output requires strategic use of whitespace, consistent symbol patterns, and appropriate progress indicators. Research shows that well-designed CLI tools prioritize scannability through visual hierarchy, use Unicode symbols purposefully (not decoratively), and provide context-appropriate progress feedback. The /coordinate output currently suffers from mixed symbol usage (●, ⎿, ✓, ✗, …, +), inconsistent separator patterns (4 instances of ━ separators), and unclear progress indicators, reducing scannability and cognitive load management.

## Findings

### 1. Visual Hierarchy Principles

**Minimal Output Philosophy (2025 Best Practice)**
- Applications should "fail loudly and succeed quietly" - the best output is no output
- Output minimum information that is relevant and useful (Localytics CLI Best Practices)
- Don't clutter output with extraneous information

**Whitespace for Scannability**
- Whitespace makes content more scannable, allowing readers to quickly scan through headings, bullet points, and short paragraphs
- Line height of 1.5 to 1.8x font size improves readability spacing (2025 Typography Guidelines)
- Ample whitespace around text blocks reduces cognitive load, providing visual breaks between sections
- Vertical space is free and can drastically improve code/output readability

**Visual Hierarchy Through Spacing**
- Use clear hierarchy with high contrast to create accessible, scannable content
- With limited space and vertical scroll bias, spacing becomes the tool that separates content into scannable sections
- Leave ample margins around text and increase spacing between sections

**Current Issue in /coordinate Output**:
- Mixed symbol usage creates visual noise: ● (bullets), ⎿ (continuation), ✓✗ (status), … (truncation), + (expansion)
- Inconsistent separator usage: 4 instances of ━━━ lines found (lines 19, 23, 34, 43 in coordinate_output.md)
- No clear visual rhythm or hierarchy between workflow phases

### 2. Unicode Symbol Best Practices

**Strategic Symbol Usage**
- Unicode symbols enhance CLI aesthetics by replacing basic ASCII with visually rich characters
- Symbols should maintain consistent width (e.g., ▰ for progress bars) to avoid misalignment
- Use symbols purposefully, not decoratively - each symbol should communicate specific meaning
- Box-drawing characters (U+2500–257F) provide 128 options for creating visual structure

**Symbol Selection Guidelines**
- Progress indicators: Use block elements like ▰▱ for consistent-width bars
- Status indicators: ✓ (success), ✗ (failure), ● (in-progress), ○ (pending)
- Hierarchy indicators: Tree symbols (├─ └─) for nested structures, not mixed symbols
- Continuation: Use consistent tree-drawing characters, not mixed Unicode

**Cross-Platform Compatibility**
- Use UTF-8 encoding (2023+ assumption for most terminals)
- Ensure proper locale settings (LANG="en_US.UTF-8")
- Provide fallback ASCII alternatives for older systems
- Test symbols in both monospaced and variable-width font contexts

**Current Issue in /coordinate Output**:
- ⎿ symbol used 12 times for indentation/continuation (non-standard choice)
- Mixing bullet styles (●) with tree symbols (⎿) creates inconsistent hierarchy
- No clear mapping of symbol → meaning (is ● a status? a bullet point? an action?)

### 3. Progress Indicator Patterns

**Three Main Pattern Types (Evil Martians CLI UX, 2024-2025)**

**Spinners**: Best for one or a few sequential tasks that should complete in just a few seconds
- Popular libraries: ora (npm), cli-spinners (60+ spinner styles)
- Design principle: Update only when specific action completed to signal ongoing activity
- Clear spinners automatically once action completes (most libraries auto-delete)

**X of Y Pattern**: Use for step-by-step processes where you can measure progress of each step
- Shows current step and total steps (e.g., "Phase 2/7")
- Provides context without visual gauge
- Best for sequential, countable operations

**Progress Bars**: Build upon X of Y pattern with visual gauge
- Use Unicode block elements (U+2580-U+259F) for higher resolution
- Provide all previous info (step count) plus visual progress gauge
- Include time estimates when possible
- Examples: tty-progressbar, cli-progress libraries

**Design Requirements**
- Get in habit of clearing spinners/progress bars once action completed
- Update spinner only when specific action completed (not continuously)
- Detect TTY vs piping automatically (wget example: bar for terminal, dots for pipes)
- Show indication of progress for any long-running process (better usability)

**Current Issue in /coordinate Output**:
- No progress indicators for long-running tasks (Task operations show "Done" after completion)
- No time estimates or visual progress gauges
- "Done (26 tool uses · 87.8k tokens · 4m 31s)" appears only after completion, not during execution
- Missing real-time progress feedback during multi-minute operations

### 4. Color Usage Guidelines

**ANSI Escape Code Best Practices**

**Accessibility Principles**
- Allow users to enable/disable color display (visual impairment support)
- When information is color-coded, it becomes easier to parse important messages, warnings, statuses
- Strategic use improves visual clarity and accessibility (not just decoration)

**Color Semantic Mapping**
- Different colors indicate different message types (errors, warnings, success)
- Establishes clear visual hierarchy in terminal applications
- Creates polished, professional feel

**Technical Requirements**
- Always reset colors with `\x1b[0m` after use (prevents color spillover)
- Actual colors displayed depend on terminal color scheme
- Common issues: terminal settings, lack of support, incorrect syntax
- Write useful info to stdout, warnings/errors to stderr (separation of concerns)

**Current Issue in /coordinate Output**:
- No visible color usage in coordinate_output.md sample (appears monochrome)
- Errors and successes have same visual weight
- Missing semantic color mapping for different message types

### 5. Spacing and Whitespace for Readability

**Vertical Spacing Guidelines**
- Vertical space is free and improves readability drastically
- Code/output is more readable with whitespace between different operations
- Ample margins around text blocks improve scanning capability

**Horizontal Spacing**
- Maintain consistent indentation levels (coordinate_output.md uses mix of ● and ⎿ with unclear indentation logic)
- Use spaces (not tabs) for predictable alignment across terminals
- Keep lines under 100-120 characters for readability

**Section Separation**
- Use spacing to separate content into scannable sections
- Visual breaks between sections reduce cognitive load
- Consistent separator patterns (not varied separator styles)

**Current Issue in /coordinate Output**:
- 4 separator instances using ━━━ (lines 19, 23, 34, 43)
- Separator usage inconsistent (some sections separated, others not)
- No clear pattern for when separators appear vs. simple spacing

### 6. Scannable Output Design

**Principles from Well-Designed CLI Tools**

**Docker/Cargo/npm Output Patterns**
- lazydocker: View containers/images in visual blocks, clear state indicators
- Cargo: Clean build output with color-coded status (Compiling, Finished, Running)
- npm: Minimal output on success, detailed on failure

**Best Practice Examples**
- Cobra framework (used by Kubernetes, Hugo, Docker): Consistent command hierarchy
- rich (Python): Sophisticated terminal formatting with tables, progress bars, syntax highlighting
- blessed/charm (Node.js): Terminal box drawing, list management, cursor control

**Output Organization Patterns**
- Group related information in visual blocks
- Use consistent indentation for hierarchy
- Clear state transitions (starting → in-progress → complete)
- Minimal output for successful operations ("succeed quietly")

**Current Issue in /coordinate Output**:
- Verbose output even for successful operations (83+ lines in coordinate_output.md)
- No clear visual blocks grouping related information
- State transitions unclear (when does research start? when does it complete?)
- Mixes high-level summary with detailed operation traces

### 7. Current /coordinate Output Analysis

**Symbol Inventory** (from /home/benjamin/.config/.claude/specs/coordinate_output.md):
- ● (bullet/action): 23 instances
- ⎿ (continuation): 12 instances
- ✓ (success): Used in verification output ("✓✓ (all passed)")
- ✗ (failure): Pattern defined but not visible in sample
- ━ (separator): 4 instances (lines 19, 23, 34, 43)
- … (ellipsis/truncation): Used in truncated output
- + (expansion): Used in "… +9 lines (ctrl+o to expand)"

**Structural Issues**:
1. No consistent mapping of symbols to meanings
2. Mixed indentation styles (● for actions, ⎿ for sub-items, but unclear rules)
3. Separator bars appear inconsistently (not all phase transitions marked)
4. Progress feedback only appears after completion, not during execution
5. Verbose output for routine operations (contradicts "succeed quietly" principle)

**Readability Problems**:
- Dense text with minimal vertical spacing between operations
- No visual grouping of related operations (research agents, verification, planning)
- Status information buried in prose ("Perfect! Both research reports created successfully")
- Difficult to scan for current state or errors at a glance

## Recommendations

### 1. Establish Consistent Symbol Semantics

**Define Clear Symbol Mappings**:
- **Status indicators**: ✓ (success), ✗ (failure), ⊙ (in-progress), ○ (pending)
- **Hierarchy**: Use standard tree-drawing (├─ for intermediate items, └─ for last item), not mixed symbols
- **Actions**: Reserve ● for high-level actions only, not nested operations
- **Separators**: Use consistent separator pattern (━━━) only for major phase transitions

**Implementation**:
Create symbol definition library in `/home/benjamin/.config/.claude/lib/output-symbols.sh`:
```bash
# Status symbols
readonly SYMBOL_SUCCESS="✓"
readonly SYMBOL_FAILURE="✗"
readonly SYMBOL_IN_PROGRESS="⊙"
readonly SYMBOL_PENDING="○"

# Tree symbols
readonly SYMBOL_TREE_BRANCH="├─"
readonly SYMBOL_TREE_LAST="└─"

# Separators
readonly SYMBOL_SEPARATOR="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

**Rationale**: Consistent symbol semantics improve scannability by allowing users to quickly identify status, hierarchy, and structure without reading prose.

### 2. Implement Real-Time Progress Indicators

**Add Progress Feedback During Long Operations**:
- For tasks >5 seconds: Show spinner with current activity
- For multi-step processes: Use "X of Y" pattern (e.g., "Research agent 2/3")
- For operations >30 seconds: Add progress bar with time estimate

**Example Pattern**:
```
Phase 1: Research (2/3 agents complete)
  ⊙ Analyzing plan changes [▰▰▰▰▰▱▱▱▱▱] 50% (2m remaining)
```

**Implementation Location**:
- Modify `/home/benjamin/.config/.claude/lib/workflow-initialization.sh` to add progress tracking
- Use `tput` for cursor positioning and clearing (no external dependencies)

**Rationale**: Progress indicators reduce user anxiety during long operations and provide visibility into workflow state (addresses finding #3 - missing real-time feedback).

### 3. Reduce Visual Noise Through Hierarchical Grouping

**Create Visual Blocks for Related Operations**:
```
Phase 1: Research
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Research Agents (2)
  ├─ Plan analysis      ✓ 4m 31s
  └─ Documentation scan ✓ 2m 10s

Verification
  └─ Reports created    ✓✓ (2/2 passed)
```

**vs Current Output** (83 lines with mixed symbols and prose):
```
● Now I'll invoke 2 research agents in parallel...
● Task(Research plan 002 formatting changes)
  ⎿  Done (26 tool uses · 87.8k tokens · 4m 31s)
● Task(Research current documentation structure)
  ⎿  Done (17 tool uses · 90.9k tokens · 2m 10s)
● Excellent! Both research reports have been created successfully...
```

**Rationale**: Visual blocks reduce cognitive load by grouping related information, making it easier to scan for phase completion or errors (addresses findings #1, #6, #7).

### 4. Apply "Succeed Quietly" Principle

**Reduce Verbose Output for Successful Operations**:
- Suppress detailed metrics (tool uses, token counts) unless error occurs
- Replace prose narration ("Excellent! Both research reports...") with concise status
- Show only essential information: phase name, status, duration

**Before** (verbose success):
```
● Excellent! Both research reports have been created successfully. Now let me verify they exist and then move to Phase 2 to create the implementation plan.
● Bash(echo "Verifying research reports (2): "...)
  ⎿  Verifying research reports (2):
     ✓✓ (all passed)
     Successful reports: 2/2
● Perfect! Both research reports created successfully. Now moving to Phase 2...
```

**After** (concise success):
```
Phase 1: Research        ✓ 6m 41s
  └─ Reports: 2/2        ✓
```

**Rationale**: Minimal output on success aligns with industry best practices (Docker, Cargo, npm) and reduces scrollback clutter (addresses finding #6 - verbose output contradicts "succeed quietly").

### 5. Implement Semantic Color Coding

**Color Mapping for Message Types**:
- Green: Success messages, completed phases
- Red: Errors, failures
- Yellow: Warnings, retries
- Blue: Informational, progress updates
- Cyan: File paths, artifacts created

**Example**:
```bash
# In output-symbols.sh
if [ -t 1 ]; then  # Check if stdout is terminal
  readonly COLOR_SUCCESS="\033[32m"
  readonly COLOR_ERROR="\033[31m"
  readonly COLOR_WARNING="\033[33m"
  readonly COLOR_INFO="\033[34m"
  readonly COLOR_PATH="\033[36m"
  readonly COLOR_RESET="\033[0m"
else
  # No colors for piped output
  readonly COLOR_SUCCESS=""
  readonly COLOR_ERROR=""
  # ... etc
fi
```

**Accessibility Consideration**:
Add environment variable `CLAUDE_NO_COLOR=1` to disable colors for users with visual impairments or terminal limitations.

**Rationale**: Semantic colors improve visual hierarchy and make it easier to identify errors/warnings at a glance (addresses finding #4 - missing color usage).

### 6. Standardize Separator Usage

**Consistent Separator Pattern**:
- Use separator (━━━) only for major phase boundaries
- Use blank lines for section separation within phases
- Never use separators for sub-operations or progress updates

**Separator Hierarchy**:
```
Phase 0: Location        ✓
━━━━━━━━━━━━━━━━━━━━━━━━

Phase 1: Research        ⊙ (in progress)
  Research Agents (3)
    ├─ Visual clarity   ✓ 3m 12s
    ├─ Symbol usage     ⊙ 1m 45s
    └─ Progress patterns ○ queued

━━━━━━━━━━━━━━━━━━━━━━━━
Phase 2: Planning        ○ (pending)
```

**Current Issue**: 4 separators appear inconsistently (lines 19, 23, 34, 43 in coordinate_output.md), with no clear logic.

**Rationale**: Consistent separator usage creates predictable visual rhythm, making phase boundaries immediately recognizable (addresses finding #5 - inconsistent separator patterns).

### 7. Create Scannable State Summary

**Add Glanceable Status Block at Start/End**:

**At Workflow Start**:
```
Workflow: research-and-plan
Phases: 0 → 1 → 2 (3 total)
━━━━━━━━━━━━━━━━━━━━━━━━
```

**During Execution** (top of screen, updated in-place):
```
Workflow Progress: 2/3 phases complete
  Phase 0: Location  ✓
  Phase 1: Research  ✓ (6m 41s)
  Phase 2: Planning  ⊙ (1m 23s elapsed)
```

**At Workflow End**:
```
━━━━━━━━━━━━━━━━━━━━━━━━
Workflow Complete: research-and-plan
  Duration: 9m 47s
  Artifacts: 3 files
    • Reports: 2
    • Plans: 1
━━━━━━━━━━━━━━━━━━━━━━━━
```

**Implementation**:
Use `tput` commands for cursor positioning to update status block in-place:
```bash
tput sc  # Save cursor position
tput cup 0 0  # Move to top-left
print_status_block
tput rc  # Restore cursor position
```

**Rationale**: Glanceable status summary provides context at a glance, reducing need to scroll through verbose output to understand current state (addresses finding #7 - difficult to scan for current state).

### 8. Implement Progressive Detail Disclosure

**Show Summary by Default, Details on Demand**:
- Default output: High-level phase status only
- Verbose mode (`--verbose` flag): Include tool usage, token counts, detailed metrics
- Debug mode (`--debug` flag): Include all intermediate operations

**Example Default Output** (concise):
```
Phase 1: Research        ✓ 6m 41s
  └─ Reports: 2/2        ✓
```

**Example Verbose Output** (`--verbose`):
```
Phase 1: Research        ✓ 6m 41s
  Research Agents (2)
    ├─ Plan analysis
    │   └─ 26 tools, 87.8k tokens, 4m 31s
    └─ Documentation scan
        └─ 17 tools, 90.9k tokens, 2m 10s
  Verification
    └─ Reports: 2/2      ✓
```

**Rationale**: Progressive disclosure balances "succeed quietly" with debugging needs, allowing users to choose their information density level (addresses finding #6 - verbose output for routine operations).

### Implementation Priority

**High Priority** (addresses core scannability issues):
1. Establish consistent symbol semantics (Recommendation #1)
2. Reduce visual noise through hierarchical grouping (Recommendation #3)
3. Apply "succeed quietly" principle (Recommendation #4)

**Medium Priority** (enhances user experience):
4. Standardize separator usage (Recommendation #6)
5. Implement semantic color coding (Recommendation #5)
6. Create scannable state summary (Recommendation #7)

**Low Priority** (nice-to-have improvements):
7. Implement real-time progress indicators (Recommendation #2)
8. Implement progressive detail disclosure (Recommendation #8)

**Estimated Effort**:
- High priority: 4-6 hours (refactor output formatting in coordinate.md, create symbol library)
- Medium priority: 3-4 hours (add color support, separator standardization, status summary)
- Low priority: 6-8 hours (progress indicators require architectural changes, mode flags need new argument parsing)

## References

### Codebase Files Analyzed

1. `/home/benjamin/.config/.claude/specs/coordinate_output.md`
   - Lines 1-113: Complete /coordinate workflow output sample
   - Line 9: Symbol usage (●) for high-level actions
   - Line 15: ⎿ symbol for continuation/indentation
   - Lines 19, 23, 34, 43: Inconsistent ━━━ separator usage
   - Lines 55-60, 73-75: Task completion output format
   - Lines 64-68, 76-81: Verification output patterns

2. `/home/benjamin/.config/.claude/lib/error-handling.sh`
   - Lines 1-100: Error classification and recovery utilities
   - Demonstrates structured output patterns for error messages
   - No Unicode symbol usage (plain text error messages)

3. `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh`
   - Lines 1-100: Checkpoint management utilities
   - Contains comment-based documentation structure
   - No visual output formatting (utility library only)

4. `/home/benjamin/.config/.claude/lib/workflow-initialization.sh`
   - Referenced for progress tracking implementation
   - Contains workflow phase management logic

### Web Sources

**Visual Hierarchy and Best Practices**:
1. Localytics Engineering Blog - "Exploring CLI Best Practices"
   - URL: https://eng.localytics.com/exploring-cli-best-practices/
   - Key concept: "Fail loudly, succeed quietly" philosophy
   - Minimal output principle for successful operations

2. DEV Community - "14 great tips to make amazing CLI applications"
   - URL: https://dev.to/wesen/14-great-tips-to-make-amazing-cli-applications-3gp3
   - Best practices for CLI design and user experience
   - Output parsability and stdout/stderr separation

3. adoc Studio - "Typography Best Practices: The Ultimate 2025 Guide"
   - URL: https://www.adoc-studio.app/blog/typography-guide
   - Line height guidelines: 1.5-1.8x font size
   - Whitespace for readability and scannability

**Unicode Symbols and Progress Indicators**:
4. Mike42.me - "Make better CLI progress bars with Unicode block characters"
   - URL: https://mike42.me/blog/2018-06-make-better-cli-progress-bars-with-unicode-block-characters
   - Unicode block elements (U+2580-U+259F) for progress bars
   - Higher resolution alternatives to ASCII progress bars

5. Changaco - "Unicode progress bars"
   - URL: https://changaco.oy.lc/unicode-progress-bars/
   - Comprehensive Unicode progress bar examples
   - Character selection for consistent width

6. GitHub - sindresorhus/ora
   - URL: https://github.com/sindresorhus/ora
   - Elegant terminal spinner library (npm)
   - Design patterns for progress indication

7. Evil Martians - "CLI UX best practices: 3 patterns for improving progress displays"
   - URL: https://evilmartians.com/chronicles/cli-ux-best-practices-3-patterns-for-improving-progress-displays
   - Three pattern types: Spinners, X of Y, Progress bars
   - When to use each pattern (task duration, measurability)

**Color and ANSI Codes**:
8. Wikipedia - "ANSI escape code"
   - URL: https://en.wikipedia.org/wiki/ANSI_escape_code
   - Standard ANSI escape sequences for color and formatting
   - Unicode version 16.0 updates (September 2024)

9. Chris Yeh - "Terminal Colors"
   - URL: https://chrisyeh96.github.io/2020/03/28/terminal-colors.html
   - Technical implementation of ANSI color codes
   - Color reset requirements (\x1b[0m)

**Box Drawing and Unicode Characters**:
10. Wikipedia - "Box-drawing characters"
    - URL: https://en.wikipedia.org/wiki/Box-drawing_character
    - Unicode block U+2500–257F (128 characters)
    - Symbols for Legacy Computing Supplement (2024 addition)

11. Stack Overflow - "Double line box_drawing characters in terminal"
    - URL: https://unix.stackexchange.com/questions/89780/double-line-box-drawing-characters-in-terminal
    - UTF-8 encoding requirements
    - Locale settings for proper display

**Well-Designed CLI Examples**:
12. Medium (Ravinduhimansha) - "The Terminal Just Leveled Up: Exploring the Next-Gen CLI Tools of 2025"
    - URL: https://medium.com/@ravinduhimansha99/the-terminal-just-leveled-up-exploring-the-next-gen-cli-tools-of-2025-6ec222795f93
    - lazydocker, lazygit visual design patterns
    - Modern CLI tool trends for 2025

13. GitHub - shadawck/awesome-cli-frameworks
    - URL: https://github.com/shadawck/awesome-cli-frameworks
    - Collection of tools for beautiful CLI interfaces
    - Cross-language framework comparison

**Whitespace and Readability**:
14. Smashing Magazine - "Using White Space For Readability In HTML And CSS"
    - URL: https://www.smashingmagazine.com/2013/02/using-white-space-for-readability-in-html-and-css/
    - Whitespace principles applicable to terminal output
    - Cognitive load reduction through spacing

15. Lenovo - "How Does White Space Affect Readability?"
    - URL: https://www.lenovo.com/us/en/glossary/white-space/
    - Whitespace for scannability
    - Visual break importance for comprehension

### Key Statistics from Research

- **Symbol Inventory in /coordinate Output**: 7 different symbol types (●, ⎿, ✓, ✗, ━, …, +)
- **Separator Instances**: 4 occurrences of ━━━ separators (inconsistent placement)
- **Output Length**: 83+ lines for a simple 3-phase workflow (verbose)
- **Unicode Support**: 128 box-drawing characters available (U+2500–257F)
- **Progress Libraries**: 60+ spinner styles in cli-spinners (npm)
- **Line Height Guideline**: 1.5-1.8x font size for optimal readability (2025)
- **Terminal UTF-8**: Default assumption for 2023+ terminals (backward compatibility still needed)
