# THEN Breakpoint Syntax Research Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Implementing 'THEN' breakpoint syntax for workflow commands
- **Report Type**: Implementation Options Analysis

## Executive Summary

This report analyzes implementation approaches for adding 'THEN' breakpoint syntax to workflow commands (/research, /debug, /plan, /revise) that enables multi-phase artifact passing. The codebase already uses a sophisticated two-step argument capture pattern with regex-based flag parsing for options like `--complexity`. Recommended approach is Option A (regex-based parsing) which matches existing patterns and provides the best balance of simplicity, consistency, and extensibility, requiring approximately 50-100 lines per command.

## Findings

### 1. Current Implementation Analysis

#### Argument Capture Pattern (All Four Commands)

All four target commands use an identical two-step argument capture pattern:

**Pattern Structure** (from `/home/benjamin/.config/.claude/commands/research.md:35-45`):
```bash
# Part 1: Explicit substitution by Claude
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/research_arg_$(date +%s%N).txt"
echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/research_arg_path.txt"
```

**Purpose**: Avoids shell expansion issues with special characters in user input. Claude performs explicit text substitution of the placeholder before execution.

#### Flag Parsing Pattern (from `/home/benjamin/.config/.claude/commands/plan.md:82-92`):
```bash
# Parse optional --complexity flag (default: 3 for research-and-plan)
DEFAULT_COMPLEXITY=3
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"

if [[ "$FEATURE_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  # Strip flag from feature description
  FEATURE_DESCRIPTION=$(echo "$FEATURE_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi
```

**Key Insight**: The codebase already uses regex pattern matching with `BASH_REMATCH` for extracting embedded flags, then strips them from the description. This same pattern can extend to THEN syntax.

#### State Machine Architecture

All commands use the state-based orchestration system defined in `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`:

- **8 explicit states**: initialize, research, plan, implement, test, debug, document, complete
- **Validated transitions**: State machine enforces valid state changes
- **Atomic transitions**: Two-phase commit pattern with checkpoints
- **Workflow scopes**: research-only, research-and-plan, full-implementation, debug-only

State transitions are controlled via `sm_transition()` calls (lines 55-63):
```bash
declare -gA STATE_TRANSITIONS=(
  [initialize]="research,implement"
  [research]="plan,complete"
  [plan]="implement,complete"
  [implement]="test"
  ...
)
```

#### Artifact Passing Between Phases

Currently, artifacts are passed between phases via:

1. **State persistence** (`/home/benjamin/.config/.claude/lib/state-persistence.sh`): GitHub Actions-style workflow state files
2. **append_workflow_state()**: Stores values across bash block boundaries
3. **File paths**: Reports, plans stored in specs directory with known paths

Example from `/home/benjamin/.config/.claude/commands/plan.md:389-391`:
```bash
REPORT_PATHS=$(find "$RESEARCH_DIR" -name '*.md' -type f | sort)
REPORT_PATHS_JSON=$(echo "$REPORT_PATHS" | jq -R . | jq -s .)
```

### 2. External Best Practices Analysis

#### Unix Shell Command Chaining Operators

Standard operators (from industry research):
- **`;`**: Sequential execution, always continues
- **`&&`**: Continue only if previous succeeds
- **`||`**: Continue only if previous fails
- **`|`**: Pipe output to next command

**Limitation**: These are shell-level operators, not suitable for user-provided argument strings that need internal parsing.

#### PowerShell Pipeline Pattern

PowerShell uses `ValueFromPipeline` and `ValueFromPipelineByPropertyName` attributes for parameter binding between cmdlets. Key design pattern:
- BEGIN/PROCESS/END blocks for handling pipeline input
- Metadata extraction for efficient passing

**Relevant Insight**: The metadata aggregation pattern aligns with how our supervisors reduce context (95% reduction).

#### Domain-Specific Language (DSL) Patterns

Workflow DSLs typically use keyword-based delimiters:
```
workflow {
  start "Start Task"
  then "Review Task" type Approval
  then "Send Notification" type Notification
  end
}
```

**Key Design Principles**:
- Simplicity: Clear, concise syntax within problem domain
- Expressiveness: Capture domain operations naturally
- Readability: Meaningful keywords, consistent naming

### 3. Use Case Scenarios

