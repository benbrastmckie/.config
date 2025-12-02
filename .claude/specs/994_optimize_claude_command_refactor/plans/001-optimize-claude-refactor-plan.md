# /optimize-claude Command Refactor Implementation Plan

## Metadata
- **Date**: 2025-12-01
- **Feature**: Refactor /optimize-claude command
- **Scope**: Remove hard abort criteria, standardize command structure, improve documentation guidance
- **Estimated Phases**: 7
- **Estimated Hours**: 5.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 42.5 (5 refactor + 9 tasks + 7 phases*5 + 0 integrations + 4.5 hours*0.5)
- **Research Reports**:
  - [/optimize-claude Refactor Research](/home/benjamin/.config/.claude/specs/994_optimize_claude_command_refactor/reports/001_optimize_claude_refactor_research.md)

## Overview

The /optimize-claude command currently contains critical design flaws that cause workflow failures. This plan refactors the command to:

1. **Fix critical workflow initialization**: Replace invalid "optimize-claude" scope with valid "research-and-plan" scope
2. **Remove hard abort language**: Replace 400-line hard blockers with soft guidance in docs-bloat-analyzer and cleanup-plan-architect agents
3. **Improve naming fallback**: Replace "no_name_error" with descriptive timestamp-based fallback
4. **Standardize argument capture**: Adopt 2-block pattern consistent with /research, /plan, /repair commands
5. **Add checkpoint format**: Use structured [CHECKPOINT] format per output-formatting standards
6. **Update documentation**: Add command reference entry for discoverability
7. **Consolidate bash blocks**: Reduce from 4 blocks to 3 blocks per block consolidation standards

## Research Summary

Research identified 6 issues across /optimize-claude command, supporting libraries, and 5 agents:

**Critical Issues**:
- **Invalid Workflow Scope**: Command uses "optimize-claude" instead of valid "research-and-plan" scope, causing initialization failure (error in optimize-claude-output.md line 14)
- **Hard Abort Language**: docs-bloat-analyzer.md line 315 uses "STOP if projected size >400 lines" creating blockers in generated plans
- **Propagation to Plans**: cleanup-plan-architect.md lines 314-320 copies hard abort language into implementation plans, causing /build failures

**High Priority**:
- **Poor Naming Fallback**: Topic naming agent failures create "000_no_name_error" directories requiring manual renaming

**Medium Priority**:
- **Non-Standard Argument Capture**: Uses legacy direct $1 pattern instead of 2-block capture, preventing user description input
- **Missing Checkpoints**: Uses informal "✓ Setup complete" instead of structured [CHECKPOINT] format

**Recommendation**: Adopt soft guidance model with risk assessment matrices (LOW/MODERATE/HIGH/CRITICAL) providing contextual recommendations without hard blockers. This balances maintainability with implementation flexibility.

## Success Criteria

- [x] Command initializes successfully with valid "research-and-plan" workflow scope
- [x] All agents use soft guidance language (WARNING/RECOMMENDATION) instead of hard abort language (STOP if/must not)
- [x] Generated plans contain advisory recommendations, not hard blockers
- [x] Plans execute successfully with /build without size-based aborts for 400+ line files
- [x] Topic naming fallback uses descriptive timestamps (e.g., "optimize_claude_20251201_143022")
- [x] Command uses standardized 2-block argument capture pattern
- [x] Command uses structured [CHECKPOINT] format with Context/Ready-for metadata
- [x] Command consolidated to 3 bash blocks (Setup, Execute, Cleanup)
- [x] Command reference entry added to command-reference.md
- [x] All changes comply with command-authoring, output-formatting, and error-logging standards

## Technical Design

### Architecture Overview

The /optimize-claude command orchestrates a 4-stage agent workflow:
- **Stage 1 (Parallel)**: claude-md-analyzer + docs-structure-analyzer (research)
- **Stage 2 (Parallel)**: docs-bloat-analyzer + docs-accuracy-analyzer (analysis)
- **Stage 3 (Sequential)**: cleanup-plan-architect (planning)
- **Stage 4 (Display)**: Results summary

**Current Issues**:
1. Invalid workflow scope prevents initialization
2. Hard abort language in agents creates plan execution blockers
3. Non-standard argument capture limits user input
4. Missing structured checkpoints reduces visibility

### Refactor Strategy

**Phase 1: Critical Workflow Scope Fix** (5 minutes)
- Single-line change: Replace "optimize-claude" with "research-and-plan"
- Enables command initialization without scope validation error
- No risk, immediate fix

**Phase 2: Soft Guidance Language in docs-bloat-analyzer** (2 hours)
- Replace 8 instances of hard abort language with risk assessment matrices
- Update size thresholds to advisory format: <300 (LOW), 300-400 (MODERATE), 400-600 (HIGH), >600 (CRITICAL)
- Add contextual guidance: "Proceed with merge regardless of risk level"
- Test plan generation with various thresholds

**Phase 3: Soft Guidance Language in cleanup-plan-architect** (1 hour)
- Mirror docs-bloat-analyzer changes in plan generation templates
- Replace "STOP if" with "WARNING if" and "Rollback if exceeded" with "Post-Merge Review if >600 lines"
- Ensure generated plans use conditional language ("consider", "recommend", "review guidance")
- Test plan execution with /build to verify no aborts

**Phase 4: Timestamp-Based Naming Fallback** (30 minutes)
- Replace "no_name_error" with "optimize_claude_$(date +%Y%m%d_%H%M%S)"
- Ensures unique, descriptive fallback names
- Test with forced agent failure

**Phase 5: Standardize Argument Capture** (1 hour)
- Refactor to 2-block pattern (Block 1: capture, Block 2: validate/parse)
- Support user descriptions while preserving flag parsing
- Enable commands like: `/optimize-claude "Refactor auth docs --aggressive --dry-run"`
- Test with various flag combinations and special characters

