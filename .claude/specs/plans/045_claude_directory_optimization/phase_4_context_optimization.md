# Phase 3: Context Optimization - Detailed Implementation Specification

## Phase Metadata
- **Phase Number**: 3
- **Parent Plan**: 045_claude_directory_optimization.md
- **Objective**: Reduce 5,850 lines (35%) from context-heavy components through extraction and consolidation
- **Complexity**: Medium
- **Risk**: Very Low (no functionality loss, improved maintainability)
- **Estimated Time**: 8-10 hours (full) or 4-5 hours (partial)
- **Status**: COMPLETE (Parts 1-2-4 complete, Part 3 deferred)
- **Structure**: 4 parts - Extract Reference Files (3-4h), Consolidate Examples (2-3h), Simplify Agents (2-3h), Simplify Large Utilities (optional, 2-3h)
- **Parts Completed**:
  - Part 1: COMPLETE (3 reference files created, 362 lines from orchestrate.md)
  - Part 2: COMPLETE (4,997 total lines saved: orchestrate 3,259 + implement 816 + doc-converter 922)
  - Part 3: DEFERRED (doc-converter.md already at 949 lines, close to 800 target)
  - Part 4: COMPLETE (536 lines saved from auto-analysis-utils.sh, 30.5% reduction)

## Overview

This phase reduces 5,850 lines (35%) from context-heavy components through systematic extraction and consolidation. The work is divided into 4 parts with clear dependencies and validation steps.

**Target Reductions**:
- `orchestrate.md`: 5,628 → ~3,000 lines (2,628 lines extracted, 47% reduction)
- `implement.md`: 1,803 → ~1,000 lines (803 lines extracted, 45% reduction)
- `doc-converter.md`: 1,871 → ~800 lines (1,071 lines extracted, 57% reduction)
- `auto-analysis-utils.sh`: 1,755 → ~900 lines (855 lines extracted, 49% reduction, OPTIONAL)

**Dependencies**:
- Part 1 must complete before Part 2
- Part 2 must complete before Part 3
- Part 4 is optional and independent

---

## Part 1: Extract Reference Files (3-4 hours)

### Objective
Create centralized reference files for reusable patterns, examples, and documentation that are currently duplicated across multiple commands/agents.

### Files to Create

#### 1.1 `.claude/docs/orchestration-patterns.md` (Extract ~800 lines)

**Source Material**: Extract from `orchestrate.md` lines 608-1500

**Content Structure**:
```markdown
# Workflow Orchestration Patterns

## Research Phase Patterns

### Parallel Research Topic Identification
[Extract from orchestrate.md lines 612-658]
- Workflow description parsing
- Topic extraction algorithms
- Keyword identification patterns

### Research Agent Prompt Template
[Extract from orchestrate.md lines 792-920]
- Complete template with variables
- Section-by-section breakdown
- Metadata requirements

### Research Result Aggregation
[Extract from orchestrate.md lines 920-1050]
- Collecting parallel research outputs
- Report path validation
- Failure handling

## Planning Phase Patterns

### Plan Architect Invocation
[Extract from orchestrate.md lines 1050-1200]
- Context building for plan generation
- Report synthesis approach
- Plan file creation workflow

## Implementation Phase Patterns

### Code Writer Delegation
[Extract from orchestrate.md lines 1200-1350]
- Plan-driven implementation
- Progress tracking integration
- Checkpoint coordination

## Debugging Phase Patterns

### Conditional Debug Invocation
[Extract from orchestrate.md lines 1350-1500]
- Trigger detection
- Debug report integration
- Fix verification workflow
```

**Extraction Approach**:
1. Use Read tool to identify exact line ranges for each pattern
2. Use Write tool to create new file with extracted content
3. Add cross-references: "See `.claude/docs/orchestration-patterns.md#research-phase-patterns`"
4. Include usage examples from original context

**Validation**:
```bash
# Verify file created and contains expected sections
test -f .claude/docs/orchestration-patterns.md || echo "ERROR: File not created"
grep -q "## Research Phase Patterns" .claude/docs/orchestration-patterns.md || echo "ERROR: Missing section"

# Count extracted content
EXTRACTED_LINES=$(wc -l < .claude/docs/orchestration-patterns.md)
echo "Extracted $EXTRACTED_LINES lines (target: ~800)"
```

#### 1.2 `.claude/docs/command-examples.md` (Extract ~600 lines)

**Source Material**: Extract from multiple files