#### Primary Use Case
```bash
/research "authentication patterns" THEN /plan
```
- Research creates reports in specs/NNN_topic/reports/
- THEN triggers plan creation using those reports as input
- Plan architect receives report paths automatically

#### Extended Use Cases
```bash
# Research to plan with custom plan options
/research "OAuth2 flows --complexity 3" THEN /plan --complexity 4

# Debug with follow-up plan
/debug "timeout errors" THEN /plan "fix timeout issues"

# Plan then revise based on feedback
/plan "initial auth" THEN /revise "add MFA support"
```

### 4. Implementation Challenges

#### Challenge 1: Argument Boundary Detection

The THEN keyword must be distinguished from legitimate text:
- User input: `"research THEN keyword in documentation"`
- Chained commands: `"research patterns" THEN /plan`

**Solution**: Require format `THEN /command` (THEN followed by slash command)

#### Challenge 2: Case Sensitivity

Options to consider:
- **Case-sensitive** (`THEN`): Clearer visual delimiter, less ambiguity
- **Case-insensitive** (`THEN`, `Then`, `then`): More flexible, but "then" is common English word

**Recommendation**: Case-sensitive `THEN` (all caps) as visual delimiter, matching emphasis of action

#### Challenge 3: Artifact Context Passing

How to communicate output paths to next command:
- **Option A**: Environment variables (RESEARCH_OUTPUT_DIR)
- **Option B**: State file persistence (append_workflow_state)
- **Option C**: Direct substitution in next command invocation

**Existing Pattern**: Commands already use state persistence extensively.

NOTE: I want to continue to use state persistence here as well for uniformity and consistency

## Implementation Options Analysis

### Option A: Regex-Based Parsing at Command Invocation

**Implementation Location**: Within each command's Part 2 (validation) section

**Pattern**:
```bash
# Parse THEN delimiter to extract chained commands
NEXT_COMMAND=""
if [[ "$FEATURE_DESCRIPTION" =~ (.+)[[:space:]]THEN[[:space:]](/[a-z]+)(.*) ]]; then
  FEATURE_DESCRIPTION="${BASH_REMATCH[1]}"
  NEXT_COMMAND="${BASH_REMATCH[2]}"
  NEXT_COMMAND_ARGS="${BASH_REMATCH[3]}"
fi
```

**Implementation Complexity**: Low (50-100 lines per command)

**Strengths**:
- Matches existing `--complexity` parsing pattern exactly
- No new libraries or infrastructure required
- Easy to understand and maintain
- Immediate extraction at point of use

**Weaknesses**:
- Regex can become complex for nested THEN chains
- Some code duplication across commands
- Limited to single THEN (multi-THEN requires recursion)

**Error Handling**:
```bash
# Validate next command exists
if [ -n "$NEXT_COMMAND" ]; then
  VALID_COMMANDS="research|debug|plan|revise"
  if ! echo "$NEXT_COMMAND" | grep -qE "^/($VALID_COMMANDS)$"; then
    echo "ERROR: Invalid command after THEN: $NEXT_COMMAND"
    echo "Valid commands: /research, /debug, /plan, /revise"
    exit 1
  fi
fi
```

**Case Sensitivity Handling**:
```bash
# Case-sensitive (recommended)
if [[ "$FEATURE_DESCRIPTION" =~ (.+)[[:space:]]THEN[[:space:]]/.+ ]]; then

# Or case-insensitive variant
shopt -s nocasematch
if [[ "$FEATURE_DESCRIPTION" =~ (.+)[[:space:]]then[[:space:]]/.+ ]]; then
shopt -u nocasematch
```

---

### Option B: State Machine Extension with Explicit Phase Transitions

NOTE: I want to use this option

**Implementation Location**: `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`

**Pattern**:
```bash
# New state: THEN_PENDING
STATE_THEN_PENDING="then_pending"

# Extended transitions
[research]="plan,complete,then_pending"
[then_pending]="research,debug,plan,revise"

# Store queued command in state
sm_queue_then_command() {
  local next_cmd="$1"
  local next_args="$2"
  append_workflow_state "THEN_NEXT_COMMAND" "$next_cmd"
  append_workflow_state "THEN_NEXT_ARGS" "$next_args"
}
```

**Implementation Complexity**: Medium (150-250 lines in state machine + per-command updates)

**Strengths**:
- Formal state machine representation
- Natural fit with existing architecture
- Clear transition paths
- Supports complex multi-step chains