**Phase 6: Add Checkpoint Format** (30 minutes)
- Replace informal "✓ Setup complete" with structured [CHECKPOINT] format
- Add checkpoints after: Setup, Topic init, Research, Analysis, Planning
- Include Context (WORKFLOW_ID, flags) and Ready-for metadata
- Consolidate bash blocks from 4 to 3 (combine 1a+1c into Setup)

**Phase 7: Update Command Reference** (15 minutes)
- Add complete /optimize-claude entry to command-reference.md
- Include usage, arguments, agents, workflow, and see-also links
- Verify documentation builds and links resolve

### Standards Alignment

**Command Authoring Standards Compliance**:
- ✓ Execution directives (all blocks have "EXECUTE NOW")
- ✓ Task tool invocation (inline prompt pattern)
- ✓ Subprocess isolation (set +H, library re-sourcing)
- ✓ State persistence (workflow ID, state-persistence.sh)
- **✗ → ✓ Argument capture** (Phase 5: adopt 2-block pattern)
- **✗ → ✓ Path initialization** (Phase 1: fix workflow scope to "research-and-plan")
- ✓ Output suppression (libraries with 2>/dev/null)
- ✓ Directory creation (lazy creation via ensure_artifact_directory)
- ✓ Prohibited patterns (no `if !` or `elif !`)

**Output Formatting Standards Compliance**:
- **✗ → ✓ Checkpoint format** (Phase 6: add structured [CHECKPOINT] markers)
- **✗ → ✓ Block consolidation** (Phase 6: reduce to 3 blocks)
- ✓ Output suppression (library sourcing suppressed)
- ✓ Console summary (custom format with box-drawing, close to standard)

**Error Logging Standards Compliance**:
- ✓ Sources error-handling library
- ✓ Initializes error log (ensure_error_log_exists)
- ✓ Sets workflow metadata (COMMAND_NAME, WORKFLOW_ID, USER_ARGS)
- ✓ Logs errors with standard types (validation_error, file_error, agent_error)
- ✓ Queryable via /errors and /repair commands

### Risk Assessment

**Low Risk Changes**:
- Phase 1 (workflow scope): Single line change, immediately testable
- Phase 4 (naming fallback): Doesn't affect core workflow
- Phase 7 (documentation): No code changes

**Medium Risk Changes**:
- Phase 2-3 (soft guidance language): Agent behavioral change, requires thorough testing of generated plans
- Phase 5 (argument capture): New pattern, needs validation with various inputs
- Phase 6 (block consolidation): Structural change, verify all paths execute correctly

## Implementation Phases

### Phase 1: Fix Critical Workflow Scope [COMPLETE]
dependencies: []

**Objective**: Replace invalid "optimize-claude" workflow scope with valid "research-and-plan" scope to enable command initialization

**Complexity**: Low

**Tasks**:
- [x] Open `/home/benjamin/.config/.claude/commands/optimize-claude.md`
- [x] Locate line 330: `initialize_workflow_paths "$OPTIMIZATION_DESCRIPTION" "optimize-claude" "1" "$CLASSIFICATION_JSON"`
- [x] Replace "optimize-claude" with "research-and-plan": `initialize_workflow_paths "$OPTIMIZATION_DESCRIPTION" "research-and-plan" "1" "$CLASSIFICATION_JSON"`
- [x] Save file and verify syntax

**Testing**:
```bash
# Verify command initializes without scope validation error
/optimize-claude --dry-run

# Expected: No "ERROR: Unknown workflow scope" message
# Expected: Topic path initialization succeeds

# Verify error log has no validation_error entries
/errors --command /optimize-claude --type validation_error --since 5m
```

**Expected Duration**: 5 minutes

---

### Phase 2: Replace Hard Abort Language in docs-bloat-analyzer [COMPLETE]
dependencies: [1]

**Objective**: Replace 8 instances of hard abort language with soft guidance using risk assessment matrices

**Complexity**: Medium

**Tasks**:
- [x] Open `/home/benjamin/.config/.claude/agents/docs-bloat-analyzer.md`
- [x] **Line 199**: Update threshold classification
  - OLD: `**Bloated**: >400 lines (warning threshold)`
  - NEW: `**Bloated**: >400 lines (readability concern - review guidance)`
- [x] **Line 216**: Update risk flagging language
  - OLD: `Flag if projected size >400 lines (HIGH RISK)`
  - NEW: `Assess risk if projected size >400 lines (see Risk Matrix below)`
- [x] **Lines 314-325**: Replace hard abort with risk assessment matrix
  - OLD: `**STOP if projected size >400 lines** (bloat threshold exceeded)`
  - NEW: Add complete risk matrix with 4 levels (LOW/MODERATE/HIGH/CRITICAL)
  - Include guidance: "Proceed with merge regardless of risk level"
  - Add: "Post-merge review task if risk HIGH or CRITICAL"
- [x] **Line 320**: Update conditional guidance
  - OLD: `If >400 lines, consider split before continuing`
  - NEW: `If >600 lines, split recommended before merge (or extract to new file)`
- [x] **Line 342**: Update warning message format
  - OLD: `echo "WARNING: File size ($FILE_SIZE lines) exceeds bloat threshold (400 lines)"`
  - NEW: `echo "NOTE: File size ($FILE_SIZE lines) exceeds optimal threshold (400 lines) - consider split if readability suffers"`
- [x] **Line 396**: Update bloat prevention message
  - OLD: `echo "WARNING: $file exceeds bloat threshold ($lines lines > 400)"`
  - NEW: `echo "RECOMMENDATION: $file may benefit from split ($lines lines) - review for logical boundaries"`
