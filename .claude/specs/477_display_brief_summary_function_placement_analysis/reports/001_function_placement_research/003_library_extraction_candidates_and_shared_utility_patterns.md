# Library Extraction Candidates and Shared Utility Patterns

## Research Metadata
- **Topic**: Library extraction candidates for display/summary functions
- **Date**: 2025-10-26
- **Researcher**: Research Specialist Agent
- **Status**: Complete

## Executive Summary

The `display_brief_summary()` function in `/supervise` is **intentionally command-specific** and should **NOT** be extracted to a library. Analysis of 59 existing libraries and 30+ commands reveals a clear pattern: library functions provide **reusable logic** (parsing, validation, formatting), while command-specific functions provide **workflow-specific presentation**.

**Key Finding**: Existing libraries contain 19 display/formatting functions, but ALL are **domain-specific utilities** (format error reports, render dashboards, format timestamps) - NONE are workflow completion summaries. The pattern is consistent: summary/completion messages belong in commands, not libraries.

**Recommendation**: Keep `display_brief_summary()` inline in `/supervise` command file. No extraction needed.

## Research Questions

### 1. What display/output/summary related functions exist in current libraries?

**Total Functions Found**: 19 display/formatting functions across 7 libraries

#### Error Reporting Functions (error-handling.sh)
- `/home/benjamin/.config/.claude/lib/error-handling.sh:511` - `format_error_report()` - Format error messages with context and recovery suggestions
- `/home/benjamin/.config/.claude/lib/error-handling.sh:633` - `format_orchestrate_agent_failure()` - Format agent invocation failures for orchestrate workflows
- `/home/benjamin/.config/.claude/lib/error-handling.sh:673` - `format_orchestrate_test_failure()` - Format test failures with workflow context
- `/home/benjamin/.config/.claude/lib/error-handling.sh:715` - `format_orchestrate_phase_context()` - Add workflow phase context to errors

**Pattern**: Error formatting is **reusable** - same structure used across multiple commands (orchestrate, implement, supervise).

#### Dashboard Rendering Functions (progress-dashboard.sh)
- `/home/benjamin/.config/.claude/lib/progress-dashboard.sh:105` - `render_dashboard()` - Render full implementation progress dashboard with ANSI box-drawing
- `/home/benjamin/.config/.claude/lib/progress-dashboard.sh:267` - `render_box_line()` - Render horizontal box lines with Unicode characters
- `/home/benjamin/.config/.claude/lib/progress-dashboard.sh:274` - `render_text_line()` - Render text lines within dashboard boxes
- `/home/benjamin/.config/.claude/lib/progress-dashboard.sh:283` - `format_duration()` - Format elapsed time in human-readable format
- `/home/benjamin/.config/.claude/lib/progress-dashboard.sh:296` - `render_progress_markers()` - Fallback progress rendering for terminals without ANSI support

**Pattern**: Dashboard rendering is **reusable** - complex ANSI terminal manipulation logic shared across commands.

#### Progress Display Functions (progress-tracker.sh)
- `/home/benjamin/.config/.claude/lib/progress-tracker.sh:260` - `display_wave_progress()` - Display wave-based parallel implementation progress
- `/home/benjamin/.config/.claude/lib/progress-tracker.sh:430` - `display_compact_progress()` - Display compact progress summary

**Pattern**: Progress tracking is **reusable** - JSON state management and formatting logic shared.

#### Structure Analysis Functions (structure-eval-utils.sh)
- `/home/benjamin/.config/.claude/lib/structure-eval-utils.sh:191` - `display_structure_recommendations()` - Display plan structure analysis recommendations

**Pattern**: Analysis output is **reusable** - same recommendation format used by /plan, /expand, /collapse.

#### Template Display Functions (template-integration.sh)
- `/home/benjamin/.config/.claude/lib/template-integration.sh:320` - `display_available_templates()` - Display available plan templates by category

**Pattern**: Template listing is **reusable** - same format used by /plan-from-template and /plan-wizard.

