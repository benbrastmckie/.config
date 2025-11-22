# Topic Naming Feature Analysis Research Report

## Metadata
- **Date**: 2025-11-21
- **Agent**: research-specialist
- **Topic**: Semantic Topic Directory Naming Feature Usage Across Commands
- **Report Type**: codebase analysis
- **Research Complexity**: 2

## Executive Summary

This research analyzes which commands in the `.claude/commands/` directory use the LLM-based topic naming feature for creating semantic directory names. The analysis reveals that **4 out of 13 commands** currently use topic naming, with varying implementation approaches. The study provides recommendations for each command regarding whether they should adopt or avoid this feature.

### Key Findings
- **Commands using topic naming**: `/research`, `/plan`, `/debug`, `/optimize-claude`
- **Commands creating directories but NOT using topic naming**: `/errors`, `/build`, `/revise`
- **Commands not creating persistent directories**: `/expand`, `/collapse`, `/convert-docs`, `/setup`
- **Topic naming mechanism**: Invokes topic-naming-agent via Task tool, validates format (^[a-z0-9_]{5,40}$), falls back to "no_name" on failure

## Findings

### 1. Topic Naming Mechanism Architecture

The topic naming system works through a well-defined pipeline:

```
User Command Input
       |
       v
Invoke topic-naming-agent (Haiku LLM)
       |
       v
Semantic analysis of user prompt
       |
       v
Generate snake_case topic name (5-40 chars)
       |
       v
Validate format: ^[a-z0-9_]{5,40}$
       |
       v
Success? -> Use LLM name
Failure? -> Fall back to "no_name" + log error
       |
       v
allocate_and_create_topic() -> NNN_topic_name/
```

**Key Libraries**:
- `/home/benjamin/.config/.claude/lib/plan/topic-utils.sh` - Topic directory utilities
- `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` - initialize_workflow_paths() function
- `/home/benjamin/.config/.claude/agents/topic-naming-agent.md` - Agent behavioral guidelines

### 2. Commands Currently Using Topic Naming

#### 2.1 /research Command
**File**: `/home/benjamin/.config/.claude/commands/research.md`

**Implementation**: Invokes topic-naming-agent directly via Task tool in a dedicated bash block.

**Evidence**: Block 1b includes:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  prompt: "Read and follow ALL behavioral guidelines from:
          ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-naming-agent.md..."
}
```

**Appropriateness**: APPROPRIATE - Creates persistent research reports that benefit from semantic naming for discoverability.

---

#### 2.2 /plan Command
**File**: `/home/benjamin/.config/.claude/commands/plan.md`

**Implementation**: Uses initialize_workflow_paths() which invokes topic naming internally via the workflow-initialization library.

**Evidence**: Sources workflow-initialization.sh and calls initialize_workflow_paths() which handles topic naming through validate_topic_directory_slug().

**Appropriateness**: APPROPRIATE - Creates implementation plans stored in topic directories. Semantic naming significantly improves plan discoverability.

---

#### 2.3 /debug Command
**File**: `/home/benjamin/.config/.claude/commands/debug.md`

**Implementation**: Uses initialize_workflow_paths() similar to /plan.

**Evidence**: Calls initialize_workflow_paths() with debug-only workflow type.

**Appropriateness**: APPROPRIATE - Creates debug analysis reports that benefit from semantic naming like "jwt_auth_null_pointer_debug".

---

#### 2.4 /optimize-claude Command
**File**: `/home/benjamin/.config/.claude/commands/optimize-claude.md`

**Implementation**: Explicitly invokes topic-naming-agent in Block 1b with full behavioral guidelines.

**Evidence**: Lines 199-222 show explicit Task invocation:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  prompt: "Read and follow ALL behavioral guidelines from:
          ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-naming-agent.md..."
}
```

**Appropriateness**: APPROPRIATE - Creates optimization plans and analysis reports that benefit from semantic naming.

### 3. Commands Creating Directories WITHOUT Topic Naming

#### 3.1 /errors Command
**File**: `/home/benjamin/.config/.claude/commands/errors.md`

**Current Behavior**: Uses initialize_workflow_paths() but passes a simple error description string, resulting in sanitized slugs rather than LLM-generated names.

**Evidence**: Line 271:
```bash
initialize_workflow_paths "$ERROR_DESCRIPTION" "research-only" "2" ""
```
The fourth parameter (classification result) is empty, triggering fallback to basic sanitization.

**Creates**: Topic directories like `NNN_build_error_analysis/` or `NNN_state_error_analysis/` based on filter parameters.