- [x] **Line 415**: Update completion criteria language
  - OLD: `**Bloat prevention**: No extracted files exceed 400 lines (bloat threshold)`
  - NEW: `**Size guidance**: Flag extracted files >400 lines for readability review (non-blocking)`
- [x] Add new section after line 340: "## Risk Assessment Matrix" with 4-tier guidance

**Risk Matrix Template** (insert after line 340):
```markdown
## Risk Assessment Matrix

Use this matrix to assess post-merge file size risks:

| Projected Size | Risk Level | Recommendation | Action |
|----------------|------------|----------------|--------|
| <300 lines | LOW | Optimal - proceed with merge | None required |
| 300-400 lines | MODERATE | Acceptable if logically cohesive | Monitor growth |
| 400-600 lines | HIGH | Readability concerns | Add post-merge review task |
| >600 lines | CRITICAL | Maintainability risk | Recommend split before merge OR extract to new file |

**Important**: Risk levels are advisory only. HIGH and CRITICAL risks do not block merge operations - they add follow-up review tasks to ensure maintainability.

**Decision Criteria**:
- **Proceed with merge**: If content is logically cohesive and splitting would harm readability
- **Split before merge**: If logical boundaries exist and split improves navigation
- **Extract to new file**: If content is independent topic deserving separate file
```

**Testing**:
```bash
# Generate optimization plan with aggressive threshold (more extractions)
/optimize-claude --aggressive

# Verify bloat analysis report uses soft guidance
REPORT=$(find .claude/specs -name "*bloat_analysis.md" | head -1)
grep -q "STOP if" "$REPORT" && echo "FAIL: Hard abort language found" || echo "PASS: No hard abort language"
grep -q "Risk Level\|RECOMMENDATION" "$REPORT" && echo "PASS: Soft guidance found" || echo "FAIL: No soft guidance"

# Verify risk assessment matrix present
grep -q "Risk Assessment Matrix" "$REPORT" && echo "PASS: Matrix found" || echo "FAIL: Matrix missing"
```

**Expected Duration**: 2 hours

---

### Phase 3: Replace Hard Abort Language in cleanup-plan-architect [COMPLETE]
dependencies: [2]

**Objective**: Update cleanup-plan-architect to generate plans with soft guidance language matching docs-bloat-analyzer changes

**Complexity**: Medium

**Tasks**:
- [x] Open `/home/benjamin/.config/.claude/agents/cleanup-plan-architect.md`
- [x] **Lines 314-320**: Replace hard abort task template with soft guidance version
  - Remove: `**STOP if projected size >400 lines** (bloat threshold exceeded)`
  - Add: `**Size validation and risk assessment** (BEFORE extraction):`
  - Include: Complete risk matrix (LOW/MODERATE/HIGH/CRITICAL with guidance)
  - Add: `**Guidance**: Proceed with extraction regardless of risk level`
  - Add: `**Add post-merge task if HIGH/CRITICAL**: Review for split opportunities`
- [x] **Lines 353-361**: Update rollback section to post-merge review
  - OLD: `**Rollback** (if bloat threshold exceeded):`
  - NEW: `**Post-Merge Review** (if file >600 lines):`
  - Replace git rollback commands with: "Review file for logical split boundaries"
  - Add: "Consider creating Phase [N+1]: Split [filename].md if readability suffers"
- [x] **Line 223**: Update consolidation guidance
  - Ensure: "**ONLY recommend merge if combined size ≤400 lines**" becomes "**Prefer merge for combined size ≤400 lines, but HIGH risk (400-600) acceptable if cohesive**"
- [x] **Line 320**: Update post-merge size check language
  - OLD: `**Post-merge size check**: Verify actual file size ≤400 lines`
  - NEW: `**Post-merge size assessment**: Calculate actual file size, compare to risk matrix, add review task if >600 lines`

**Template Update** (lines 314-325):
```markdown
**Tasks**:
- [x] **Size validation and risk assessment** (BEFORE extraction):
  - Check current size of target file: .claude/docs/[category]/[filename].md
  - Calculate extraction size: [X] lines
  - Project post-merge size: [current] + [X] = [projected] lines
  - **Risk Assessment**:
    - <300 lines: LOW (optimal) → Proceed with merge
    - 300-400 lines: MODERATE (monitor growth) → Proceed with merge
    - 400-600 lines: HIGH (readability concerns) → Proceed with merge, add post-merge review task
    - >600 lines: CRITICAL (maintainability risk) → Recommend split before merge OR extract to new file
  - **Guidance**: Proceed with extraction regardless of risk level (thresholds are advisory)
- [x] Extract lines [start]-[end] from CLAUDE.md
- [x] [CREATE|MERGE] .claude/docs/[category]/[filename].md with full content
- [x] **Post-merge size assessment**:
  - Calculate actual file size
  - If >600 lines, add Phase [N+1]: Review [filename].md for split opportunities
```

**Testing**:
```bash
# Generate optimization plan with aggressive threshold
/optimize-claude --aggressive

# Find generated plan
PLAN=$(find .claude/specs -name "*optimization_plan.md" | head -1)

# Verify plan uses soft guidance
grep -q "STOP if" "$PLAN" && echo "FAIL: Hard abort in plan" || echo "PASS: No hard abort"
grep -q "Risk Assessment\|RECOMMENDATION\|Guidance:" "$PLAN" && echo "PASS: Soft guidance in plan" || echo "FAIL: No soft guidance"

# Verify plan executes without aborts
/build "$PLAN" --dry-run

# Expected: No workflow aborts on size warnings
# Expected: Post-merge review tasks added for files >600 lines
```

**Expected Duration**: 1 hour

---