#### Conversion Display Functions (convert-core.sh)
- `/home/benjamin/.config/.claude/lib/convert-core.sh:709` - `show_tool_detection()` - Display detected conversion tools (pandoc, libreoffice)
- `/home/benjamin/.config/.claude/lib/convert-core.sh:760` - `show_dry_run()` - Display dry-run conversion preview
- `/home/benjamin/.config/.claude/lib/convert-core.sh:1080` - `show_missing_tools()` - Display missing tool installation instructions

**Pattern**: Tool detection display is **reusable** - same logic for all conversion operations.

#### Timestamp Functions (timestamp-utils.sh)
- `/home/benjamin/.config/.claude/lib/timestamp-utils.sh:50` - `format_timestamp()` - Format timestamps in ISO 8601 or human-readable format

**Pattern**: Timestamp formatting is **reusable** - standardized across all logging and artifact creation.

### 2. Are there similar inline functions across multiple commands that could be shared?

**Search Results**: No similar inline summary functions found in other commands.

**Analysis**:
- `/supervise` (2177 lines): Contains `display_brief_summary()` at line 326-355 (30 lines)
- `/implement` (2073 lines): No equivalent function - uses `echo` statements directly (lines 1860-1869)
- `/plan` (1444 lines): No equivalent function - uses `echo` statements directly (line 644, 664, 684)
- `/research`, `/report`, `/debug`, `/expand`, `/collapse`: All use inline `echo` statements for completion messages

**Key Finding**: Each command has **workflow-specific completion logic**:
- `/supervise`: Branches on `$WORKFLOW_SCOPE` (research-only, research-and-plan, full-implementation, debug-only)
- `/implement`: Reports PR creation status and summary path
- `/plan`: Reports complexity evaluation and phase expansion recommendations
- `/research`: Reports hierarchical research structure and synthesis paths

**No Common Pattern**: Each command's completion message is **unique to its workflow context**.

### 3. What patterns distinguish library-worthy functions from command-specific ones?

**Analysis of 59 Libraries + 30+ Commands**:

#### Library-Worthy Functions (Extracted to libraries)
**Characteristics**:
1. **Reusable Logic**: Same behavior needed across 2+ commands
2. **Domain-Specific**: Focused on ONE problem domain (parsing, validation, formatting)
3. **Stateless/Pure**: Takes inputs, returns outputs, no side effects (except formatting)
4. **Complex Implementation**: Non-trivial logic that benefits from centralization
5. **Testable**: Can be unit tested independently

**Examples**:
- `format_error_report()` - Used by 5+ commands (orchestrate, implement, supervise, debug, expand)
- `render_dashboard()` - Complex ANSI terminal logic, used by /implement
- `display_wave_progress()` - Wave-based progress logic, used by /implement
- `format_timestamp()` - Timestamp standardization, used by ALL commands
- `parse_plan_file()` - Plan parsing, used by 8+ commands

#### Command-Specific Functions (Keep inline)
**Characteristics**:
1. **Workflow-Specific**: Unique to ONE command's completion logic
2. **Context-Dependent**: References workflow variables (WORKFLOW_SCOPE, PLAN_PATH, etc.)
3. **Simple Implementation**: Basic `echo` statements with variable interpolation
4. **Not Reusable**: Other commands have different completion contexts
5. **Tied to Command State**: Uses local variables from command execution

**Examples**:
- `display_brief_summary()` in /supervise - References `$WORKFLOW_SCOPE`, `$TOPIC_PATH`, `$REPORT_PATHS[@]`
- Completion messages in /implement - References `$PR_NUMBER`, `$PR_URL`, `$SUMMARY_PATH`
- Completion messages in /plan - References complexity scores, expansion recommendations

### 4. Would `display_brief_summary` benefit other commands if extracted to a library?

**Answer**: **NO**

**Reasons**:

1. **No Reuse Opportunity**: No other command has the same completion logic
   - `/supervise` is the ONLY command that branches on workflow scope (research-only, research-and-plan, full-implementation, debug-only)
   - Other commands have simpler, linear completion messages

2. **High Context Coupling**: Function references 7 workflow-specific variables
   - `$WORKFLOW_SCOPE` (unique to /supervise)
   - `$TOPIC_PATH` (calculated by /supervise)
   - `$REPORT_PATHS[@]` (array populated during research phase)
   - `$PLAN_PATH` (calculated by /supervise)
   - `$SUMMARY_PATH` (calculated by /supervise)
   - `$DEBUG_REPORT` (calculated by /supervise)
   - All variables are **local to /supervise execution context**

