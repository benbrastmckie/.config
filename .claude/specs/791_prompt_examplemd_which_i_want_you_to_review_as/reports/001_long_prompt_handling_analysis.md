# Long Prompt Handling Analysis

## Metadata
- **Date**: 2025-11-18
- **Agent**: research-specialist
- **Topic**: Long prompt handling in /plan and other commands
- **Report Type**: codebase analysis

## Executive Summary

Analysis of the prompt_example.md reveals that elements of the user's long prompt (3,777 characters of detailed semantic theory content) were significantly condensed to a 600-character summary during the /plan workflow. However, **the generated plan (001_docs_glossary_semanticconceptsmd_to_reor_plan.md) successfully captured the vast majority of the semantic content** - the condensation occurred in FEATURE_DESCRIPTION but the actual plan preserved nearly all detailed requirements.

The root cause is NOT bash shell limitations (ARG_MAX is 2MB) but rather Claude AI's interpretation of the instruction to "replace the placeholder with the actual feature description." The current command instructions implicitly encourage Claude to summarize rather than preserve verbatim. This can be addressed by explicit instructions in the command template to preserve the user's text exactly without summarization or interpretation.

**Key Finding**: While the FEATURE_DESCRIPTION variable was condensed, the research and planning phases successfully extracted and preserved the detailed content in the actual plan. This demonstrates the system works correctly for producing accurate plans, but the condensed FEATURE_DESCRIPTION could cause issues if used for other purposes (e.g., commit messages, summaries).

## Findings

### Analysis of prompt_example.md

#### Original Prompt Characteristics

The captured prompt in `/home/benjamin/.config/.claude/prompt_example.md:5-50` exhibits the following characteristics:

**Content**: A detailed philosophical/semantic specification requesting revision of multiple documentation sections with:
- Specific technical definitions (truth-conditions, contexts, truth-values)
- Complex conceptual relationships (bilateral vs unilateral propositions)
- Mathematical notation requirements (Unicode characters for logical operators)
- Detailed explanations of each section's content requirements

**Length Metrics**:
- Total characters: 3,777+
- Approximate word count: ~600 words
- Lines: 46 lines (formatted with soft wraps)

Reference: `/home/benjamin/.config/.claude/prompt_example.md:5-50`

#### Captured FEATURE_DESCRIPTION

The workflow state at line 74 shows the captured description:

```bash
export FEATURE_DESCRIPTION="Revise the sections 'Extensions', 'Intensions',
'Hyperintensions', and 'Truth Conditions' in /home/benjamin/Documents/Philosophy/
Projects/Logos/docs/glossary/semantic-concepts.md to reorder and rewrite them
with: Truth Conditions first (explaining truth-conditions as functions from
contexts to truth-values), then Bilateral Propositions (unilateral vs bilateral
propositions), then Extensions (simplest theory with empty contexts,
truth-functional operators), then Intensions (worlds as context parameter,
unilateral), then Hyperintensions (states as context, bilateral with verifiers
and falsifiers)"
```

**Length Metrics**:
- Approximate characters: 600
- Reduction ratio: ~84% content loss

Reference: `/home/benjamin/.config/.claude/prompt_example.md:74`

#### Evidence of Content Loss in FEATURE_DESCRIPTION

Comparing original to the captured FEATURE_DESCRIPTION reveals condensation:

1. **Mathematical notation requirements**: Original specifies "use unicode characters for [logical operators]" - LOST in FEATURE_DESCRIPTION
2. **Bilateral proposition definition**: Full explanation of truth + falsity sets - CONDENSED to "unilateral vs bilateral"
3. **Truth-functional operator examples**: "(and, or, not, the material conditional, material equivalence)" - LOST in FEATURE_DESCRIPTION
4. **Hyperintensional details**: Verifiers/falsifiers as truthmakers/falsitymakers - PARTIALLY PRESERVED
5. **Coarse-grained critique**: Cannot interpret modal-sensitive operators - LOST in FEATURE_DESCRIPTION
6. **Recursive composition explanation**: "assigns truth-conditions to sentences recursively on the complexity" - LOST in FEATURE_DESCRIPTION

#### Actual Plan Content Preservation (NEW ANALYSIS)

Critically, the generated plan at `/home/benjamin/Documents/Philosophy/Projects/Logos/.claude/specs/001_docs_glossary_semanticconceptsmd_to_reorder_and/plans/001_docs_glossary_semanticconceptsmd_to_reor_plan.md` successfully preserved the vast majority of content:

**PRESERVED in plan**:
1. **Unicode operators**: Plan specifies `¬`, `∧`, `∨`, `→`, `↔` explicitly (lines 33, 87, 157)
2. **Bilateral proposition definition**: Full definition preserved (lines 43-44, 75-80)
3. **Truth-functional operators**: All five listed with semantic clauses required (lines 87-91)
4. **Hyperintensional details**: Verifiers and falsifiers as truthmakers/falsitymakers (lines 102-109)
5. **Coarse-grained critique**: "Too coarse-grained for modal reasoning" (line 91)
6. **Recursive composition**: "Truth-conditional semantics assigns truth-conditions recursively on sentence complexity" (line 71)