### Phase 4: Improve Topic Naming Fallback [COMPLETE]
dependencies: [1]

**Objective**: Replace "no_name_error" fallback with descriptive timestamp-based fallback for better discoverability

**Complexity**: Low

**Tasks**:
- [x] Open `/home/benjamin/.config/.claude/commands/optimize-claude.md`
- [x] Locate lines 271-283 (topic naming fallback logic)
- [x] Replace static "no_name_error" with dynamic timestamp pattern
  - OLD: `TOPIC_NAME="no_name_error"`
  - NEW: `TOPIC_NAME="optimize_claude_$(date +%Y%m%d_%H%M%S)"`
- [x] Update validation logic to generate fallback if agent fails
  - Keep validation for agent success cases
  - Generate timestamp fallback if: empty output, invalid format, no output file
- [x] Preserve NAMING_STRATEGY tracking for debugging

**Code Changes** (lines 271-290):
```bash
# OLD:
TOPIC_NAME="no_name_error"
NAMING_STRATEGY="fallback"

if [ -f "$TOPIC_NAME_FILE" ]; then
  TOPIC_NAME=$(cat "$TOPIC_NAME_FILE" 2>/dev/null | tr -d '\n' | tr -d ' ')
  if [ -z "$TOPIC_NAME" ]; then
    NAMING_STRATEGY="agent_empty_output"
    TOPIC_NAME="no_name_error"
  fi
  # ... validation ...
fi

# NEW:
TOPIC_NAME=""
NAMING_STRATEGY="fallback"

if [ -f "$TOPIC_NAME_FILE" ]; then
  TOPIC_NAME=$(cat "$TOPIC_NAME_FILE" 2>/dev/null | tr -d '\n' | tr -d ' ')
  if [ -z "$TOPIC_NAME" ]; then
    NAMING_STRATEGY="agent_empty_output"
  elif ! echo "$TOPIC_NAME" | grep -qE '^[a-z0-9_]{5,40}$'; then
    NAMING_STRATEGY="validation_failed"
    TOPIC_NAME=""
  else
    NAMING_STRATEGY="llm_generated"
  fi
else
  NAMING_STRATEGY="agent_no_output_file"
fi

# Generate fallback if agent failed
if [ -z "$TOPIC_NAME" ]; then
  TOPIC_NAME="optimize_claude_$(date +%Y%m%d_%H%M%S)"
  echo "NOTE: Using timestamp-based fallback name (agent failed: $NAMING_STRATEGY)"
fi
```

**Testing**:
```bash
# Test normal operation (agent succeeds)
/optimize-claude --dry-run
# Expected: LLM-generated semantic name

# Test forced agent failure (mock test harness)
# Create mock agent output file with empty content
mkdir -p "${HOME}/.claude/tmp"
touch "${HOME}/.claude/tmp/topic_name_optimize_claude.txt"
/optimize-claude --dry-run
# Expected: Fallback name like "optimize_claude_20251201_143022"

# Verify uniqueness with multiple failures
/optimize-claude --dry-run
sleep 1
/optimize-claude --dry-run
# Expected: Two unique timestamp-based directories
ls -d .claude/specs/*optimize_claude_* | wc -l
# Should be: 2
```

**Expected Duration**: 30 minutes

---

### Phase 5: Standardize Argument Capture Pattern [COMPLETE]
dependencies: [1]

**Objective**: Refactor to 2-block argument capture pattern consistent with /research, /plan, /repair commands

**Complexity**: Medium

**Tasks**:
- [x] Open `/home/benjamin/.config/.claude/commands/optimize-claude.md`
- [x] Replace lines 64-102 (current direct argument parsing) with 2-block pattern
- [x] **Block 1a: Mechanical Capture** (lines 38-60 → expand to include capture)
  - Add temp file creation for user description
  - Include explicit "YOUR_DESCRIPTION_HERE" substitution marker
  - Write path to tracking file for Block 2
- [x] **Block 1b: Validation and Flag Parsing** (new block, insert after Block 1a)
  - Read captured description from temp file
  - Parse flags from description: --threshold, --aggressive, --balanced, --conservative, --dry-run, --file
  - Extract and clean description text
  - Set default values for missing flags
- [x] Update Block 1c (topic naming) to use cleaned DESCRIPTION variable
- [x] Test with various input formats

**Block 1a: Mechanical Capture** (replace lines 38-60):
```markdown
## Block 1a: Capture User Description

**EXECUTE NOW**: Capture the user-provided description and flags.

Replace `YOUR_DESCRIPTION_HERE` with the actual user input:

```bash
set +H
# Setup
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/optimize_claude_arg_$(date +%s%N).txt"

# Capture user description (Claude will substitute)
echo "YOUR_DESCRIPTION_HERE" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/optimize_claude_arg_path.txt"
echo "Description captured to $TEMP_FILE"
```
```

**Block 1b: Validation and Flag Parsing** (new, insert after Block 1a):
```markdown
## Block 1b: Validate and Parse Arguments

**EXECUTE NOW**: Read captured description, parse flags, and validate:

```bash
set +H
# Source required libraries
source "${HOME}/.claude/lib/core/state-persistence.sh" 2>/dev/null || { echo "Error: Cannot load state-persistence library"; exit 1; }
source "${HOME}/.claude/lib/core/error-handling.sh" 2>/dev/null || { echo "Error: Cannot load error-handling library"; exit 1; }
source "${HOME}/.claude/lib/util/optimize-claude-md.sh" 2>/dev/null || { echo "Error: Cannot load optimize-claude-md library"; exit 1; }

# Initialize error logging
ensure_error_log_exists
COMMAND_NAME="/optimize-claude"
WORKFLOW_ID="optimize_claude_$(date +%s)"
USER_ARGS="$*"

