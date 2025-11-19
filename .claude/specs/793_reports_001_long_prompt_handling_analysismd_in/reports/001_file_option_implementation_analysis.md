# --file Option Implementation Analysis for Commands with Research Phases

## Metadata
- **Date**: 2025-11-18
- **Agent**: research-specialist
- **Topic**: --file option for long prompts in /plan, /coordinate, /research, /debug
- **Report Type**: codebase analysis
- **Prior Research**: /home/benjamin/.config/.claude/specs/791_prompt_examplemd_which_i_want_you_to_review_as/reports/001_long_prompt_handling_analysis.md

## Executive Summary

Analysis of four commands with research phases (/plan, /research, /debug, /coordinate) reveals a consistent two-step argument capture pattern that can be extended to support --file for long prompts. The implementation requires: (1) parsing --file flag alongside existing --complexity flag, (2) copying prompt file to specs directory for archival, (3) persisting original file path in workflow state via append_workflow_state(), and (4) passing the path to research subagents through Task tool prompt templates. The existing summarization behavior for FEATURE_DESCRIPTION should be preserved for backward compatibility while the original prompt file provides verbatim access for research agents.

## Findings

### 1. Commands with Research Phases - Identification

Four commands invoke the research-specialist agent and need --file support:

| Command | Variable Name | Line Reference | Default Complexity |
|---------|--------------|----------------|-------------------|
| /plan | FEATURE_DESCRIPTION | plan.md:43 | 3 |
| /research | WORKFLOW_DESCRIPTION | research.md:42 | 2 |
| /debug | ISSUE_DESCRIPTION | debug.md:30 | 2 |
| /coordinate | WORKFLOW_DESCRIPTION | coordinate.md:39 | N/A (full workflow) |

Reference: `/home/benjamin/.config/.claude/commands/plan.md:43`, `/home/benjamin/.config/.claude/commands/research.md:42`, `/home/benjamin/.config/.claude/commands/debug.md:30`, `/home/benjamin/.config/.claude/commands/coordinate.md:39`

### 2. Current Argument Capture Pattern Analysis

All commands follow the two-step execution pattern to avoid positional parameter issues:

#### Step 1: Capture to Temp File
```bash
# Example from plan.md:37-44
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/plan_arg_$(date +%s%N).txt"
echo "YOUR_FEATURE_DESCRIPTION_HERE" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/plan_arg_path.txt"
```

#### Step 2: Read and Parse Flags
```bash
# Example from plan.md:55-62
# Parse optional --complexity flag (default: 3 for research-and-plan)
if [[ "$FEATURE_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  FEATURE_DESCRIPTION=$(echo "$FEATURE_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi
```

Reference: `/home/benjamin/.config/.claude/commands/plan.md:37-44`, `/home/benjamin/.config/.claude/commands/plan.md:55-62`

### 3. State Persistence Architecture

The state-persistence.sh library provides the mechanism to pass information to subagents:

#### Key Functions
- `init_workflow_state()` - Creates workflow state file (line 130)
- `append_workflow_state()` - Appends key-value pairs to state (line 321)
- `load_workflow_state()` - Restores state in subsequent blocks (line 212)

#### Variable Export Pattern
```bash
# From plan.md:148-156
append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"
append_workflow_state "SPECS_DIR" "$SPECS_DIR"
append_workflow_state "FEATURE_DESCRIPTION" "$FEATURE_DESCRIPTION"
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
```

Reference: `/home/benjamin/.config/.claude/lib/state-persistence.sh:130`, `/home/benjamin/.config/.claude/lib/state-persistence.sh:321`, `/home/benjamin/.config/.claude/commands/plan.md:148-156`

### 4. Subagent Invocation Pattern

Research agents receive context through Task tool prompt templates:

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research ${FEATURE_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are conducting research for: plan workflow

    **Workflow-Specific Context**:
    - Research Topic: ${FEATURE_DESCRIPTION}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Output Directory: ${RESEARCH_DIR}
    - Workflow Type: research-and-plan
  "
}
```

Reference: `/home/benjamin/.config/.claude/commands/plan.md:165-183`

### 5. Topic Directory Structure

The workflow-initialization.sh library manages specs directory creation:

```bash
# From workflow-initialization.sh:426-436
if [ -d "${project_root}/.claude/specs" ]; then
  specs_root="${project_root}/.claude/specs"
elif [ -d "${project_root}/specs" ]; then
  specs_root="${project_root}/specs"
else
  specs_root="${project_root}/.claude/specs"
  mkdir -p "$specs_root"
fi