**Recommendation**: SHOULD NOT add topic naming - Error reports are filtered by type/command, not searched by semantic name. The current slug generation from ERROR_DESCRIPTION is sufficient.

---

#### 3.2 /build Command
**File**: `/home/benjamin/.config/.claude/commands/build.md`

**Current Behavior**: Operates on EXISTING plan paths, does not create new topic directories.

**Evidence**: Accepts plan file path as argument and operates within existing topic structure.

**Recommendation**: SHOULD NOT add topic naming - /build executes existing plans, it doesn't create new topic directories. It reuses the topic directory from the plan path.

---

#### 3.3 /revise Command
**File**: `/home/benjamin/.config/.claude/commands/revise.md`

**Current Behavior**: Uses "research-and-revise" workflow scope which REUSES existing topic directories from the plan being revised.

**Evidence**: workflow-initialization.sh lines 516-559 show research-and-revise handling:
```bash
if [ "${workflow_scope:-}" = "research-and-revise" ]; then
  # research-and-revise: Reuse existing plan's topic directory
  topic_path=$(dirname $(dirname "$EXISTING_PLAN_PATH"))
```

**Recommendation**: SHOULD NOT add topic naming - /revise operates on existing plans within their existing topic directories. Creating new topic names would break the relationship between original and revised plans.

### 4. Commands NOT Creating Persistent Directories

#### 4.1 /expand Command
**File**: `/home/benjamin/.config/.claude/commands/expand.md`

**Current Behavior**: Expands phases/stages WITHIN existing plan directories, does not create new topic directories.

**Creates**: Phase files like `phase_2_impl.md` within existing plan directories.

**Recommendation**: SHOULD NOT add topic naming - Works within existing topic structure, file naming is deterministic based on phase numbers.

---

#### 4.2 /collapse Command
**File**: `/home/benjamin/.config/.claude/commands/collapse.md`

**Current Behavior**: Collapses expanded phases/stages back into parent files, does not create directories.

**Recommendation**: SHOULD NOT add topic naming - Inverse of /expand, only modifies existing files.

---

#### 4.3 /convert-docs Command
**File**: `/home/benjamin/.config/.claude/commands/convert-docs.md`

**Current Behavior**: Creates output directories at user-specified paths, not within specs/ structure.

**Creates**: User-specified output directory (default: `./converted_output/`)

**Recommendation**: SHOULD NOT add topic naming - Output directory is user-controlled, not part of specs/ topic system. Users specify exact output paths.

---

#### 4.4 /setup Command
**File**: `/home/benjamin/.config/.claude/commands/setup.md`

**Current Behavior**: Creates CLAUDE.md files and analysis reports at fixed locations.

**Evidence**: Analysis mode calls initialize_workflow_paths() with "research" type:
```bash
initialize_workflow_paths "CLAUDE.md standards analysis" "research" "2" ""
```

**Recommendation**: MIXED - The analysis mode could benefit from topic naming for reports, but the current implementation uses initialize_workflow_paths() which provides fallback sanitization. Consider adding explicit topic naming for the analysis reports.

### 5. Commands Not Analyzed (Not in commands/ directory)

- `/repair` - Uses workflow-initialization.sh similar to /plan
- Other utility scripts in scripts/ directory

## Recommendations

### Summary Table

| Command | Creates Topic Dir? | Uses Topic Naming? | Recommendation |
|---------|-------------------|-------------------|----------------|
| /research | Yes | Yes | Keep current implementation |
| /plan | Yes | Yes | Keep current implementation |
| /debug | Yes | Yes | Keep current implementation |
| /optimize-claude | Yes | Yes | Keep current implementation |
| /errors | Yes | No (sanitization) | **No change needed** - filter-based discovery sufficient |
| /build | No (reuses) | N/A | **No change needed** - operates on existing plans |
| /revise | No (reuses) | N/A | **No change needed** - must preserve topic relationship |
| /expand | No (modifies) | N/A | **No change needed** - deterministic file naming |
| /collapse | No (modifies) | N/A | **No change needed** - inverse operation |
| /convert-docs | Yes (user path) | N/A | **No change needed** - user-controlled paths |
| /setup | Yes (analysis) | Partial | **Consider adding** - would improve report discoverability |

### Detailed Recommendations

#### 1. Commands That SHOULD Use Topic Naming (Currently Do)
- **`/research`**: Keep - Semantic names crucial for finding research reports
- **`/plan`**: Keep - Plans benefit from descriptive names like `jwt_auth_implementation`
- **`/debug`**: Keep - Debug reports need semantic context
- **`/optimize-claude`**: Keep - Optimization workflows need semantic identification