# Read captured description
PATH_FILE="${HOME}/.claude/tmp/optimize_claude_arg_path.txt"
if [ -f "$PATH_FILE" ]; then
  TEMP_FILE=$(cat "$PATH_FILE")
else
  TEMP_FILE="${HOME}/.claude/tmp/optimize_claude_arg.txt"  # Legacy fallback
fi

if [ -f "$TEMP_FILE" ]; then
  DESCRIPTION=$(cat "$TEMP_FILE")
else
  echo "ERROR: Argument file not found" >&2
  echo "Usage: /optimize-claude \"[description] [--threshold <profile>] [--dry-run] [--file <path>]\"" >&2
  exit 1
fi

# Use default if empty
if [ -z "$DESCRIPTION" ]; then
  DESCRIPTION="Optimize CLAUDE.md structure and documentation"
fi

# Parse flags from description
THRESHOLD="balanced"  # Default
DRY_RUN=false
ADDITIONAL_REPORTS=()

# Extract --threshold flag
if echo "$DESCRIPTION" | grep -qE '\--threshold\s+\w+'; then
  THRESHOLD=$(echo "$DESCRIPTION" | grep -oE '\--threshold\s+\w+' | awk '{print $2}')
  DESCRIPTION=$(echo "$DESCRIPTION" | sed -E 's/--threshold\s+\w+//g')
fi

# Extract shorthand threshold flags
if echo "$DESCRIPTION" | grep -q '\--aggressive'; then
  THRESHOLD="aggressive"
  DESCRIPTION=$(echo "$DESCRIPTION" | sed 's/--aggressive//g')
fi
if echo "$DESCRIPTION" | grep -q '\--balanced'; then
  THRESHOLD="balanced"
  DESCRIPTION=$(echo "$DESCRIPTION" | sed 's/--balanced//g')
fi
if echo "$DESCRIPTION" | grep -q '\--conservative'; then
  THRESHOLD="conservative"
  DESCRIPTION=$(echo "$DESCRIPTION" | sed 's/--conservative//g')
fi

# Extract --dry-run flag
if echo "$DESCRIPTION" | grep -q '\--dry-run'; then
  DRY_RUN=true
  DESCRIPTION=$(echo "$DESCRIPTION" | sed 's/--dry-run//g')
fi

# Extract --file flags (repeatable)
while echo "$DESCRIPTION" | grep -qE '\--file\s+\S+'; do
  FILE_PATH=$(echo "$DESCRIPTION" | grep -oE '\--file\s+\S+' | head -1 | awk '{print $2}')
  ADDITIONAL_REPORTS+=("$FILE_PATH")
  DESCRIPTION=$(echo "$DESCRIPTION" | sed -E "s/--file\s+\S+//1")  # Remove first occurrence
done

# Clean whitespace
DESCRIPTION=$(echo "$DESCRIPTION" | xargs)

# Validate threshold
if [[ ! "$THRESHOLD" =~ ^(aggressive|balanced|conservative)$ ]]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "validation_error" \
    "Invalid threshold profile: $THRESHOLD" "argument_validation" \
    "{\"threshold\": \"$THRESHOLD\", \"valid_values\": [\"aggressive\", \"balanced\", \"conservative\"]}"
  echo "ERROR: Invalid threshold '$THRESHOLD'. Valid values: aggressive, balanced, conservative" >&2
  exit 1
fi

# Validate --file paths if provided
for report_path in "${ADDITIONAL_REPORTS[@]}"; do
  if [ ! -f "$report_path" ]; then
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "file_error" \
      "Additional report file not found: $report_path" "argument_validation" \
      "{\"file_path\": \"$report_path\"}"
    echo "ERROR: Report file not found: $report_path" >&2
    exit 1
  fi
done