3. **No Complexity Reduction**: Function is 30 lines of simple `echo` and `case` statements
   - No complex logic to centralize
   - No performance benefit from extraction
   - Would require passing 7+ parameters to library function (higher complexity than inline)

4. **Library Design Pattern Violation**: Extracting would create **workflow-specific library function**
   - Current libraries are **domain-specific** (error-handling, progress-tracking, parsing)
   - A "supervise-specific completion library" would be an anti-pattern

5. **Maintenance Burden**: Extraction would increase complexity
   - Need to pass 7+ parameters to library function
   - Need to maintain function signature across versions
   - Need to coordinate updates between command and library
   - Current inline approach is **simpler and more maintainable**

## Findings

### Current Library Organization (59 Modules)

**Functional Domains**:
1. **Parsing & Plans** (4 modules): plan-core-bundle.sh, progressive-planning-utils.sh, etc.
2. **Artifact Management** (1 module): artifact-operations.sh
3. **Error Handling & Validation** (2 modules): error-handling.sh, validation-utils.sh
4. **Document Conversion** (5 modules): convert-core.sh, convert-docx.sh, etc.
5. **Adaptive Planning** (3 modules): checkpoint-utils.sh, complexity-utils.sh, etc.
6. **Agent Coordination** (4 modules): agent-registry-utils.sh, workflow-detection.sh, etc.
7. **Analysis & Metrics** (3 modules): analyze-metrics.sh, structure-eval-utils.sh, etc.
8. **Template System** (3 modules): parse-template.sh, substitute-variables.sh, etc.
9. **Infrastructure** (6+ modules): unified-logger.sh, git-utils.sh, etc.

**Key Observations**:
- ALL libraries are **domain-organized** (error handling, parsing, conversion, etc.)
- NO libraries are **workflow-organized** (supervise-utils.sh, implement-utils.sh)
- 300-400 LOC saved through library extraction (documented in README.md)
- Single Responsibility Principle strictly followed

### Inline Functions in Commands

**Pattern Analysis**:
- Commands contain 0-3 inline functions on average
- Inline functions are **always workflow-specific**
- Common pattern: verification functions (`verify_agent_output()`, `verify_file_creation()`)
- Common pattern: completion messages (`display_brief_summary()`, `echo "✓ Complete"`)

**No Extraction Candidates Found**:
- All inline functions are either:
  1. Too simple to justify library extraction (< 10 lines)
  2. Too workflow-specific to be reusable
  3. Already have equivalent logic in libraries (verify → `retry_with_backoff()`)

### Historical Context: Library Extraction Refactor (2025-10-14)

**Reference**: `/home/benjamin/.config/.claude/lib/README.md:1-80`

The project underwent a "clean-break refactor" on 2025-10-14 that extracted common functionality to 59 modular libraries. This was a **deliberate architectural decision** to:
1. Reduce code duplication (300-400 LOC saved)
2. Improve maintainability (update once, applies everywhere)
3. Increase testability (utilities can be unit tested independently)
4. Ensure consistency (same logic used by all commands)
5. Enforce single responsibility (each module focused on one domain)

**Implication**: The current library organization is the result of **careful analysis** and **deliberate design**. The absence of "workflow completion libraries" is **intentional**, not an oversight.

## Recommendations

### 1. Keep `display_brief_summary()` Inline in /supervise (HIGH PRIORITY)