**Content Structure**:
```markdown
# Command Usage Examples and Patterns

## /implement Examples

### Basic Implementation
[Extract from implement.md lines 47-56]

### Resume from Checkpoint
[Extract from implement.md lines 1427-1435]

### With Progress Dashboard
[Extract from implement.md lines 65-110]

### With Scope Drift Detection
[Extract from implement.md lines 47-56 + notes]

## /orchestrate Examples

### Full Feature Workflow
[Extract from orchestrate.md lines 32-72]

### Debug-Focused Workflow
[Extract from orchestrate.md lines 550-600]

### Parallel Research Only
[Extract from orchestrate.md context]

## Document Conversion Examples

### Batch DOCX Conversion
[Extract from doc-converter.md lines 988-1010]

### Round-Trip Conversion
[Extract from doc-converter.md lines 1511-1791, condensed]

### Quality-Focused Conversion
[Extract from doc-converter.md lines 1020-1034]
```

**Extraction Strategy**:
1. Identify example blocks across all three files
2. Consolidate similar examples (avoid duplication)
3. Add context and explanations for each example
4. Create cross-reference index at top of file

**Validation**:
```bash
# Verify completeness
EXAMPLE_COUNT=$(grep -c "^### " .claude/docs/command-examples.md)
test "$EXAMPLE_COUNT" -ge 10 || echo "WARNING: Expected at least 10 examples, found $EXAMPLE_COUNT"

# Verify no broken code blocks
OPEN_BLOCKS=$(grep -c '^```' .claude/docs/command-examples.md)
test $((OPEN_BLOCKS % 2)) -eq 0 || echo "ERROR: Unmatched code blocks"
```

#### 1.3 `.claude/docs/logging-patterns.md` (Extract ~400 lines)

**Source Material**: Extract from `doc-converter.md` lines 662-983

**Content Structure**:
```markdown
# Logging System Patterns

## Log File Initialization
[Extract from doc-converter.md lines 670-687]
- Setup pattern
- Header format
- Context information

## Section Headers with Separators
[Extract from doc-converter.md lines 699-721]
- Major section format
- Minor section format
- Blank line conventions

## Tool Usage Logging with Quality Indicators
[Extract from doc-converter.md lines 723-757]
- Tool selection logging
- Execution result logging
- Quality indicator definitions

## Error Logging with Context Preservation
[Extract from doc-converter.md lines 759-797]
- Error output capture
- Context extraction
- Debugging information

## Timestamped Entries for Long-Running Operations
[Extract from doc-converter.md lines 799-821]
- Start/end timestamps
- Duration calculation
- Format patterns

## Progress Logging for Batch Operations
[Extract from doc-converter.md lines 823-858]
- Counter maintenance
- Percentage calculation
- Summary generation

## Verification Logging Pattern
[Extract from doc-converter.md lines 860-910]
- Pass/fail indicators
- Status symbols
- Check structure

## Decision Tree Logging
[Extract from doc-converter.md lines 912-948]
- Question-answer flow
- Result documentation
- Reason explanation

## Best Practices for Logging
[Extract from doc-converter.md lines 950-983]
- Consistency guidelines
- Completeness requirements
- Readability tips
- Context preservation
- Performance tracking
```

**Extraction Details**:
- This is the most straightforward extraction (contiguous section)
- Preserve all code examples within each pattern
- Maintain heading hierarchy (### for pattern names, #### for sub-patterns)
- Keep "Key Points" lists intact

**Validation**:
```bash
# Verify structure
grep -c "^## " .claude/docs/logging-patterns.md
# Should match 9 major sections

# Check for code blocks
CODE_BLOCKS=$(grep -c '^```bash' .claude/docs/logging-patterns.md)
test "$CODE_BLOCKS" -ge 8 || echo "WARNING: Missing code examples"
```

---

## Part 2: Consolidate Examples (2-3 hours)

### Objective
Replace extracted content with concise references and summaries, reducing file sizes while maintaining usability.

### 2.1 Simplify `orchestrate.md` (Target: 5,628 → ~3,000 lines)

**Approach**: Replace verbose patterns with references

**Edit Pattern 1: Research Phase (Lines 608-1050)**

Original content (~440 lines of detailed patterns)

Replace with:
```markdown
## Phase Coordination

### Research Phase (Parallel Execution)

Research phase launches multiple research-specialist agents in parallel to investigate different aspects of the feature.