#### 2. Commands That SHOULD NOT Add Topic Naming

**`/errors`** - Keep current implementation
- **Reason**: Error reports are discovered via filters (`--command`, `--type`, `--since`), not by browsing directory names
- **Current approach**: Slug generation from ERROR_DESCRIPTION is sufficient
- **Risk of change**: Adding LLM naming would add latency (~3s) with minimal discoverability benefit

**`/build`** - No change needed
- **Reason**: Operates on existing plans, doesn't create topic directories
- **Architecture**: Receives plan path as input, works within existing structure

**`/revise`** - No change needed
- **Reason**: MUST preserve relationship with original plan by staying in same topic directory
- **Architecture**: research-and-revise scope explicitly reuses EXISTING_PLAN_PATH's topic

**`/expand`** and **`/collapse`** - No change needed
- **Reason**: Modify existing files within existing directories
- **Architecture**: Phase/stage naming is deterministic (phase_N_name.md)

**`/convert-docs`** - No change needed
- **Reason**: Output path is user-specified, not part of specs/ system
- **Architecture**: Operates outside topic directory structure

#### 3. Commands That COULD Benefit From Topic Naming

**`/setup` (analysis mode)** - Consider adding
- **Benefit**: Analysis reports would have semantic names instead of generic "001_standards_analysis.md"
- **Cost**: +3s latency per invocation
- **Recommendation**: Low priority - current implementation sufficient, but could improve discoverability of analysis reports

### Implementation Pattern for Adding Topic Naming

For commands that should add topic naming, follow this pattern from /research:

```bash
# Block 1b: Topic Name Generation
Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-naming-agent.md

    You are generating a topic directory name for: /command-name

    **Input**:
    - User Prompt: ${USER_DESCRIPTION}
    - Command Name: /command-name
    - OUTPUT_FILE_PATH: ${HOME}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt

    Execute topic naming according to behavioral guidelines.
    Return: TOPIC_NAME_GENERATED: <generated_name>
  "
}

# Block 1c: Parse and validate
TOPIC_NAME_FILE="${HOME}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt"
TOPIC_NAME=$(cat "$TOPIC_NAME_FILE" 2>/dev/null | tr -d '\n')

# Validate format
if ! echo "$TOPIC_NAME" | grep -Eq '^[a-z0-9_]{5,40}$'; then
  TOPIC_NAME="no_name"
fi
```

## References

### File Paths Analyzed

| File | Lines Relevant |
|------|---------------|
| `/home/benjamin/.config/.claude/commands/research.md` | Block 1b (topic naming agent invocation) |
| `/home/benjamin/.config/.claude/commands/plan.md` | initialize_workflow_paths() call |
| `/home/benjamin/.config/.claude/commands/debug.md` | initialize_workflow_paths() call |
| `/home/benjamin/.config/.claude/commands/repair.md` | initialize_workflow_paths() call |
| `/home/benjamin/.config/.claude/commands/optimize-claude.md` | Lines 199-222 (topic naming) |
| `/home/benjamin/.config/.claude/commands/errors.md` | Line 271 (initialize_workflow_paths) |
| `/home/benjamin/.config/.claude/commands/build.md` | Plan path reuse logic |
| `/home/benjamin/.config/.claude/commands/revise.md` | research-and-revise scope |
| `/home/benjamin/.config/.claude/commands/expand.md` | Phase file creation |
| `/home/benjamin/.config/.claude/commands/collapse.md` | Phase file modification |
| `/home/benjamin/.config/.claude/commands/convert-docs.md` | User-specified output paths |
| `/home/benjamin/.config/.claude/commands/setup.md` | initialize_workflow_paths() for analysis |
| `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` | Lines 388-819 (initialize_workflow_paths) |
| `/home/benjamin/.config/.claude/lib/plan/topic-utils.sh` | Topic directory utilities |
| `/home/benjamin/.config/.claude/agents/topic-naming-agent.md` | Agent behavioral guidelines |
| `/home/benjamin/.config/.claude/docs/guides/development/topic-naming-with-llm.md` | Feature documentation |

### Key Functions

- `initialize_workflow_paths()` - Main entry point for workflow path initialization (workflow-initialization.sh:388)
- `validate_topic_directory_slug()` - Two-tier validation for topic slugs (workflow-initialization.sh:296)
- `allocate_and_create_topic()` - Atomic topic number allocation (topic-utils.sh)
- `get_or_create_topic_number()` - Idempotent topic number retrieval (topic-utils.sh)