**Rationale**:
- Function is **workflow-specific** (unique to /supervise's multi-scope architecture)
- No reuse opportunity across other commands
- Extraction would **increase complexity** (7+ parameter passing)
- Violates library design pattern (domain-specific, not workflow-specific)
- Current inline placement is **simpler and more maintainable**

**Action**: No changes needed. Function is correctly placed.

### 2. Document Library Extraction Criteria (MEDIUM PRIORITY)

**Rationale**:
- Clear criteria prevent future over-extraction
- Helps maintainers distinguish library-worthy functions from command-specific ones
- Preserves architectural integrity

**Proposed Criteria** (based on analysis):
```markdown
## Library Extraction Criteria

A function should be extracted to a library if it meets ALL criteria:
1. **Reusable**: Used by 2+ commands
2. **Domain-Specific**: Focused on one problem domain (not workflow-specific)
3. **Complex**: Non-trivial logic (>20 lines or complex algorithm)
4. **Stateless**: Minimal dependencies on command execution context
5. **Testable**: Can be unit tested independently

Functions should remain inline if they are:
- Workflow-specific completion messages
- Simple verification wrappers (< 10 lines)
- Command-specific orchestration logic
- Tightly coupled to command state (> 5 local variable references)
```

**Action**: Add to `/home/benjamin/.config/.claude/lib/README.md` or create `/home/benjamin/.config/.claude/docs/guides/library-design-guide.md`

### 3. Consider Extracting Verification Pattern (LOW PRIORITY)

**Observation**:
Many commands contain similar verification logic:
```bash
if ! retry_with_backoff 2 1000 test -f "$FILE_PATH" -a -s "$FILE_PATH"; then
  echo "❌ ERROR: File not created"
  exit 1
fi
echo "✓ VERIFIED: File created"
```

**Potential Library Function**:
```bash
# verify_file_creation: Verify file exists and has content (with retry)
# Usage: verify_file_creation <file-path> [description]
# Returns: 0 if verified, 1 if failed (exits with error message)
verify_file_creation() {
  local file_path="${1:-}"
  local description="${2:-File}"

  if ! retry_with_backoff 2 1000 test -f "$file_path" -a -s "$file_path"; then
    echo "❌ ERROR: $description not created at $file_path"
    return 1
  fi

  echo "✓ VERIFIED: $description created at $file_path"
  return 0
}
```

**Rationale**:
- Pattern appears in 10+ commands (supervise, implement, plan, research, etc.)
- Reusable logic (file existence + content verification + retry)
- Not workflow-specific (generic file verification)
- Meets all library extraction criteria

**Action**: Consider adding to `/home/benjamin/.config/.claude/lib/validation-utils.sh`

## References

### Library Files Analyzed
- `/home/benjamin/.config/.claude/lib/error-handling.sh` (lines 511-719)
- `/home/benjamin/.config/.claude/lib/progress-dashboard.sh` (lines 95-300)
- `/home/benjamin/.config/.claude/lib/progress-tracker.sh` (lines 255-430)
- `/home/benjamin/.config/.claude/lib/structure-eval-utils.sh` (line 191)
- `/home/benjamin/.config/.claude/lib/template-integration.sh` (lines 315-342)
- `/home/benjamin/.config/.claude/lib/convert-core.sh` (lines 709-1080)
- `/home/benjamin/.config/.claude/lib/timestamp-utils.sh` (line 50)
- `/home/benjamin/.config/.claude/lib/README.md` (lines 1-80) - Library organization documentation

### Command Files Analyzed
- `/home/benjamin/.config/.claude/commands/supervise.md` (2177 lines, lines 324-397)
- `/home/benjamin/.config/.claude/commands/implement.md` (2073 lines, lines 1860-1869)
- `/home/benjamin/.config/.claude/commands/plan.md` (1444 lines, lines 644-684)
- `/home/benjamin/.config/.claude/commands/research.md` (completion messages analyzed)
- `/home/benjamin/.config/.claude/commands/report.md` (completion messages analyzed)
- `/home/benjamin/.config/.claude/commands/debug.md` (completion messages analyzed)
- `/home/benjamin/.config/.claude/commands/expand.md` (completion messages analyzed)
- `/home/benjamin/.config/.claude/commands/collapse.md` (completion messages analyzed)

### Search Patterns Used
- Display/formatting functions: `grep -r "^(function )?(display_|show_|print_|output_|summary|format_|render_)"`
- Inline functions in commands: `grep -r "function.*\(display\|show\|print\|output\)"`
- Completion messages: `grep -ri "(echo|cat).*(complete|success|finish|done|summary)"`
- Summary functions: `grep -r "display_brief_summary|display_summary|show_summary"`