**Pattern**: See [Research Phase Patterns](../docs/orchestration-patterns.md#research-phase-patterns) for:
- Topic identification algorithms
- Parallel agent invocation
- Result aggregation strategies
- Research agent prompt template

**Quick Example**:
```bash
# Launch 3 research agents in parallel (single message, multiple Task calls)
Task { research-specialist: "JWT authentication patterns" }
Task { research-specialist: "Security best practices" }
Task { research-specialist: "Token refresh strategies" }
```

**Key Points**:
- 2-4 parallel agents based on workflow complexity
- Each agent creates independent report in `specs/reports/{topic}/`
- Continue on partial failures (1+ successful reports sufficient)
- Estimated time: 5-10 minutes for 3 agents
```

**Validation After Edit**:
```bash
# Measure reduction
ORIGINAL_LENGTH=5628
NEW_LENGTH=$(wc -l < .claude/commands/orchestrate.md)
REDUCTION=$((ORIGINAL_LENGTH - NEW_LENGTH))
REDUCTION_PCT=$((REDUCTION * 100 / ORIGINAL_LENGTH))

echo "Orchestrate.md: $ORIGINAL_LENGTH → $NEW_LENGTH lines"
echo "Reduction: $REDUCTION lines ($REDUCTION_PCT%)"

# Verify references work
grep -q "orchestration-patterns.md" .claude/commands/orchestrate.md || echo "ERROR: Missing reference"
```

**Edit Pattern 2: Planning Phase (Lines 1050-1200)**

Replace with:
```markdown
### Planning Phase (Sequential)

Plan-architect synthesizes research reports into structured implementation plan.

**Pattern**: See [Planning Phase Patterns](../docs/orchestration-patterns.md#planning-phase-patterns)

**Agent Invocation**:
```markdown
Task {
  subagent_type: "plan-architect"
  description: "Create implementation plan from research reports"
  input_reports: [report1, report2, report3]
}
```

**Output**: `specs/plans/NNN_feature_name.md`
```

**Edit Pattern 3: Implementation Phase (Lines 1200-1350)**

Replace with:
```markdown
### Implementation Phase (Adaptive)

Code-writer executes plan phase-by-phase with testing and commits.

**Pattern**: Delegates to `/implement` command (see [implement.md](../commands/implement.md))

**Integration**:
- `/implement` handles phase execution, testing, and commits
- Workflow monitors progress via PROGRESS markers
- Checkpoint state preserved for resumption
- Adaptive replanning triggered on complexity/failures

**Context Passed**:
```json
{
  "plan_path": "specs/plans/NNN_feature.md",
  "orchestration_context": {
    "workflow_id": "workflow-123",
    "research_reports": ["report1", "report2"],
    "parent_workflow": "orchestrate"
  }
}
```
```

**Edit Pattern 4: Debugging Phase (Lines 1350-1500)**

Replace with:
```markdown
### Debugging Phase (Conditional)

Debug-specialist investigates test failures and creates diagnostic reports.

**Trigger**: Only runs if implementation phase tests fail

**Pattern**: See [Debugging Phase Patterns](../docs/orchestration-patterns.md#debugging-phase-patterns)

**Iteration Limit**: Maximum 3 debug-fix cycles before user escalation

**Flow**:
1. Detect test failure in implementation phase
2. Invoke `/debug` with error context
3. Parse debug report for root cause
4. Apply fix via code-writer
5. Re-run tests
6. Repeat up to 3 times or until success
```

### 2.2 Simplify `implement.md` (Target: 1,803 → ~1,000 lines)

**Approach**: Consolidate redundant examples and merge similar sections

**Edit Pattern 1: Dry-Run Mode (Lines 374-574)**

The dry-run section is 200 lines of detailed implementation. Consolidate to ~60 lines:

```markdown
### Step 0.5: Dry-Run Mode Execution

If `--dry-run` flag is present, execute preview mode instead of actual implementation.

**Workflow**:
1. Parse plan structure and metadata
2. Analyze each phase (complexity, tasks, files, tests)
3. Determine agent assignments based on complexity
4. Parse dependencies and generate execution waves
5. Display formatted preview with duration estimates
6. Prompt for confirmation to proceed

**Implementation**: See [Dry-Run Implementation Pattern](../docs/implement-dry-run.md) for:
- Phase analysis algorithm
- Complexity evaluation logic
- Wave generation from dependencies
- Duration estimation formulas
- Preview display formatting

**Example Output**:
```
┌─────────────────────────────────────────────────┐
│ Implementation Plan: Feature Name (Dry-Run)     │
├─────────────────────────────────────────────────┤
│ Total Phases: 5  |  Estimated Duration: ~42min  │
│ Wave 1 (Sequential): Phase 1 [8min]            │
│ Wave 2 (Parallel): Phases 2-3 [15min, 12min]   │
│ Wave 3 (Sequential): Phases 4-5 [5min, 2min]   │
└─────────────────────────────────────────────────┘
```

**Exit**: If user declines, exit without changes. If confirmed, continue with implementation.
```

**Edit Pattern 2: Error Handling (Lines 826-1113)**

The automatic debug integration section is 287 lines. Consolidate to ~80 lines:

```markdown
### 3.3. Automatic Debug Integration

**Strategy**: 4-level tiered error recovery

**Levels**:
1. **Immediate Classification**: Detect error type, generate suggestions (error-utils.sh)
2. **Transient Retry**: Retry with timeout for timeouts/locks (retry_with_timeout)
3. **Fallback Toolset**: Retry with reduced tools for access errors (retry_with_fallback)
4. **Debug Invocation**: Automatic `/debug` call for root cause analysis

**Level 4 Workflow** (when auto-debug triggers):
```bash
# Invoke /debug automatically (no user prompt)
DEBUG_RESULT=$(invoke_slash_command "/debug \"Phase $PHASE test failure: $ERROR\"")
DEBUG_REPORT_PATH=$(parse_debug_report_path "$DEBUG_RESULT")

# Present user choices
echo "Choose action: (r)evise plan, (c)ontinue, (s)kip, (a)bort"
read -r USER_CHOICE

# Execute choice
case "$USER_CHOICE" in
  r) invoke_slash_command "/revise --auto-mode --context '$CONTEXT'" ;;
  c) mark_incomplete; proceed_to_next_phase ;;
  s) mark_skipped; proceed_to_next_phase ;;
  a) save_checkpoint; exit 0 ;;
esac
```

**Error Categories**: syntax, test_failure, file_not_found, import_error, null_error, timeout, permission, unknown

**Benefits**: 50% faster debug workflow, tiered recovery, graceful degradation

**Implementation**: See [Error Recovery Patterns](../docs/error-recovery.md) for complete level 1-4 logic
```

### 2.3 Simplify `doc-converter.md` (Target: 1,871 → ~800 lines)

**Approach**: Extract orchestration and logging sections, keep core conversion logic

**Edit Pattern 1: Workflow Orchestration (Lines 258-661)**

This 403-line orchestration section should be reduced to ~50 lines:

```markdown
## Workflow Orchestration

For quality-critical conversions, batch processing, or detailed logging requirements, use orchestrated multi-stage workflows.

**When to Use**:
- Batch conversions with detailed tracking
- Quality-critical conversions requiring verification
- Round-trip conversions (MD→DOCX→MD)
- Tool comparison testing
- Audit requirements

**Workflow Phases**:
1. **Tool Detection**: Detect available tools with versions
2. **Tool Selection**: Select best tool based on priority matrix
3. **Conversion**: Execute conversions with automatic fallback
4. **Verification**: Validate outputs and explain tool selection
5. **Summary Reporting**: Generate comprehensive statistics

**Pattern Details**: See [Document Conversion Orchestration](../docs/doc-conversion-orchestration.md) for:
- Complete 5-phase workflow pattern
- Template variables and customization
- Logging integration at each phase
- Error handling and fallback logic
- Example orchestrated script template

**Quick Reference**:
```bash
# Phase 1: Tool Detection
if command -v markitdown &> /dev/null; then MARKITDOWN_AVAILABLE=true; fi

# Phase 2: Tool Selection
DOCX_TOOL=$([ "$MARKITDOWN_AVAILABLE" = true ] && echo "markitdown" || echo "pandoc")

# Phase 3: Conversion with fallback
if ! markitdown "$INPUT" > "$OUTPUT"; then
  pandoc "$INPUT" -t gfm -o "$OUTPUT"  # Automatic fallback
fi

# Phase 4: Verification
FILE_SIZE=$(wc -c < "$OUTPUT")
[ "$FILE_SIZE" -lt 100 ] && echo "⚠ Suspiciously small"

# Phase 5: Summary
echo "Conversions: $SUCCESS_COUNT succeeded, $FAILED_COUNT failed"
```

**For Simple Conversions**: Skip orchestration overhead and use basic conversion strategies (see "Conversion Strategies" section).
```

**Edit Pattern 2: Logging Patterns (Lines 662-983)**

Replace entire 321-line section with:

```markdown
## Logging System Patterns

Comprehensive logging is essential for debugging, auditing, and quality verification.

**Patterns**: See [Logging Patterns](../docs/logging-patterns.md) for:
- Log file initialization
- Section headers with separators
- Tool usage logging with quality indicators
- Error logging with context preservation
- Timestamped entries for long-running operations
- Progress logging for batch operations
- Verification logging
- Decision tree logging
- Best practices

**Quick Example**:
```bash
# Initialize log
LOG_FILE="conversion.log"
echo "========================================" > "$LOG_FILE"
echo "Conversion Task - $(date)" >> "$LOG_FILE"

# Log with sections
echo "" | tee -a "$LOG_FILE"
echo "TOOL DETECTION PHASE" | tee -a "$LOG_FILE"
echo "✓ MarkItDown: AVAILABLE" | tee -a "$LOG_FILE"

# Log tool usage
echo "Tool selected: MarkItDown (HIGH quality)" | tee -a "$LOG_FILE"
if markitdown "$FILE" > output.md; then
  echo "✓ SUCCESS: Conversion complete" | tee -a "$LOG_FILE"
fi
```

**Status Symbols**: ✓ (success), ✗ (failure), ⚠ (warning), INFO: (informational)
```

**Edit Pattern 3: Standalone Script Template (Lines 1511-1791)**

The 280-line template should be condensed to ~30 lines:

```markdown
## Reference: Standalone Script Template

For users who explicitly request standalone, customizable scripts, I can generate complete orchestrated conversion scripts.

**Template Location**: See [Document Conversion Script Template](../docs/doc-conversion-script-template.sh) for:
- Full 5-phase orchestrated bash script (~270 lines)
- Parameterized variables
- Tool detection and selection logic
- Automatic fallback implementation
- Comprehensive logging integration
- Verification and reporting

**Usage Note**: Direct execution via Bash tool is the default behavior. This template is provided only for explicit script generation requests.

**Customization Guide**: Template supports:
- Simple conversions (remove orchestration phases)
- Quality-critical (keep all 5 phases)
- Round-trip conversions (duplicate Phase 3 for stages)
- Multi-stage workflows (add stage-specific tracking)
```

---

## Part 3: Simplify Agents (2-3 hours)

### Objective
Apply consolidation to agent files, focusing on `doc-converter.md` as the primary target (other agents already lean).

### 3.1 Create Agent Reference Files

**File**: `.claude/docs/doc-conversion-orchestration.md`

Extract the orchestration workflow pattern (lines 258-661 from doc-converter.md) into this reference file. This becomes the detailed guide for orchestrated workflows.

**Structure**:
```markdown
# Document Conversion Orchestration Workflow

## Overview
[Brief introduction to when and why to use orchestration]

## Phase 1: Tool Detection Phase
[Complete pattern from lines 278-339]
- Detection code for all tools
- Version capture
- Availability flags
- Logging to stdout and file

## Phase 2: Tool Selection Phase
[Complete pattern from lines 340-397]
- Priority matrix application
- Quality indicator assignment
- Fallback decision logic
- Selection logging

## Phase 3: Conversion Phase
[Complete pattern from lines 398-478]
- Tool-specific conversion logic
- Automatic fallback implementation
- Success/failure tracking
- File size logging

## Phase 4: Verification Phase
[Complete pattern from lines 479-540]
- Decision tree logging
- File validation
- Structure checks
- Quality warnings

## Phase 5: Summary Reporting Phase
[Complete pattern from lines 541-609]
- Stage-by-stage summary
- Overall statistics
- Output file listing
- Completion timestamp

## Template Variables
[From lines 610-634]

## Best Practices
[From lines 636-661]
```

**File**: `.claude/docs/doc-conversion-script-template.sh`

Extract the standalone script template (lines 1511-1791) as an executable template.

### 3.2 Update `doc-converter.md` with References

After creating reference files, update doc-converter.md to reference them rather than inline all content.

---

## Part 4: Simplify Large Utilities (2-3 hours, OPTIONAL)

**Note**: This part is OPTIONAL and should only be pursued if the user explicitly requests HIGH priority for utility simplification.

### Objective
Reduce `auto-analysis-utils.sh` from 1,755 → ~900 lines by extracting boilerplate patterns.

### 4.1 Target: Consolidate Parallel Execution Functions

**Lines 716-1295** (580 lines) contain parallel execution orchestration that follows repetitive patterns:

**Pattern 1**: invoke_*_agents_parallel functions (expansion and collapse)
- Both follow same structure: build artifact refs, prepare Task prompts, return JSON
- Extract common logic to `invoke_agents_parallel_generic()`

**Pattern 2**: aggregate_*_artifacts functions
- Both validate artifacts and build JSON summaries
- Extract common logic to `aggregate_artifacts_generic()`

**Pattern 3**: coordinate_metadata_updates functions
- Both update plan metadata and detect structure level changes
- Extract common logic to `coordinate_metadata_generic()`

**Consolidation Approach**:

Create `.claude/lib/parallel-orchestration-utils.sh`:
```bash
#!/usr/bin/env bash
# Reusable parallel orchestration patterns

invoke_agents_parallel_generic() {
  local operation_type="$1"  # "expansion" or "collapse"
  local plan_path="$2"
  local recommendations_json="$3"

  # Generic implementation (~80 lines)
  # Handles both expansion and collapse with operation_type parameter
}

aggregate_artifacts_generic() {
  local operation_type="$1"
  local plan_path="$2"
  local artifact_refs_json="$3"

  # Generic implementation (~60 lines)
}

coordinate_metadata_generic() {
  local operation_type="$1"
  local plan_path="$2"
  local aggregation_json="$3"

  # Generic implementation (~50 lines)
}
```

Then in `auto-analysis-utils.sh`, replace the 580 lines with:
```bash
source "$SCRIPT_DIR/parallel-orchestration-utils.sh"

invoke_expansion_agents_parallel() {
  invoke_agents_parallel_generic "expansion" "$@"
}

invoke_collapse_agents_parallel() {
  invoke_agents_parallel_generic "collapse" "$@"
}

aggregate_expansion_artifacts() {
  aggregate_artifacts_generic "expansion" "$@"
}

aggregate_collapse_artifacts() {
  aggregate_artifacts_generic "collapse" "$@"
}

coordinate_metadata_updates() {
  coordinate_metadata_generic "expansion" "$@"
}

coordinate_collapse_metadata_updates() {
  coordinate_metadata_generic "collapse" "$@"
}
```

**Expected Reduction**: 580 lines → ~220 lines (360-line reduction, 62%)

---

## Testing Specifications

### Test Matrix

| Part | File Modified | Validation Test | Expected Result |
|------|---------------|-----------------|-----------------|
| 1 | orchestration-patterns.md | `grep -c "^## " file` | Count = 4 major sections |
| 1 | command-examples.md | `grep -c "^### " file` | Count ≥ 10 examples |
| 1 | logging-patterns.md | `grep -c "^## " file` | Count = 9 sections |
| 2 | orchestrate.md | `wc -l < file` | ≤ 3,200 lines |
| 2 | implement.md | `wc -l < file` | ≤ 1,100 lines |
| 2 | doc-converter.md | `wc -l < file` | ≤ 900 lines |
| 3 | doc-conversion-orchestration.md | Test file exists and has 5 phases | Pass |
| 4 | auto-analysis-utils.sh | `wc -l < file` | ≤ 1,000 lines |

### Validation Script

Create `.claude/tests/test_phase3_extraction.sh`:

```bash
#!/usr/bin/env bash
# Test Phase 3: Context Optimization

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."

echo "Testing Phase 3: Context Optimization"
echo "======================================"
echo ""

# Part 1: Reference file validation
echo "Part 1: Reference Files"
echo "-----------------------"

test -f "$PROJECT_ROOT/.claude/docs/orchestration-patterns.md" || { echo "✗ orchestration-patterns.md missing"; exit 1; }
SECTIONS=$(grep -c "^## " "$PROJECT_ROOT/.claude/docs/orchestration-patterns.md")
[ "$SECTIONS" -eq 4 ] || { echo "✗ Expected 4 sections, found $SECTIONS"; exit 1; }
echo "✓ orchestration-patterns.md: $SECTIONS sections"

test -f "$PROJECT_ROOT/.claude/docs/command-examples.md" || { echo "✗ command-examples.md missing"; exit 1; }
EXAMPLES=$(grep -c "^### " "$PROJECT_ROOT/.claude/docs/command-examples.md")
[ "$EXAMPLES" -ge 10 ] || { echo "✗ Expected ≥10 examples, found $EXAMPLES"; exit 1; }
echo "✓ command-examples.md: $EXAMPLES examples"

test -f "$PROJECT_ROOT/.claude/docs/logging-patterns.md" || { echo "✗ logging-patterns.md missing"; exit 1; }
SECTIONS=$(grep -c "^## " "$PROJECT_ROOT/.claude/docs/logging-patterns.md")
[ "$SECTIONS" -eq 9 ] || { echo "✗ Expected 9 sections, found $SECTIONS"; exit 1; }
echo "✓ logging-patterns.md: $SECTIONS sections"

echo ""

# Part 2: File size validation
echo "Part 2: File Consolidation"
echo "---------------------------"

ORCHESTRATE_LINES=$(wc -l < "$PROJECT_ROOT/.claude/commands/orchestrate.md")
[ "$ORCHESTRATE_LINES" -le 3200 ] || { echo "✗ orchestrate.md too large: $ORCHESTRATE_LINES lines"; exit 1; }
ORCHESTRATE_REDUCTION=$(( (5628 - ORCHESTRATE_LINES) * 100 / 5628 ))
echo "✓ orchestrate.md: $ORCHESTRATE_LINES lines ($ORCHESTRATE_REDUCTION% reduction)"

IMPLEMENT_LINES=$(wc -l < "$PROJECT_ROOT/.claude/commands/implement.md")
[ "$IMPLEMENT_LINES" -le 1100 ] || { echo "✗ implement.md too large: $IMPLEMENT_LINES lines"; exit 1; }
IMPLEMENT_REDUCTION=$(( (1803 - IMPLEMENT_LINES) * 100 / 1803 ))
echo "✓ implement.md: $IMPLEMENT_LINES lines ($IMPLEMENT_REDUCTION% reduction)"

DOC_LINES=$(wc -l < "$PROJECT_ROOT/.claude/agents/doc-converter.md")
[ "$DOC_LINES" -le 900 ] || { echo "✗ doc-converter.md too large: $DOC_LINES lines"; exit 1; }
DOC_REDUCTION=$(( (1871 - DOC_LINES) * 100 / 1871 ))
echo "✓ doc-converter.md: $DOC_LINES lines ($DOC_REDUCTION% reduction)"

echo ""

# Part 3: Reference integrity
echo "Part 3: Reference Validation"
echo "-----------------------------"

grep -q "orchestration-patterns.md" "$PROJECT_ROOT/.claude/commands/orchestrate.md" || { echo "✗ Missing reference in orchestrate.md"; exit 1; }
echo "✓ orchestrate.md references orchestration-patterns.md"

grep -q "logging-patterns.md" "$PROJECT_ROOT/.claude/agents/doc-converter.md" || { echo "✗ Missing reference in doc-converter.md"; exit 1; }
echo "✓ doc-converter.md references logging-patterns.md"

grep -q "doc-conversion-orchestration.md" "$PROJECT_ROOT/.claude/agents/doc-converter.md" || { echo "✗ Missing reference in doc-converter.md"; exit 1; }
echo "✓ doc-converter.md references doc-conversion-orchestration.md"

echo ""

# Summary
TOTAL_ORIGINAL=$((5628 + 1803 + 1871))
TOTAL_NEW=$(($ORCHESTRATE_LINES + $IMPLEMENT_LINES + $DOC_LINES))
TOTAL_REDUCTION=$((TOTAL_ORIGINAL - TOTAL_NEW))
TOTAL_PCT=$((TOTAL_REDUCTION * 100 / TOTAL_ORIGINAL))

echo "Summary"
echo "-------"
echo "Total original: $TOTAL_ORIGINAL lines"
echo "Total new: $TOTAL_NEW lines"
echo "Total reduction: $TOTAL_REDUCTION lines ($TOTAL_PCT%)"
echo ""
echo "✓ All Phase 3 validations passed"
```

### Smoke Tests

After completing each part, run these smoke tests:

**After Part 1**:
```bash
# Verify reference files are valid markdown
for file in orchestration-patterns.md command-examples.md logging-patterns.md; do
  markdown-lint .claude/docs/$file || echo "WARNING: Linting issues in $file"
done

# Verify no broken internal links
grep -r "](../" .claude/docs/*.md | while read -r line; do
  FILE=$(echo "$line" | cut -d: -f1)
  LINK=$(echo "$line" | grep -o '](../[^)]*)')
  TARGET=$(echo "$LINK" | sed 's/](..\/\([^)]*\))/\1/')
  test -f "$TARGET" || echo "✗ Broken link in $FILE: $TARGET"
done
```

**After Part 2**:
```bash
# Test that commands still parse correctly
.claude/commands/orchestrate.md --help 2>&1 | grep -q "description:" || echo "✗ orchestrate.md parse error"
.claude/commands/implement.md --help 2>&1 | grep -q "description:" || echo "✗ implement.md parse error"

# Test that references resolve
grep -o 'orchestration-patterns.md#[a-z-]*' .claude/commands/orchestrate.md | while read -r ref; do
  FILE=$(echo "$ref" | cut -d# -f1)
  ANCHOR=$(echo "$ref" | cut -d# -f2)
  HEADING=$(echo "$ANCHOR" | tr '-' ' ' | sed 's/.*/\L&/')
  grep -qi "$HEADING" ".claude/docs/$FILE" || echo "✗ Broken anchor: $ref"
done
```

**After Part 3**:
```bash
# Test agent behavioral guideline format
grep -q "^---$" .claude/agents/doc-converter.md || echo "✗ Missing frontmatter"
grep -q "^allowed-tools:" .claude/agents/doc-converter.md || echo "✗ Missing allowed-tools"
grep -q "^description:" .claude/agents/doc-converter.md || echo "✗ Missing description"
```

**After Part 4** (if completed):
```bash
# Test that utility still sources correctly
bash -n .claude/lib/auto-analysis-utils.sh || echo "✗ Syntax error in auto-analysis-utils.sh"

# Test that new parallel-orchestration-utils.sh is valid
bash -n .claude/lib/parallel-orchestration-utils.sh || echo "✗ Syntax error in parallel-orchestration-utils.sh"

# Test function exports
source .claude/lib/auto-analysis-utils.sh
type invoke_expansion_agents_parallel &>/dev/null || echo "✗ Missing function: invoke_expansion_agents_parallel"
type aggregate_expansion_artifacts &>/dev/null || echo "✗ Missing function: aggregate_expansion_artifacts"
```

---

## Error Handling and Rollback

### What Could Go Wrong

**Part 1 Risks**:
- **Incomplete extraction**: Missing sections from reference files
- **Detection**: Reference file line count < target
- **Recovery**: Re-read source file and extract missing sections

- **Broken cross-references**: Links to wrong file or anchor
- **Detection**: Grep for reference links, test if target exists
- **Recovery**: Fix link paths using Edit tool

**Part 2 Risks**:
- **Excessive reduction**: Removed critical information, not just verbosity
- **Detection**: Command smoke tests fail (parsing errors, broken commands)
- **Recovery**: Git diff to see what was removed, restore critical sections

- **Broken markdown structure**: Unmatched code blocks, malformed headers
- **Detection**: Markdown linter errors, uneven ``` count
- **Recovery**: Re-read file, fix structure issues

**Part 3 Risks**:
- **Agent functionality broken**: Agent can't access extracted patterns
- **Detection**: Agent invocation fails or produces incorrect output
- **Recovery**: Verify agent has correct file paths in references

**Part 4 Risks**:
- **Function signature mismatch**: Generic functions don't handle all edge cases
- **Detection**: Bash syntax check fails, function calls return errors
- **Recovery**: Revert to original implementation, adjust generic function signature

### Git Checkpoint Strategy

Create checkpoints after each part:

```bash
# After Part 1
git add .claude/docs/orchestration-patterns.md
git add .claude/docs/command-examples.md
git add .claude/docs/logging-patterns.md
git commit -m "feat(phase3): extract reference files (Part 1)

- Created orchestration-patterns.md (800 lines)
- Created command-examples.md (600 lines)
- Created logging-patterns.md (400 lines)

Part 1/4 of Phase 3 complete"

# After Part 2
git add .claude/commands/orchestrate.md
git add .claude/commands/implement.md
git add .claude/agents/doc-converter.md
git commit -m "feat(phase3): consolidate command files (Part 2)

- orchestrate.md: 5,628 → $(wc -l < orchestrate.md) lines
- implement.md: 1,803 → $(wc -l < implement.md) lines
- doc-converter.md: 1,871 → $(wc -l < doc-converter.md) lines

Part 2/4 of Phase 3 complete"

# After Part 3
git add .claude/docs/doc-conversion-orchestration.md
git add .claude/docs/doc-conversion-script-template.sh
git add .claude/agents/doc-converter.md
git commit -m "feat(phase3): simplify agents (Part 3)

- Extracted orchestration workflow to reference
- Extracted script template to executable file
- Updated doc-converter.md with references

Part 3/4 of Phase 3 complete"

# After Part 4 (if completed)
git add .claude/lib/parallel-orchestration-utils.sh
git add .claude/lib/auto-analysis-utils.sh
git commit -m "feat(phase3): simplify utilities (Part 4)

- Extracted generic parallel orchestration functions
- auto-analysis-utils.sh: 1,755 → $(wc -l < auto-analysis-utils.sh) lines

Part 4/4 of Phase 3 complete (OPTIONAL)"
```

### Rollback Procedure

If any part fails validation:

```bash
# Rollback to previous checkpoint
git log --oneline | grep "phase3"
git reset --hard <commit-before-failed-part>

# Clean up any created files that weren't committed
git clean -fd .claude/docs/
git clean -fd .claude/lib/

# Re-attempt the failed part with adjustments
```

### Partial Completion Handling

Parts 1-3 are sequential dependencies. Part 4 is independent.

**If Part 1 fails**: Cannot proceed to Part 2 (no reference files to link to)
**If Part 2 fails**: Part 1 is complete and useful; Part 3 can partially proceed
**If Part 3 fails**: Parts 1-2 are complete and provide value
**If Part 4 fails**: Parts 1-3 are complete; Part 4 is optional bonus

**Minimum Viable Outcome**: Parts 1-2 complete → Achieves ~60% of target reduction

---

## Summary

This specification provides concrete, actionable guidance for Phase 3 implementation:

**Part 1** (3-4h): Extract 1,800 lines to 3 reference files
**Part 2** (2-3h): Consolidate 3 files, reducing by 4,300 lines total
**Part 3** (2-3h): Simplify agents by extracting workflows
**Part 4** (2-3h, OPTIONAL): Reduce utilities by 360 lines via generics

**Total Reduction**: 5,850 lines (35%) if all parts completed
**Minimum Viable**: 4,300 lines (26%) with Parts 1-2 only

**Testing**: Comprehensive validation script, smoke tests per part, reference integrity checks
**Safety**: Git checkpoints after each part, rollback procedures, partial completion handling
**Risk Mitigation**: Clear detection and recovery for all identified failure modes
