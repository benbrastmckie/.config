# Documentation Standards Update Research Report

## Metadata
- **Date**: 2025-11-18
- **Agent**: research-specialist
- **Topic**: Update .claude/docs/ standards to enforce clean and concise comments approach
- **Report Type**: codebase analysis and standards update
- **Source Plan**: /home/benjamin/.config/.claude/specs/778_doesnt_the_state_machine_provide_something_similar/plans/001_comprehensive_output_formatting_refactor.md

## Executive Summary

This report identifies eight documentation files in .claude/docs/ that require updates to enforce the clean and concise commenting approach from the output formatting refactor plan. The key patterns to standardize are: output suppression via `2>/dev/null`, single summary lines per bash block, block consolidation from 6-11 blocks to 2-3 per command, and minimal inline comments explaining WHAT not WHY. The existing standards already establish the "WHAT not WHY" pattern in code-standards.md:36 and executable-documentation-separation.md:71, but lack specific enforcement for output suppression and block consolidation patterns.

## Findings

### Finding 1: Existing "WHAT not WHY" Comment Standard

The codebase already establishes the clean comment philosophy in multiple locations:

**Primary Standard Definition** (code-standards.md:36):
```markdown
- **Executable Files** (`.claude/commands/*.md`, `.claude/agents/*.md`): Lean execution scripts (<250 lines for commands, <400 lines for agents) containing bash blocks, phase markers, and minimal inline comments (WHAT not WHY)
```

**Supporting Pattern Documentation** (executable-documentation-separation.md:71, 382, 436):
- Line 71: "Minimal inline comments explaining WHAT (not WHY)"
- Line 382: "Comments must be minimal: Only WHAT (not WHY) to avoid conversation"
- Line 436: "Inline comments for critical WHAT explanations only"

**Template Guidance** (_template-executable-command.md:28):
```markdown
# Inline comments explain WHAT is being done, not WHY (WHY belongs in guide)
```

**Current Gap**: The standard is established but not expanded with specific enforcement patterns for output formatting.

### Finding 2: Missing Output Suppression Pattern Standard

The plan introduces a critical output suppression pattern that is not currently documented in standards:

**Pattern from Plan** (lines 94-108):
```bash
# Suppress library sourcing
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh" 2>/dev/null

# Redirect diagnostics to log file
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"
if ! operation; then
  echo "ERROR: Operation failed (see $DEBUG_LOG)" >&2
  echo "[$(date)] Details..." >> "$DEBUG_LOG"
  exit 1
fi

# Single summary line per block
echo "Setup complete: $WORKFLOW_ID"
```

**Current Standards Gap**:
- command-authoring-standards.md mentions `2>/dev/null` only once (line 145, for mkdir)
- bash-block-execution-model.md doesn't discuss output suppression
- logging-patterns.md focuses on progress markers but not output suppression

### Finding 3: Missing Block Consolidation Standard

The plan defines a block consolidation pattern that reduces display noise by 70%:

**Pattern from Plan** (lines 73-91):
```
Before (6 blocks):
Block 1: Capture arguments
Block 2: Validate arguments
Block 3: Initialize state machine
Block 4: Allocate topic directory
Block 5: Verify artifacts
Block 6: Complete workflow

After (2-3 blocks):
Block 1: Setup (capture, validate, init, allocate)
Block 2: Execute (main workflow logic)
Block 3: Cleanup (verify, complete)
```

**Current Standards Gap**:
- bash-block-execution-model.md documents subprocess isolation but not block minimization
- command-authoring-standards.md doesn't address block count optimization
- No standard exists for when to consolidate blocks

### Finding 4: Inconsistent Guidance on Library Sourcing Output

Current templates show verbose library sourcing:

**_template-bash-block.md** (lines 32-44):
```bash
if [ -f "${LIB_DIR}/workflow-state-machine.sh" ]; then
  source "${LIB_DIR}/workflow-state-machine.sh"
else
  echo "ERROR: workflow-state-machine.sh not found"
  exit 1
fi
```

**Inconsistency**: This pattern generates verbose output. The refactor plan recommends:
```bash
source "${LIB_DIR}/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: workflow-state-machine.sh not found" >&2
  exit 1
}
```

### Finding 5: State Persistence Pattern is Established

The plan references state-persistence.sh which is already well-documented:

**command-authoring-standards.md** (lines 229-244):
- Documents `append_workflow_state`, `load_workflow_state`, `init_workflow_state`
- Shows proper usage pattern across bash blocks

**Current Status**: This standard is complete and consistent with the plan - no update needed.

### Finding 6: Files Requiring Updates

Based on the analysis, these 8 files require updates to enforce the output formatting approach:

1. **/home/benjamin/.config/.claude/docs/reference/code-standards.md** - Add output suppression and block consolidation standards
2. **/home/benjamin/.config/.claude/docs/reference/command-authoring-standards.md** - Add output suppression section
3. **/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md** - Add block consolidation pattern
4. **/home/benjamin/.config/.claude/docs/guides/_template-bash-block.md** - Update library sourcing to use suppression
5. **/home/benjamin/.config/.claude/docs/guides/logging-patterns.md** - Add output suppression guidance
6. **/home/benjamin/.config/.claude/docs/concepts/patterns/executable-documentation-separation.md** - Add output formatting to pattern benefits
7. **/home/benjamin/.config/.claude/docs/guides/command-development-fundamentals.md** - Add block consolidation guidance
8. **/home/benjamin/.config/.claude/docs/concepts/writing-standards.md** - No changes needed (already focuses on prose, not code comments)