# Topic path calculation (line 526)
topic_path="${specs_root}/${topic_num}_${topic_name}"
```

Reference: `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:426-436`, `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:526`

### 6. Prior Research Recommendation (from Report 001)

The prior research at `/home/benjamin/.config/.claude/specs/791_prompt_examplemd_which_i_want_you_to_review_as/reports/001_long_prompt_handling_analysis.md:250-251` explicitly recommended:

> For prompts exceeding 5,000 characters, consider:
> 1. **File-based input**: `/plan --file /path/to/spec.md`

This validates the user's request for the --file option.

Reference: `/home/benjamin/.config/.claude/specs/791_prompt_examplemd_which_i_want_you_to_review_as/reports/001_long_prompt_handling_analysis.md:250-251`

### 7. Modification Points Identified

For each command, the following sections require modification:

#### Block 1 Modifications (4 commands)

| Command | Line Range | Modification Type |
|---------|------------|-------------------|
| plan.md | 55-62 | Add --file parsing after --complexity |
| research.md | 54-60 | Add --file parsing after --complexity |
| debug.md | 39-45 | Add --file parsing after --complexity |
| coordinate.md | 87-97 | Add --file parsing in WORKFLOW_DESCRIPTION validation |

#### State Persistence Additions (4 commands)

| Command | Line Range | New Variables |
|---------|------------|---------------|
| plan.md | 148-156 | ORIGINAL_PROMPT_FILE_PATH |
| research.md | 143-149 | ORIGINAL_PROMPT_FILE_PATH |
| debug.md | 144-147 | ORIGINAL_PROMPT_FILE_PATH |
| coordinate.md | 166-175 | ORIGINAL_PROMPT_FILE_PATH |

#### Task Tool Prompts (4 commands)

| Command | Line Range | Add to Context |
|---------|------------|----------------|
| plan.md | 165-183 | - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH} |
| research.md | 157-175 | - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH} |
| debug.md | 282-303 | - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH} |
| coordinate.md | 193+ | - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH} |

## Recommendations

### Recommendation 1: Add --file Flag Parsing Logic

Add the following bash code after existing --complexity parsing:

```bash
# Parse optional --file flag for long prompts
ORIGINAL_PROMPT_FILE_PATH=""
if [[ "$FEATURE_DESCRIPTION" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
  SOURCE_FILE="${BASH_REMATCH[1]}"

  # Validate source file exists
  if [ ! -f "$SOURCE_FILE" ]; then
    echo "ERROR: Prompt file not found: $SOURCE_FILE" >&2
    exit 1
  fi

  # Store original path for subagents
  ORIGINAL_PROMPT_FILE_PATH="$SOURCE_FILE"

  # Read content for FEATURE_DESCRIPTION (preserves summarization)
  FEATURE_DESCRIPTION=$(cat "$SOURCE_FILE")

  # Remove --file flag from any remaining text
  FEATURE_DESCRIPTION=$(echo "$FEATURE_DESCRIPTION" | sed -E 's/--file[[:space:]]+[^[:space:]]+//' | xargs)
fi
```

**Implementation locations**:
- `/home/benjamin/.config/.claude/commands/plan.md:62` (after --complexity parsing)
- `/home/benjamin/.config/.claude/commands/research.md:60` (after --complexity parsing)
- `/home/benjamin/.config/.claude/commands/debug.md:45` (after --complexity parsing)
- `/home/benjamin/.config/.claude/commands/coordinate.md:97` (after WORKFLOW_DESCRIPTION validation)

**Impact**: High - enables verbatim prompt handling for all research-phase commands
**Effort**: Medium - requires modification to 4 commands
**Risk**: Low - additive feature with explicit flag

### Recommendation 2: Copy Prompt File to Specs Directory

After topic directory creation, copy the original prompt file:

```bash
# Copy original prompt file to specs directory for archival
ARCHIVED_PROMPT_PATH=""
if [ -n "$ORIGINAL_PROMPT_FILE_PATH" ] && [ -f "$ORIGINAL_PROMPT_FILE_PATH" ]; then
  ARCHIVED_PROMPT_PATH="${TOPIC_PATH}/prompt_$(basename "$ORIGINAL_PROMPT_FILE_PATH")"
  cp "$ORIGINAL_PROMPT_FILE_PATH" "$ARCHIVED_PROMPT_PATH"
  echo "Prompt file archived: $ARCHIVED_PROMPT_PATH"
fi
```

**Implementation locations**:
- After `initialize_workflow_paths()` call in each command
- Specifically after topic directory creation (plan.md:144, research.md:141, debug.md:263, coordinate.md:Part 2)

**Impact**: Medium - provides permanent archival of original specification
**Effort**: Low - simple file copy operation
**Risk**: None - additive operation

### Recommendation 3: Persist Original File Path in Workflow State

Add to existing append_workflow_state() calls:

```bash
# Add to state persistence section
append_workflow_state "ORIGINAL_PROMPT_FILE_PATH" "$ORIGINAL_PROMPT_FILE_PATH"
append_workflow_state "ARCHIVED_PROMPT_PATH" "$ARCHIVED_PROMPT_PATH"
```

**Implementation locations**:
- `/home/benjamin/.config/.claude/commands/plan.md:156` (after RESEARCH_COMPLEXITY)
- `/home/benjamin/.config/.claude/commands/research.md:149` (after RESEARCH_COMPLEXITY)
- `/home/benjamin/.config/.claude/commands/debug.md:147` (after RESEARCH_COMPLEXITY)
- `/home/benjamin/.config/.claude/commands/coordinate.md:184` (after PERF_START_TOTAL)

**Impact**: High - enables subagents to access original file
**Effort**: Low - two additional append_workflow_state calls
**Risk**: None - extends existing pattern

### Recommendation 4: Update Task Tool Prompts for Research Agents

Add original prompt file path to research-specialist context:

```markdown
**Workflow-Specific Context**:
- Research Topic: ${FEATURE_DESCRIPTION}
- Research Complexity: ${RESEARCH_COMPLEXITY}
- Output Directory: ${RESEARCH_DIR}
- Workflow Type: research-and-plan
- Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}
- Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}