**Evidence of complete preservation in plan**:
- Plan line 132: `Write new Truth Conditions section with function notation ⟦A⟧^c : Contexts → {1, 0}`
- Plan lines 157-160: `Add explicit list of truth-functional operators with Unicode: ¬, ∧, ∨, →, ↔`
- Plan lines 185-189: Explicitly captures verifier/falsifier functions as truthmakers
- Plan line 160: `Note that extensions are unilateral and collapse materially equivalent sentences`

**Conclusion**: The FEATURE_DESCRIPTION was condensed, but the research agent and planning agent successfully extracted and preserved all the detailed requirements from the original prompt. The plan is faithful to the user's intent.

### Technical Analysis of Prompt Passing Mechanisms

#### Current /plan Command Architecture

The /plan command uses a file-based two-step argument capture pattern:

```bash
# From /home/benjamin/.config/.claude/commands/plan.md:37-44
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/plan_arg_$(date +%s%N).txt"
# SUBSTITUTE THE FEATURE DESCRIPTION IN THE LINE BELOW
echo "YOUR_FEATURE_DESCRIPTION_HERE" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/plan_arg_path.txt"
```

Reference: `/home/benjamin/.config/.claude/commands/plan.md:37-44`

The command instructs Claude at lines 28-32:

```markdown
In the **bash block below**, replace `YOUR_FEATURE_DESCRIPTION_HERE` with the
actual feature description (keeping the quotes).

**Example**: If user ran `/plan "implement user authentication with JWT tokens"`, change:
- FROM: `echo "YOUR_FEATURE_DESCRIPTION_HERE" > "$TEMP_FILE"`
- TO: `echo "implement user authentication with JWT tokens" > "$TEMP_FILE"`
```

Reference: `/home/benjamin/.config/.claude/commands/plan.md:28-32`

#### System Limits Analysis

Bash shell limits are NOT the constraining factor:

| Limit | Value | Prompt Size | Status |
|-------|-------|-------------|--------|
| ARG_MAX | 2,097,152 bytes | 3,777 bytes | 0.18% of limit |
| Stack size | 8,192 KB | 3.7 KB | 0.04% of limit |
| Bash version | 5.2.37 | N/A | Modern with full features |

Reference: System calls `getconf ARG_MAX` and `ulimit -s`

### Root Cause Analysis

#### Primary Cause: Implicit Summarization Instruction

The instruction "replace `YOUR_FEATURE_DESCRIPTION_HERE` with the actual feature description" does NOT explicitly require verbatim preservation. Claude AI interprets this as permission to:

1. **Summarize** the user's intent
2. **Restructure** the information for clarity
3. **Remove redundancy** (as perceived by the model)
4. **Condense** detailed explanations to key points

This is a reasonable interpretation for a language model optimized for helpful responses, but it conflicts with the user's need for exact content preservation.

#### Contributing Factors

1. **Example uses short string**: The command shows `"implement user authentication with JWT tokens"` as the example, suggesting short descriptions are expected
   - Reference: `/home/benjamin/.config/.claude/commands/plan.md:31`

2. **No length preservation guidance**: No explicit instruction to maintain input length or verbatim content
   - Reference: `/home/benjamin/.config/.claude/commands/plan.md:28-44`

3. **Description framing**: Calling it a "feature description" implies a summary rather than a specification
   - Reference: Command naming and documentation throughout

4. **Library support assumes short strings**: The argument-capture.sh library works correctly but doesn't address the summarization issue
   - Reference: `/home/benjamin/.config/.claude/lib/argument-capture.sh:1-205`

#### What Is NOT the Cause

1. **Bash ARG_MAX limits**: 2MB limit vastly exceeds prompt size
2. **Echo command limitations**: No known limitations for 4KB strings
3. **File I/O issues**: Temp file mechanism correctly preserves whatever is written
4. **Shell special characters**: The content doesn't contain problematic characters
5. **Truncation by workflow system**: State persistence correctly stores the (already condensed) value

### Vulnerability Assessment for Long Prompts

#### High Risk Scenarios

1. **Technical specifications** with precise definitions and requirements
2. **Multi-section content** with detailed instructions for each section
3. **Academic/philosophical content** with nuanced distinctions
4. **Code requirements** with specific implementation details
5. **Complex refactoring** with multiple interdependent changes

#### Lower Risk Scenarios

1. **Simple feature requests**: "Add dark mode toggle"
2. **Bug descriptions**: "Button doesn't respond on mobile"
3. **File operations**: "Rename function X to Y across codebase"