### Finding 7: Potential Conflicts with Verbose Error Patterns

Some existing patterns in standards conflict with output suppression:

**error-enhancement-guide.md** promotes verbose WHICH/WHAT/WHERE error messages:
```markdown
ERROR: [WHICH] - [WHAT]: [WHERE]
Context: [details]
Recovery: [steps]
```

**Reconciliation Needed**: Output suppression applies to success/progress output, not errors. Errors should remain verbose. This distinction must be explicit in updated standards.

### Finding 8: Existing Progress Marker Standards

The logging-patterns.md file establishes progress marker format:

**Format** (lines 26-28):
```
PROGRESS: [phase/context] - [action_description]
```

**Alignment**: This aligns with the plan's single summary line approach. The standard should clarify that PROGRESS markers are the preferred output during block execution, replacing verbose intermediate output.

## Recommendations

### Recommendation 1: Add Output Suppression Standard to code-standards.md

Add a new subsection under "Command and Agent Architecture Standards":

```markdown
### Output Suppression Patterns
[Used by: All workflow commands, orchestrators]

Suppress intermediate output to reduce display noise while preserving error visibility:

**Library Sourcing**:
```bash
# Suppress success output, show errors
source "${LIB_DIR}/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Library not found" >&2
  exit 1
}
```

**Directory Operations**:
```bash
mkdir -p "$DIR" 2>/dev/null || true
```

**Single Summary Line per Block**:
```bash
# After all operations in block complete
echo "Setup complete: $WORKFLOW_ID"
```

**Debug Log Pattern**:
```bash
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"
# ... operations ...
if [ $? -ne 0 ]; then
  echo "ERROR: Operation failed (see $DEBUG_LOG)" >&2
fi
```

**Rationale**: Each bash block displays truncated output in Claude Code. Reducing verbose output improves signal-to-noise ratio by 50%+.
```

### Recommendation 2: Add Block Consolidation Pattern to bash-block-execution-model.md

Add new section "Pattern 8: Block Count Minimization":

```markdown
### Pattern 8: Block Count Minimization

**Problem**: Each bash block displays separately in Claude Code with truncated output, creating visual noise.

**Solution**: Consolidate related operations into fewer blocks.

**Target**: 2-3 blocks per command (down from 6-11 typical)

**Block Structure**:
- **Block 1 (Setup)**: Capture arguments, validate, source libraries, init state, allocate paths
- **Block 2 (Execute)**: Main workflow logic, agent invocations
- **Block 3 (Cleanup)**: Verify artifacts, complete workflow, emit summary

**Consolidation Rules**:
1. Operations that share the same subprocess state can be combined
2. Operations that don't require user visibility between them should be combined
3. Agent invocations (Task tool) typically need separate blocks for response capture
4. Final summary should be in its own block for visibility

**Example Consolidation**:
```bash
# Block 1: Consolidated Setup
set +H
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# Capture and validate arguments
WORKFLOW_DESC="$1"
[ -z "$WORKFLOW_DESC" ] && { echo "ERROR: Description required" >&2; exit 1; }

# Source libraries (suppressed)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh" 2>/dev/null

# Initialize state
WORKFLOW_ID="command_$(date +%s)"
init_workflow_state "$WORKFLOW_ID"
sm_init "$WORKFLOW_DESC" "command" "research-only"

# Allocate paths
TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESC" ".claude/specs")

echo "Setup complete: $WORKFLOW_ID"
```

**Benefits**:
- 50-67% reduction in displayed blocks
- 70%+ reduction in output noise
- Better context preservation for Claude
- Clearer workflow structure
```

### Recommendation 3: Update _template-bash-block.md Library Sourcing

Update lines 32-44 to use suppressed pattern:

```bash
# === STEP 1: Source State Machine and Persistence (FIRST) ===
# Suppress library sourcing output while preserving error visibility

source "${LIB_DIR}/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: workflow-state-machine.sh not found" >&2
  exit 1
}

source "${LIB_DIR}/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: state-persistence.sh not found" >&2
  exit 1
}
```

### Recommendation 4: Add Output vs Error Distinction to logging-patterns.md

Add clarification section:

```markdown
### Output vs Error Distinction

**Suppress**: Success output, progress chatter, intermediate state
- `mkdir -p "$DIR" 2>/dev/null`
- `source lib.sh 2>/dev/null`

**Preserve**: Errors, warnings, completion summaries
- `echo "ERROR: File not found" >&2`
- `echo "Setup complete: $WORKFLOW_ID"`
- `PROGRESS: Phase 1 complete`

**Pattern**: Redirect success to /dev/null, keep stderr visible
```