**Key Requirements from User**:
If Original Prompt File is provided, read it directly for complete verbatim requirements.
The Research Topic above may be summarized; the original file contains full specifications.
```

**Implementation locations**:
- `/home/benjamin/.config/.claude/commands/plan.md:173-180` (add to Workflow-Specific Context)
- `/home/benjamin/.config/.claude/commands/research.md:166-170` (add to Workflow-Specific Context)
- `/home/benjamin/.config/.claude/commands/debug.md:292-296` (add to Workflow-Specific Context)
- `/home/benjamin/.config/.claude/commands/coordinate.md` (multiple Task invocations)

**Impact**: High - research agents gain access to verbatim specifications
**Effort**: Medium - requires updating multiple Task tool prompts
**Risk**: Low - agents can fall back to FEATURE_DESCRIPTION if file not provided

### Recommendation 5: Update Command Documentation and Help Text

Add usage examples showing --file flag:

```markdown
**Usage Examples**:

```bash
# Short description (existing pattern)
/plan "implement user authentication"

# Long specification from file
/plan --file /path/to/specification.md

# Combined with complexity
/plan --file /path/to/spec.md --complexity 4
```
```

**Implementation locations**:
- Command frontmatter argument-hint updates
- Troubleshooting sections at end of each command
- `/home/benjamin/.config/.claude/docs/reference/command-reference.md`
- `/home/benjamin/.config/.claude/docs/guides/plan-command-guide.md`
- `/home/benjamin/.config/.claude/docs/guides/research-command-guide.md`
- `/home/benjamin/.config/.claude/docs/guides/debug-command-guide.md`

**Impact**: Medium - improves discoverability
**Effort**: Low - documentation updates
**Risk**: None

### Recommendation 6: Preserve Backward Compatibility

The implementation should:

1. **Keep existing summarization**: FEATURE_DESCRIPTION continues to hold summarized content for commit messages, topic slugs, and state display
2. **File is optional**: Commands work identically without --file flag
3. **Flag order flexibility**: Support both `--file path --complexity 3` and `--complexity 3 --file path`
4. **Graceful absence**: If ORIGINAL_PROMPT_FILE_PATH is empty, agents use FEATURE_DESCRIPTION normally

**Impact**: High - prevents breaking existing workflows
**Effort**: Built into above recommendations
**Risk**: None if properly tested

## Implementation Considerations

### Phase 1: Core Implementation (2-4 hours)

1. Add --file parsing to all 4 commands
2. Add state persistence for file paths
3. Add file copy to specs directory
4. Update Task tool prompts with file path context

### Phase 2: Documentation Updates (1-2 hours)

1. Update command reference documentation
2. Update command-specific guides
3. Add examples to troubleshooting sections

### Phase 3: Testing (1-2 hours)

1. Test each command with --file flag
2. Test combination with --complexity
3. Verify subagents can read original file
4. Verify backward compatibility without flag

### Edge Cases to Handle

1. **File not found**: Clear error message with path
2. **Empty file**: Warning but proceed with empty description
3. **Binary file**: Detect and reject non-text files
4. **Large file**: No artificial limit (system limits apply)
5. **Relative path**: Convert to absolute path for portability

## References

### Primary Files Analyzed
- `/home/benjamin/.config/.claude/commands/plan.md:1-375` - Plan command implementation
- `/home/benjamin/.config/.claude/commands/research.md:1-261` - Research command implementation
- `/home/benjamin/.config/.claude/commands/debug.md:1-691` - Debug command implementation
- `/home/benjamin/.config/.claude/commands/coordinate.md:1-200` - Coordinate command (partial)
- `/home/benjamin/.config/.claude/lib/state-persistence.sh:1-499` - State persistence library
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:1-927` - Workflow initialization library

### Prior Research
- `/home/benjamin/.config/.claude/specs/791_prompt_examplemd_which_i_want_you_to_review_as/reports/001_long_prompt_handling_analysis.md:1-310` - Long prompt handling analysis

### Documentation References
- `/home/benjamin/.config/.claude/docs/reference/command-reference.md` - Command reference documentation
- `/home/benjamin/.config/.claude/docs/guides/plan-command-guide.md` - Plan command guide
- `/home/benjamin/.config/.claude/docs/guides/research-command-guide.md` - Research command guide
- `/home/benjamin/.config/.claude/docs/guides/debug-command-guide.md` - Debug command guide