**Weaknesses**:
- Requires state machine library modifications
- More complex testing requirements
- May require checkpoint schema v2.1 update
- Higher cognitive overhead for understanding flow

**Error Handling**:
- Validation in `sm_transition()` prevents invalid THEN targets
- State persistence ensures recovery on failure

---

### Option C: Shell Script Preprocessing Layer

**Implementation Location**: New library `/home/benjamin/.config/.claude/lib/then-preprocessor.sh`

**Pattern**:
```bash
# Preprocess user input before command execution
preprocess_then_syntax() {
  local input="$1"
  local result=""

  # Split on THEN delimiter
  IFS=' THEN ' read -ra SEGMENTS <<< "$input"

  # Return first segment and queue remainder
  result="${SEGMENTS[0]}"

  if [ "${#SEGMENTS[@]}" -gt 1 ]; then
    # Queue subsequent commands
    for ((i=1; i<${#SEGMENTS[@]}; i++)); do
      queue_command "${SEGMENTS[$i]}"
    done
  fi

  echo "$result"
}
```

**Implementation Complexity**: Medium-High (200-300 lines new library + integration)

**Strengths**:
- Centralized parsing logic
- Supports multi-THEN chains naturally
- Clean separation of concerns
- Reusable across all commands

**Weaknesses**:
- New library to maintain
- IFS manipulation can be fragile
- Requires command queue management
- Additional complexity for single-THEN use case

**Error Handling**:
- Validate each segment before queuing
- Support for syntax error reporting with position

---

### Option D: JSON/Structured Input Format

**Implementation Location**: Each command's Part 1 capture

**Pattern**:
```bash
# User provides JSON structure
# /plan '{"description": "auth system", "then": {"command": "/debug", "args": "test failures"}}'

# Or structured syntax
# /plan [description: auth system, then: /debug "test failures"]

parse_structured_input() {
  local input="$1"

  if [[ "$input" =~ ^\{ ]]; then
    # JSON parsing with jq
    DESCRIPTION=$(echo "$input" | jq -r '.description')
    THEN_CMD=$(echo "$input" | jq -r '.then.command // empty')
    THEN_ARGS=$(echo "$input" | jq -r '.then.args // empty')
  fi
}
```

**Implementation Complexity**: High (200-400 lines for parser + schema validation)

**Strengths**:
- Unambiguous syntax
- Supports complex nested structures
- Future-proof for additional metadata
- jq already available in codebase

**Weaknesses**:
- Poor user experience (verbose syntax)
- Breaks natural language feel of commands
- Requires escaping quotes within JSON
- Significant departure from current patterns

---

### Option E: Marker-Based Inline Syntax

**Implementation Location**: Each command's argument parsing

**Pattern**:
```bash
# Use unique markers: <<THEN>> or %%THEN%%
/research "auth patterns" <<THEN>> /plan

# Parsing
if [[ "$INPUT" =~ (.+)<<THEN>>(.+) ]]; then
  CURRENT_CMD="${BASH_REMATCH[1]}"
  NEXT_CMD="${BASH_REMATCH[2]}"
fi
```

**Implementation Complexity**: Low (40-80 lines per command)

**Strengths**:
- Highly distinctive delimiter
- Minimal ambiguity with user text
- Simple regex parsing
- Visual clarity

**Weaknesses**:
- Awkward to type
- Non-standard syntax
- Less intuitive than plain THEN
- May conflict with heredoc syntax

## Implementation Options Comparison Table

| Criteria | Option A (Regex) | Option B (State Machine) | Option C (Preprocessor) | Option D (JSON) | Option E (Markers) |
|----------|-----------------|-------------------------|------------------------|----------------|-------------------|
| **Implementation Complexity** | Low | Medium | Medium-High | High | Low |
| **Lines of Code** | 50-100/cmd | 150-250 total | 200-300 total | 200-400 total | 40-80/cmd |
| **Pattern Consistency** | Excellent | Good | Fair | Poor | Fair |
| **User Experience** | Good | Good | Good | Poor | Fair |
| **Multi-THEN Support** | Limited | Good | Excellent | Excellent | Limited |
| **Error Handling** | Good | Excellent | Good | Good | Good |
| **Testing Effort** | Low | Medium | Medium | High | Low |
| **Extensibility** | Fair | Excellent | Good | Excellent | Fair |
| **Risk Level** | Low | Medium | Medium | High | Low |