## Recommendations

### Recommendation 1: Explicit Verbatim Preservation Instructions (CRITICAL)

**Modify the /plan command instructions** to explicitly require verbatim preservation:

```markdown
**CRITICAL**: Copy the user's ENTIRE input EXACTLY as provided. Do NOT:
- Summarize or condense the content
- Rephrase or restructure the information
- Remove any details you consider redundant
- Interpret the intent differently than stated

The user's complete text must be preserved character-for-character, including all
technical details, examples, and specifications.
```

Implementation location: `/home/benjamin/.config/.claude/commands/plan.md:28-35`

**Impact**: High - directly addresses the root cause
**Effort**: Low - documentation change only
**Risk**: None - improves accuracy without side effects

### Recommendation 2: Add Length Preservation Check

**Add validation in Block 2** to detect potential summarization:

```bash
# After reading FEATURE_DESCRIPTION
ORIGINAL_LENGTH=$(wc -c < "$TEMP_FILE")
if [ "$ORIGINAL_LENGTH" -gt 1000 ]; then
  echo "NOTE: Long prompt detected ($ORIGINAL_LENGTH chars)"
  echo "Verify complete content was preserved in FEATURE_DESCRIPTION"
fi
```

Implementation location: `/home/benjamin/.config/.claude/commands/plan.md:46-53`

**Impact**: Medium - alerts to potential issues
**Effort**: Low - small code addition
**Risk**: Low - informational only

### Recommendation 3: Provide Multi-Line Example

**Update the example** to show a longer, more realistic prompt:

```markdown
**Example for long prompts**: If user provided a detailed specification:
- The ENTIRE specification text must appear between the quotes
- Preserve all paragraphs, bullet points, and technical details
- Do NOT summarize or condense

**Short Example**: `/plan "implement user authentication with JWT tokens"`
**Long Example**: `/plan "Refactor the authentication module to... [all details]..."`
```

Implementation location: `/home/benjamin/.config/.claude/commands/plan.md:31-35`

**Impact**: Medium - guides expected behavior
**Effort**: Low - documentation change
**Risk**: None

### Recommendation 4: Consider Alternative Input Methods for Very Long Prompts

For prompts exceeding 5,000 characters, consider:

1. **File-based input**: `/plan --file /path/to/spec.md`
2. **Here-doc syntax**: `/plan <<EOF ... EOF`
3. **Split into research + plan**: Use `/research` first to create a report, then `/plan` with the report

Implementation: New feature addition to plan.md and argument-capture.sh

**Impact**: High for edge cases
**Effort**: Medium - requires new code paths
**Risk**: Low - additive feature

### Recommendation 5: Apply to All Commands Using Placeholder Substitution

The same vulnerability exists in:
- `/coordinate` - Line 35: `echo "YOUR_WORKFLOW_DESCRIPTION_HERE"`
- `/research` - Line 42: `echo "YOUR_WORKFLOW_DESCRIPTION_HERE"`
- `/debug` - Similar pattern

Each should receive the same verbatim preservation instructions.

Reference:
- `/home/benjamin/.config/.claude/commands/coordinate.md:35`
- `/home/benjamin/.config/.claude/commands/research.md:42`

## Implementation Considerations

### Immediate Actions (< 1 hour)

1. Update `/plan` command with explicit verbatim preservation instructions
2. Add informational note for long prompts in Block 2
3. Update the example to show expectation for longer prompts

### Short-term Actions (1-4 hours)

1. Apply same changes to `/coordinate`, `/research`, `/debug` commands
2. Update command authoring standards with new guidance
3. Add test case for long prompt preservation

### Long-term Considerations

1. Evaluate file-based input option for very long specifications
2. Consider prompt length metrics in workflow state
3. Document best practices for complex specifications

## References

### Primary Files Analyzed
- `/home/benjamin/.config/.claude/prompt_example.md:1-76` - User's prompt and captured workflow state
- `/home/benjamin/.config/.claude/commands/plan.md:1-375` - Plan command implementation
- `/home/benjamin/.config/.claude/lib/argument-capture.sh:1-205` - Two-step argument capture library
- `/home/benjamin/.config/.claude/specs/757_research_the_two_step_pattern_from_coordinate_as_o/reports/001_two_step_argument_pattern_analysis.md:1-287` - Prior research on argument patterns

### System Limit Verification
- `getconf ARG_MAX` - Returns 2,097,152 (2MB)
- `ulimit -s` - Returns 8,192 (8MB stack)
- Bash version 5.2.37(1)-release

### Related Documentation
- `/home/benjamin/.config/.claude/docs/reference/command-authoring-standards.md:371-443` - Pattern definitions
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md` - Execution model
- `/home/benjamin/.config/.claude/docs/troubleshooting/bash-tool-limitations.md` - Known limitations