### Recommendation 5: Add WHAT-Only Comment Enforcement Examples

Add to code-standards.md under the existing "WHAT not WHY" standard:

```markdown
**Comment Enforcement Examples**:

```bash
# WHAT (correct - action being performed)
source "${LIB_DIR}/state-persistence.sh"  # Load state management functions

# WHY (incorrect - belongs in guide documentation)
# We source this library because subprocess isolation requires
# re-sourcing in each bash block due to the execution model...

# WHAT (correct - purpose of operation)
append_workflow_state "REPORT_PATHS" "$JSON"  # Save report paths for next block

# WHY (incorrect - rationale belongs in guide)
# Arrays don't persist across bash blocks due to subprocess isolation,
# so we serialize to JSON and persist via state file...
```

### Recommendation 6: Update command-development-fundamentals.md Section 5

Add guidance on block structure to the fundamentals:

```markdown
### 5.3 Block Structure Optimization

Commands should target 2-3 bash blocks for optimal display in Claude Code:

**Block 1: Setup** - All initialization including argument capture, validation, library sourcing, state initialization, and path allocation

**Block 2: Execute** - Main workflow logic (may include Task tool invocations which naturally separate)

**Block 3: Cleanup** - Verification, completion, and summary output

**Why This Matters**: Each bash block displays separately with truncated output. Fewer blocks means:
- Less visual noise (70%+ reduction)
- Better context preservation
- Clearer workflow structure
- Faster execution visibility
```

### Recommendation 7: Create New Reference Document

Create `/home/benjamin/.config/.claude/docs/reference/output-formatting-standards.md`:

```markdown
# Output Formatting Standards

[Used by: /coordinate, /research, /build, /plan, all workflow commands]

Standards for clean, concise output in workflow command bash blocks.

## Core Principles

1. **Suppress intermediate output** - Only summary and errors visible
2. **Single summary line per block** - "Setup complete: $ID"
3. **Minimize block count** - Target 2-3 blocks per command
4. **Preserve error visibility** - stderr always shown
5. **WHAT not WHY comments** - Brief inline, rationale in guides

## Output Suppression Patterns

[Full pattern documentation...]

## Block Consolidation Patterns

[Full pattern documentation...]

## Comment Standards

[Full WHAT not WHY enforcement with examples...]

## Related Documentation

- [Bash Block Execution Model](../concepts/bash-block-execution-model.md)
- [Command Authoring Standards](command-authoring-standards.md)
- [Logging Patterns](../guides/logging-patterns.md)
```

### Recommendation 8: Add Standards Section to CLAUDE.md

Add new section to CLAUDE.md referencing the output formatting standards:

```markdown
<!-- SECTION: output_formatting -->
## Output Formatting Standards
[Used by: /coordinate, /research, /build, /plan, all workflow commands]

See [Output Formatting Standards](.claude/docs/reference/output-formatting-standards.md) for clean output patterns including suppression, block consolidation, and comment standards.
<!-- END_SECTION: output_formatting -->
```

## References

### Files Analyzed (with key line numbers)

1. **/home/benjamin/.config/.claude/docs/reference/code-standards.md** - Lines 36 (WHAT not WHY), 51 (development guides)
2. **/home/benjamin/.config/.claude/docs/reference/command-authoring-standards.md** - Lines 145 (mkdir 2>/dev/null), 229-244 (state persistence)
3. **/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md** - Lines 309-339 (Pattern 1), 405-427 (Pattern 4)
4. **/home/benjamin/.config/.claude/docs/guides/_template-bash-block.md** - Lines 32-44 (library sourcing), 183-196 (library sourcing order)
5. **/home/benjamin/.config/.claude/docs/guides/logging-patterns.md** - Lines 26-28 (progress format), 693-705 (best practices)
6. **/home/benjamin/.config/.claude/docs/concepts/patterns/executable-documentation-separation.md** - Lines 71, 382, 436 (WHAT not WHY)
7. **/home/benjamin/.config/.claude/docs/concepts/writing-standards.md** - Lines 21-27 (development philosophy)
8. **/home/benjamin/.config/.claude/specs/778_doesnt_the_state_machine_provide_something_similar/plans/001_comprehensive_output_formatting_refactor.md** - Lines 73-91 (block structure), 94-108 (output suppression)

### External Standards Referenced

- GNU Bash Manual, section 3.5.3 (Shell Parameter Expansion) - Referenced in bash-block-execution-model.md:556-559
- CLAUDE.md Development Philosophy - Clean-break approach
- ShellCheck recommendations - Referenced in code-standards.md:15

### Related Specifications

- Spec 778: State machine option compatibility (output formatting options A/B/C)
- Spec 773: Build command output formatting revised report
- Spec 620: Bash history expansion fixes (subprocess isolation discovery)
- Spec 630: State persistence architecture