## Cross-Command Consistency

### Shared Components

To ensure consistency across all four commands, the implementation should:

1. **Extract shared parsing logic** to `/home/benjamin/.config/.claude/lib/argument-capture.sh`:
   - Already exists for two-step capture
   - Add `parse_then_syntax()` function
   - Consistent error messages

2. **Standardize artifact passing**:
   - Define convention for output directory variables
   - Document in CLAUDE.md
   - Use existing `append_workflow_state()` pattern

3. **Unified validation**:
   - Valid THEN targets per command type
   - research -> plan, debug
   - debug -> plan, revise
   - plan -> debug, revise
   - revise -> plan, debug

### Implementation Sequence

1. Update `argument-capture.sh` with THEN parsing functions
2. Implement in `/research` first (simplest terminal state)
3. Add to `/plan` (bidirectional artifact flow)
4. Add to `/debug` (debug -> plan transition)
5. Add to `/revise` (plan modification workflow)
6. Create tests for all combinations

## Recommendations

### Primary Recommendation: Option A (Regex-Based Parsing)

**Rationale**:
1. **Pattern Consistency**: Directly mirrors the existing `--complexity` flag parsing pattern
2. **Low Risk**: No modifications to core state machine library
3. **Immediate Value**: Can be implemented incrementally per command
4. **Maintainability**: Easy to understand for future developers
5. **Testing**: Simple unit tests with bash regex matching

### Implementation Strategy

1. **Phase 1**: Add `parse_then_syntax()` to `argument-capture.sh` (~50 lines)
2. **Phase 2**: Integrate into `/research` command (~30 lines)
3. **Phase 3**: Add artifact context passing via state persistence
4. **Phase 4**: Extend to remaining commands

### Enhanced Recommendation (Future): Hybrid Approach

For future extensibility, consider combining Option A with elements of Option B:

1. Use regex parsing for immediate extraction (Option A)
2. Store queued command in state file for resilience
3. Add state machine transition for tracking (lightweight Option B)

This provides immediate value with a path to formal state tracking if multi-THEN becomes needed.

### Case Sensitivity Decision

**Recommendation**: Case-sensitive `THEN` (all caps)

- Visually distinctive as a delimiter keyword
- Avoids ambiguity with common English word "then"
- Consistent with uppercase convention for emphasis (like SQL keywords)
- Simple regex: `THEN[[:space:]]/`

### Error Messages

Provide clear, actionable error messages:
```bash
ERROR: Invalid THEN syntax
Usage: /research "description" THEN /plan [args]
       /research "description" THEN /debug [args]

Found: /research "auth patterns" THEN invalid-command
```

## References

### Files Analyzed

- `/home/benjamin/.config/.claude/commands/research.md`: Lines 35-92 (argument capture, flag parsing)
- `/home/benjamin/.config/.claude/commands/debug.md`: Lines 39-48 (complexity flag parsing)
- `/home/benjamin/.config/.claude/commands/plan.md`: Lines 82-92 (flag parsing pattern)
- `/home/benjamin/.config/.claude/commands/revise.md`: Lines 82-92 (flag parsing pattern)
- `/home/benjamin/.config/.claude/lib/argument-capture.sh`: Lines 78-168 (reusable capture library)
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`: Lines 55-63 (state transitions)
- `/home/benjamin/.config/.claude/lib/state-persistence.sh`: Referenced for artifact passing
- `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md`: Lines 1-100 (architecture context)

### External Sources

- Stack Overflow: CLI argument design patterns
- GeeksforGeeks: Linux command chaining operators
- Microsoft Learn: PowerShell pipeline parameter binding
- Martin Fowler: DSL Patterns catalog
- Medium: Building custom DSLs

### Related Documentation

- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents.md`: Agent artifact passing
- `/home/benjamin/.config/.claude/docs/reference/command-reference.md`: Command catalog

## Implementation Status

- **Status**: Planning In Progress
- **Plan**: [../../775_use_homebenjaminconfigclaudespecs774_for_the_resea/plans/001_option_b_state_machine_then_plan.md](../../775_use_homebenjaminconfigclaudespecs774_for_the_resea/plans/001_option_b_state_machine_then_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-17