echo "Description: $DESCRIPTION"
echo "Threshold: $THRESHOLD"
echo "Dry run: $DRY_RUN"
[ ${#ADDITIONAL_REPORTS[@]} -gt 0 ] && echo "Additional reports: ${#ADDITIONAL_REPORTS[@]} file(s)"

echo "[CHECKPOINT] Argument parsing complete"
echo "Context: WORKFLOW_ID=${WORKFLOW_ID}, THRESHOLD=${THRESHOLD}, DRY_RUN=${DRY_RUN}"
echo "Ready for: Topic naming agent invocation"
```
```

**Testing**:
```bash
# Test basic description
/optimize-claude "Refactor authentication docs"

# Test with flags
/optimize-claude "Improve CLAUDE.md readability --aggressive --dry-run"

# Test with additional reports
/optimize-claude "Context-aware optimization --file /path/to/report.md --conservative"

# Test with multiple additional reports
/optimize-claude "Comprehensive review --file /path/report1.md --file /path/report2.md"

# Test special characters
/optimize-claude "Optimize 'guides' & 'reference' docs --balanced"

# Verify all flags parsed correctly
# Check WORKFLOW_ID persisted
# Verify error logging integration
```

**Expected Duration**: 1 hour

---

### Phase 6: Add Checkpoint Format and Block Consolidation [COMPLETE]
dependencies: [5]

**Objective**: Add structured [CHECKPOINT] format and consolidate bash blocks from 4 to 3

**Complexity**: Low

**Tasks**:
- [x] **Consolidate Block 1a + Block 1c into Single Setup Block**
  - Merge argument capture (Block 1a), validation (Block 1b), and topic naming (Block 1c)
  - Single "Setup and Initialization" block covers: capture → validate → libraries → topic naming → path initialization
  - Reduces from 4 blocks (1a, 1b, 1c, 2) to 3 blocks (Setup, Execute, Cleanup)
- [x] **Add [CHECKPOINT] markers** with Context and Ready-for metadata:
  - After argument parsing: `[CHECKPOINT] Arguments validated`
  - After topic naming: `[CHECKPOINT] Topic path initialized`
  - After Stage 1: `[CHECKPOINT] Research complete (2 reports)`
  - After Stage 2: `[CHECKPOINT] Analysis complete (2 reports)`
  - After Stage 3: `[CHECKPOINT] Planning complete (1 plan)`
- [x] **Update informal status messages**
  - Replace: `echo "✓ Setup complete, ready for topic naming"` (line 190)
  - With: `[CHECKPOINT]` format including context
- [x] **Verify block count**
  - Final structure: Block 1 (Setup), Block 2 (Execute), Block 3 (Cleanup)
  - Total: 3 blocks (meets 2-3 block target)

**Checkpoint Format Example**:
```bash
echo "[CHECKPOINT] Arguments validated"
echo "Context: THRESHOLD=${THRESHOLD}, DRY_RUN=${DRY_RUN}, ADDITIONAL_REPORTS=${#ADDITIONAL_REPORTS[@]}"
echo "Ready for: Topic naming agent invocation"
```

**Block Structure After Consolidation**:
- **Block 1: Setup and Initialization** (consolidate 1a+1b+1c)
  - Capture user description
  - Validate and parse flags
  - Source libraries
  - Invoke topic naming agent
  - Initialize workflow paths
  - [CHECKPOINT] Setup complete
- **Block 2: Execute Agent Workflow** (existing, keep)
  - Stage 1: Parallel research agents
  - [CHECKPOINT] Research complete
  - Stage 2: Parallel analysis agents
  - [CHECKPOINT] Analysis complete
  - Stage 3: Sequential planning agent
  - [CHECKPOINT] Planning complete
- **Block 3: Display Results and Cleanup** (existing, keep)
  - Summary table
  - Artifact paths
  - Next steps

**Testing**:
```bash
# Run command and verify checkpoint output
/optimize-claude --dry-run 2>&1 | grep '\[CHECKPOINT\]'

# Expected checkpoints:
# [CHECKPOINT] Arguments validated
# [CHECKPOINT] Topic path initialized
# [CHECKPOINT] Research complete (2 reports)
# [CHECKPOINT] Analysis complete (2 reports)
# [CHECKPOINT] Planning complete (1 plan)

# Count bash blocks
grep -c '^```bash' .claude/commands/optimize-claude.md
# Expected: 3 (Setup, Execute, Cleanup)

# Verify context metadata present
/optimize-claude --dry-run 2>&1 | grep 'Context:'
# Expected: Multiple context lines with WORKFLOW_ID, flags, etc.
```

**Expected Duration**: 30 minutes

---

### Phase 7: Update Command Reference Documentation [COMPLETE]
dependencies: []

**Objective**: Add complete /optimize-claude entry to command-reference.md for discoverability

**Complexity**: Low

**Tasks**:
- [x] Open `/home/benjamin/.config/.claude/docs/reference/standards/command-reference.md`
- [x] Locate orchestrator commands section (after /repair, before /build)
- [x] Insert /optimize-claude entry with complete metadata
- [x] Include: Purpose, Usage, Type, Arguments, Agents, Output, Workflow, TODO.md flag, See links
- [x] Verify documentation builds (no broken links)
- [x] Verify all cross-references resolve

**Entry Template**:
```markdown
### /optimize-claude
**Purpose**: Analyze CLAUDE.md and .claude/docs/ structure to generate optimization plan for documentation bloat reduction and quality improvement

**Usage**: `/optimize-claude "[description] [--threshold <profile>] [--dry-run] [--file <report>]"`

**Type**: orchestrator

**Arguments**:
- `description` (optional): Custom description of optimization focus (default: "Optimize CLAUDE.md structure and documentation")
- `--threshold <profile>` (optional): Bloat detection threshold profile - aggressive (50/30 lines), balanced (80/50 lines), conservative (120/80 lines) (default: balanced)
- `--aggressive`: Shorthand for --threshold aggressive
- `--balanced`: Shorthand for --threshold balanced (default)
- `--conservative`: Shorthand for --threshold conservative
- `--dry-run` (optional): Preview workflow stages without executing agents
- `--file <path>` (optional, repeatable): Additional report file for context-aware analysis

**Agents Used**:
- `claude-md-analyzer` (Haiku 4.5): Analyze CLAUDE.md structure and identify bloated sections
- `docs-structure-analyzer` (Haiku 4.5): Analyze .claude/docs/ organization and identify integration opportunities
- `docs-bloat-analyzer` (Opus 4.5): Perform semantic bloat analysis and assess extraction risks using soft guidance model
- `docs-accuracy-analyzer` (Opus 4.5): Evaluate documentation quality across 6 dimensions (accuracy, completeness, consistency, timeliness, usability, clarity)
- `cleanup-plan-architect` (Sonnet 4.5): Synthesize research reports and generate implementation plan with advisory size guidance

**Output**: Optimization plan with CLAUDE.md extraction phases, bloat prevention tasks (soft guidance, not hard blockers), accuracy fixes, and quality improvements

**Workflow**: `setup → research (parallel: claude-md + docs-structure) → analysis (parallel: bloat + accuracy) → planning (cleanup-plan-architect) → display`

**Automatically updates TODO.md**: No (manual plan tracking via /build)

**See**: [optimize-claude.md](../../commands/optimize-claude.md)
```

**Testing**:
```bash
# Verify documentation builds
cd .claude/docs
# Check for broken links (if validator available)
bash ../scripts/validate-links-quick.sh reference/standards/command-reference.md

# Verify entry format matches other commands
grep -A 15 "### /optimize-claude" reference/standards/command-reference.md

# Verify cross-reference resolves
# Navigate to ../../commands/optimize-claude.md from reference/standards/
test -f ../commands/optimize-claude.md && echo "PASS: Link resolves" || echo "FAIL: Broken link"
```

**Expected Duration**: 15 minutes

---

## Testing Strategy

### Unit Tests

**1. Workflow Scope Validation**:
```bash
# Test valid scope accepted (after Phase 1)
/optimize-claude --dry-run
# Expected: No scope validation error

# Test that invalid scope would be rejected (library test)
source .claude/lib/workflow/workflow-initialization.sh
! initialize_workflow_paths "test" "invalid-scope" "1" "{}" 2>&1 | grep -q "Unknown workflow scope"
```

**2. Threshold Validation**:
```bash
# Test all valid threshold profiles
for profile in aggressive balanced conservative; do
  /optimize-claude "Test $profile" --threshold $profile --dry-run
done

# Test invalid threshold
! /optimize-claude --threshold invalid 2>&1 | grep -q "Invalid threshold"
```

**3. Argument Capture and Flag Parsing**:
```bash
# Test basic description
/optimize-claude "Simple description test"

# Test with special characters
/optimize-claude "Test 'quotes' and \"escapes\" & symbols"

# Test flag combinations
/optimize-claude "Multi-flag test --aggressive --dry-run"
/optimize-claude --file /tmp/test_report.md --conservative

# Test multiple --file flags
touch /tmp/report1.md /tmp/report2.md
/optimize-claude --file /tmp/report1.md --file /tmp/report2.md --dry-run
```

### Integration Tests

**4. End-to-End Workflow Execution**:
```bash
# Test complete workflow with dry-run
/optimize-claude --balanced --dry-run

# Test complete workflow with real execution
/optimize-claude "Integration test execution" --conservative

# Verify all artifacts created
SPEC_DIR=$(ls -td .claude/specs/*optimize_claude* | head -1)
test -f "$SPEC_DIR/reports/001_claude_md_analysis.md" || echo "FAIL: Missing report 1"
test -f "$SPEC_DIR/reports/002_docs_structure_analysis.md" || echo "FAIL: Missing report 2"
test -f "$SPEC_DIR/reports/003_bloat_analysis.md" || echo "FAIL: Missing report 3"
test -f "$SPEC_DIR/reports/004_accuracy_analysis.md" || echo "FAIL: Missing report 4"
test -f "$SPEC_DIR/plans/001_optimization_plan.md" || echo "FAIL: Missing plan"
```

**5. Soft Guidance Language Verification**:
```bash
# Generate plan with aggressive threshold (more extractions = more guidance)
/optimize-claude "Soft guidance test" --aggressive

SPEC_DIR=$(ls -td .claude/specs/*optimize_claude* | head -1)

# Verify NO hard abort language in reports
! grep -r "STOP if\|must not exceed\|abort if" "$SPEC_DIR/reports/" && echo "PASS: No hard abort in reports" || echo "FAIL: Hard abort found"

# Verify NO hard abort language in plan
! grep -r "STOP if\|must not exceed\|abort if" "$SPEC_DIR/plans/" && echo "PASS: No hard abort in plan" || echo "FAIL: Hard abort found"

# Verify advisory language present
grep -r "WARNING\|RECOMMENDATION\|Risk Assessment\|consider\|suggest" "$SPEC_DIR/" | wc -l
# Expected: >10 instances
```

**6. Plan Execution Test**:
```bash
# Generate plan with large sections (aggressive threshold)
/optimize-claude "Plan execution test" --aggressive

# Find generated plan
PLAN=$(find .claude/specs -type f -name "*optimization_plan.md" | head -1)

# Execute plan with /build (dry-run to verify no aborts)
/build "$PLAN" --dry-run

# Expected: No workflow aborts on size warnings
# Expected: Post-merge review tasks added for files >600 lines (not blocking)
```

### Regression Tests

**7. Error Logging Integration**:
```bash
# Force validation error
! /optimize-claude --threshold invalid_profile 2>&1

# Verify error logged with correct type
/errors --command /optimize-claude --type validation_error --limit 1 | grep -q "Invalid threshold"

# Force file_error
! /optimize-claude --file /nonexistent/path.md 2>&1

# Verify file_error logged
/errors --command /optimize-claude --type file_error --limit 1 | grep -q "not found"
```

**8. Topic Naming Fallback**:
```bash
# Test timestamp-based fallback (requires mock agent failure)
# Manual test: Move topic-naming-agent.md temporarily to force failure
AGENT_BACKUP="/home/benjamin/.config/.claude/agents/topic-naming-agent.md.bak"
if [ -f "${AGENT_BACKUP%.bak}" ]; then
  mv "${AGENT_BACKUP%.bak}" "$AGENT_BACKUP"
  /optimize-claude --dry-run
  FALLBACK_DIR=$(ls -td .claude/specs/*optimize_claude_[0-9]* | head -1)
  test -d "$FALLBACK_DIR" && echo "PASS: Timestamp fallback created" || echo "FAIL: No fallback"
  mv "$AGENT_BACKUP" "${AGENT_BACKUP%.bak}"
fi
```

**9. Checkpoint Format Verification**:
```bash
# Run command and capture checkpoint output
OUTPUT=$(/optimize-claude --dry-run 2>&1)

# Verify checkpoint markers present
echo "$OUTPUT" | grep -c '\[CHECKPOINT\]'
# Expected: 5 checkpoints

# Verify context metadata
echo "$OUTPUT" | grep 'Context:' | grep -q 'WORKFLOW_ID=' && echo "PASS: Context metadata" || echo "FAIL: Missing context"

# Verify ready-for metadata
echo "$OUTPUT" | grep 'Ready for:' | wc -l
# Expected: 5 ready-for statements
```

**10. Block Consolidation Verification**:
```bash
# Count bash blocks in command file
BLOCK_COUNT=$(grep -c '^```bash' .claude/commands/optimize-claude.md)
test "$BLOCK_COUNT" -eq 3 && echo "PASS: 3 blocks (target met)" || echo "FAIL: $BLOCK_COUNT blocks (target: 3)"

# Verify block purposes
grep -E '^## Block [0-9]:' .claude/commands/optimize-claude.md
# Expected: Block 1: Setup, Block 2: Execute, Block 3: Cleanup
```

### Performance Tests

**11. Parallel Agent Execution Timing**:
```bash
# Time Stage 1 execution (parallel)
time /optimize-claude "Performance test Stage 1" --dry-run
# Expected: Stage 1 completes in ~30-45s (parallel), not 60-90s (sequential)

# Verify agents run concurrently (check timestamps in logs)
```

**12. Workflow State Transitions**:
```bash
# Verify state machine transitions for research-and-plan scope
/optimize-claude "State machine test"

# Check terminal state
STATE_FILE=$(find .claude/specs -name "workflow_state.json" | head -1)
grep -q '"state": "plan_ready"' "$STATE_FILE" && echo "PASS: Terminal state correct" || echo "FAIL: Wrong terminal state"
```

## Documentation Requirements

### Files to Update

1. **Command File** (all phases):
   - `/home/benjamin/.config/.claude/commands/optimize-claude.md`
   - Apply changes from Phases 1-6

2. **Agent Files** (Phases 2-3):
   - `/home/benjamin/.config/.claude/agents/docs-bloat-analyzer.md`
   - `/home/benjamin/.config/.claude/agents/cleanup-plan-architect.md`

3. **Command Reference** (Phase 7):
   - `/home/benjamin/.config/.claude/docs/reference/standards/command-reference.md`
   - Add /optimize-claude entry

4. **This Plan** (post-implementation):
   - Update status markers from [NOT STARTED] to [COMPLETE]
   - Document any deviations from plan
   - Add "Implementation Notes" section with lessons learned

### Documentation Standards Compliance

**README.md Requirements**:
- No new directories created (existing .claude/commands/, .claude/agents/)
- No README.md updates required

**Link Validity**:
- Verify command reference cross-references resolve
- Test navigation from command-reference.md to optimize-claude.md

**Content Standards**:
- Use clear, concise language
- Include code examples with syntax highlighting
- No emojis in file content (console output only)
- Follow CommonMark specification
- No historical commentary (clean-break development)

## Dependencies

**External Dependencies**:
- None (all changes internal to .claude/ system)

**Internal Dependencies**:
- Phases 2-3 depend on Phase 1 (workflow scope fix enables testing)
- Phase 5 depends on Phase 1 (argument capture needs valid initialization)
- Phase 6 depends on Phase 5 (block consolidation includes argument capture)
- Phase 7 has no dependencies (documentation only)

**Library Dependencies** (no changes required):
- `.claude/lib/util/optimize-claude-md.sh` (uses soft guidance already)
- `.claude/lib/workflow/workflow-initialization.sh` (validates scope correctly)
- `.claude/lib/core/state-persistence.sh` (no changes)
- `.claude/lib/core/error-handling.sh` (no changes)

**Standards Dependencies**:
- Command Authoring Standards (command-authoring.md)
- Output Formatting Standards (output-formatting.md)
- Error Logging Standards (error-handling.md from CLAUDE.md)
- Directory Organization Standards (directory-organization.md)

## Risk Mitigation

**Risk 1: Agent Behavioral Change (Phases 2-3)**
- **Mitigation**: Thorough testing of generated plans with various thresholds
- **Rollback**: Git revert to restore hard abort language if soft guidance causes issues
- **Validation**: Execute generated plans with /build to verify no regressions

**Risk 2: Argument Capture Refactor (Phase 5)**
- **Mitigation**: Preserve all flag parsing logic, only change structure
- **Rollback**: Restore direct $1 pattern if 2-block pattern causes issues
- **Validation**: Test with extensive flag combinations and special characters

**Risk 3: Block Consolidation (Phase 6)**
- **Mitigation**: Consolidate carefully, preserve all execution paths
- **Rollback**: Restore 4-block structure if consolidated blocks cause issues
- **Validation**: Verify checkpoints appear in correct sequence

**Risk 4: Standards Divergence**
- **Current Alignment**: Plan follows existing standards (no divergence)
- **No Phase 0 Required**: All changes align with command-authoring, output-formatting, error-logging standards

## Implementation Notes

**Execution Order**:
1. Phase 1 immediately (5 min) - enables testing of other phases
2. Phases 2-3 together (3 hours) - atomic soft guidance refactor
3. Phase 4 (30 min) - independent improvement
4. Phase 5 (1 hour) - enables user descriptions
5. Phase 6 (30 min) - polish and consolidation
6. Phase 7 (15 min) - documentation completeness

**Total Estimated Time**: 5.5 hours

**Critical Path**: Phase 1 → Phases 2-3 (must complete together for consistency)

**Optional Phases**: Phase 4, 6, 7 can be deferred if time-constrained

**Success Metrics**:
- Command initializes without scope errors
- Plans execute without size-based aborts
- Generated plans use advisory language only
- User can provide custom descriptions
- Checkpoint format provides visibility
- Documentation is discoverable

---

**Plan Complete**: 2025-12-01
**Plan Architect**: plan-architect agent (Opus 4.5)
**Total Tasks**: 61 across 7 phases
**Complexity**: Medium (refactor with standards alignment)
**Next Step**: Execute plan with /build or review plan for revisions
