# Command Flags and CLI Operations Research Report

## Metadata
- **Date**: 2025-11-18
- **Agent**: research-specialist
- **Topic**: Command flags and CLI operations for .claude/commands/
- **Report Type**: codebase analysis

## Executive Summary

This report provides a comprehensive analysis of all flags, CLI operations, and file-passing capabilities for the 11 commands in `.claude/commands/`. The research reveals significant documentation gaps in the current README.md, with several commands supporting undocumented flags like `--file`, `--complexity`, `--dry-run`, and various operational flags for `/setup`. Key findings include 6 commands supporting the `--file` flag for long prompts, 4 commands with `--complexity` level settings, and mode-specific operations for `/expand`, `/collapse`, `/convert-docs`, and `/setup` that are not fully documented in the README.

## Findings

### 1. Command Flag Analysis by Command

#### /build
**Source**: `/home/benjamin/.config/.claude/commands/build.md` (lines 3, 26-32)
- **Documented in README**: `/build [plan-file] [starting-phase] [--dry-run]`
- **Actual Flags**:
  - `[plan-file]` - Path to plan file (optional, auto-resume if omitted)
  - `[starting-phase]` - Phase number to start from (default: 1)
  - `--dry-run` - Preview mode, no actual execution (lines 93-104, 156-163)
- **File Passing**: Accepts plan file path as first positional argument

#### /plan
**Source**: `/home/benjamin/.config/.claude/commands/plan.md` (lines 3, 26-33)
- **Documented in README**: `/plan <feature-description>`
- **Actual Flags**:
  - `<feature-description>` - Required description of feature (positional)
  - `--file <path>` - Load description from file (lines 69-91)
  - `--complexity 1-4` - Set research complexity level (lines 55-67)
- **File Passing**: Supports `--file` flag for long prompts; file is archived to topic/prompts/

#### /research
**Source**: `/home/benjamin/.config/.claude/commands/research.md` (lines 3, 26-33)
- **Documented in README**: `/research <workflow-description>`
- **Actual Flags**:
  - `<workflow-description>` - Required workflow description (positional)
  - `--file <path>` - Load description from file (lines 69-91)
  - `--complexity 1-4` - Set research complexity level (default: 2) (lines 54-67)
- **File Passing**: Supports `--file` flag; file is archived to topic/prompts/

#### /debug
**Source**: `/home/benjamin/.config/.claude/commands/debug.md` (lines 3, 27-81)
- **Documented in README**: `/debug <issue-description>`
- **Actual Flags**:
  - `<issue-description>` - Required issue description (positional)
  - `--file <path>` - Load description from file (lines 53-75)
  - `--complexity 1-4` - Set research complexity level (default: 2) (lines 39-51)
- **File Passing**: Supports `--file` flag; file is archived to topic/prompts/

#### /revise
**Source**: `/home/benjamin/.config/.claude/commands/revise.md` (lines 3, 26-48)
- **Documented in README**: `/revise <revision-description-with-plan-path>`
- **Actual Flags**:
  - `<revision-description-with-plan-path>` - Description containing plan path (positional)
  - `--complexity 1-4` - Set research complexity level (default: 2) (lines 82-96)
- **Note**: Does NOT support `--file` flag (unlike /plan, /research, /debug)

#### /coordinate
**Source**: `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 3, 19-43)
- **Documented in README**: `/coordinate <workflow-description>`
- **Actual Flags**:
  - `<workflow-description>` - Required workflow description (positional)
- **Note**: No additional flags; relies on workflow-classifier agent for complexity

#### /setup
**Source**: `/home/benjamin/.config/.claude/commands/setup.md` (lines 3, 19-61)
- **Documented in README**: `/setup [project-directory] [--cleanup [--dry-run]] [--validate] [--analyze] [--apply-report <report-path>] [--enhance-with-docs]`
- **Actual Flags** (lines 29-43):
  - `[project-directory]` - Target directory (default: current directory)
  - `--cleanup` - Section extraction and optimization mode
  - `--dry-run` - Preview cleanup changes (requires `--cleanup`)
  - `--validate` - Structure verification mode
  - `--analyze` - Discrepancy detection mode
  - `--apply-report <report-path>` - Apply report-driven updates
  - `--enhance-with-docs` - Documentation enhancement mode
  - `--threshold [aggressive|balanced|conservative]` - Cleanup threshold (line 39)
- **Mode Priority**: apply-report > enhance > cleanup > validate > analyze > standard (line 28)

#### /expand
**Source**: `/home/benjamin/.config/.claude/commands/expand.md` (lines 3, 35-49)
- **Documented in README**: `/expand <path>` OR `/expand [phase|stage] <path> <number>`
- **Actual Flags**:
  - Auto-analysis mode: `<path>` - Plan path for automatic complexity analysis
  - Explicit mode: `[phase|stage] <path> <number>` - Expand specific phase/stage
  - `--auto-mode` - Non-interactive JSON output for agent coordination (lines 526-578, 966-1078)
- **Examples** (lines 934-961):
  - `/expand specs/plans/025_feature.md` (auto-analysis)
  - `/expand phase specs/plans/025_feature.md 3` (explicit)
  - `/expand stage specs/plans/025_feature/phase_2_impl.md 1` (stage expansion)

#### /collapse
**Source**: `/home/benjamin/.config/.claude/commands/collapse.md` (lines 3, 36-49)
- **Documented in README**: `/collapse <path>` OR `/collapse [phase|stage] <path> <number>`
- **Actual Flags**:
  - Auto-analysis mode: `<path>` - Plan path for automatic simplification analysis
  - Explicit mode: `[phase|stage] <path> <number>` - Collapse specific phase/stage
- **Examples** (lines 649-679):
  - `/collapse specs/plans/025_feature/` (auto-analysis)
  - `/collapse phase specs/plans/025_feature/ 2` (explicit)
  - `/collapse stage specs/plans/025_feature/phase_2_impl/ 1` (stage collapse)

#### /convert-docs
**Source**: `/home/benjamin/.config/.claude/commands/convert-docs.md` (lines 3-5, 36-49)
- **Documented in README**: `/convert-docs <input-directory> [output-directory] [--use-agent]`
- **Actual Flags**:
  - `<input-directory>` - Required source directory
  - `[output-directory]` - Output directory (default: `./converted_output`)
  - `--use-agent` - Force agent mode for orchestrated conversion
- **Mode Detection** (lines 205-214):
  - Agent mode triggers: `--use-agent` flag OR keywords like "detailed logging", "quality reporting", "verify tools", "orchestrated workflow"
- **Examples** (lines 76-100):
  - `/convert-docs ~/Documents/Reports` (script mode)
  - `/convert-docs ./documents ./output --use-agent` (agent mode)
  - `/convert-docs ./files ./output with detailed logging` (keyword trigger)

#### /optimize-claude
**Source**: `/home/benjamin/.config/.claude/commands/optimize-claude.md` (lines 1-18)
- **Documented in README**: `/optimize-claude`
- **Actual Flags**: None
- **Note**: Simple invocation with no arguments (line 8); uses hardcoded balanced threshold

### 2. File Passing Patterns

#### Commands Supporting `--file` Flag
Commands that support loading descriptions from files (for long prompts):

1. **`/plan`** - `--file <path>` (lines 69-91)
2. **`/research`** - `--file <path>` (lines 69-91)
3. **`/debug`** - `--file <path>` (lines 53-75)

**Behavior Pattern**:
- Relative paths converted to absolute
- File content replaces positional argument
- Original file archived to `${TOPIC_PATH}/prompts/$(basename file)`
- Empty file warning issued

#### Commands NOT Supporting `--file`
- `/revise` - Requires plan path in description (not separate file)
- `/build` - Uses plan file path directly
- `/coordinate` - Uses workflow description directly
- `/setup`, `/expand`, `/collapse`, `/convert-docs`, `/optimize-claude`

### 3. Complexity Levels

#### Commands Supporting `--complexity` Flag

| Command | Default | Range | Source Line |
|---------|---------|-------|-------------|
| `/plan` | 3 | 1-4 | lines 55-67 |
| `/research` | 2 | 1-4 | lines 54-67 |
| `/debug` | 2 | 1-4 | lines 39-51 |
| `/revise` | 2 | 1-4 | lines 82-96 |

**Complexity Interpretation**:
- 1: Minimal research
- 2: Standard research (default for most)
- 3: Comprehensive research (default for /plan)
- 4: Deep investigation

### 4. Execution Modes

#### Commands with Multiple Modes

**`/expand` and `/collapse`**:
- Auto-analysis mode: Single path argument
- Explicit mode: Three arguments (type, path, number)
- JSON output mode: `--auto-mode` flag

**`/convert-docs`**:
- Script mode: Default, fast execution
- Agent mode: `--use-agent` flag or keyword triggers

**`/setup`**:
- Standard mode: Default CLAUDE.md generation
- Cleanup mode: `--cleanup`
- Validate mode: `--validate`
- Analyze mode: `--analyze`
- Apply-report mode: `--apply-report <path>`
- Enhance mode: `--enhance-with-docs`

### 5. README Documentation Gaps

The current README.md is missing or incomplete on:

1. **`--file` flag** for `/plan`, `/research`, `/debug` (not documented)
2. **`--complexity` flag** for all four research-based commands (not documented)
3. **`--auto-mode` flag** for `/expand` (not documented)
4. **`--threshold` flag** for `/setup` cleanup (not documented)
5. **Mode triggers** for `/convert-docs` keyword detection (partially documented)
6. **File archival behavior** for `--file` flag (not documented)

### 6. Argument Parsing Patterns

All commands use similar bash argument parsing:

```bash
# Flag extraction pattern (from plan.md, lines 55-67)
if [[ "$DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  COMPLEXITY="${BASH_REMATCH[1]}"
  DESCRIPTION=$(echo "$DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi

# File flag pattern (from plan.md, lines 69-91)
if [[ "$DESCRIPTION" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
  FILE_PATH="${BASH_REMATCH[1]}"
  # ... validation and loading
fi
```

## Recommendations

### 1. Update README Usage Sections
Update each command's usage section to include all supported flags:

**`/build`**:
```
/build [plan-file] [starting-phase] [--dry-run]
```

**`/plan`**:
```
/plan <feature-description> [--file <path>] [--complexity 1-4]
```

**`/research`**:
```
/research <workflow-description> [--file <path>] [--complexity 1-4]
```

**`/debug`**:
```
/debug <issue-description> [--file <path>] [--complexity 1-4]
```

**`/setup`**:
```
/setup [project-directory] [--cleanup [--dry-run] [--threshold aggressive|balanced|conservative]] [--validate] [--analyze] [--apply-report <report-path>] [--enhance-with-docs]
```

**`/expand`**:
```
/expand <path> [--auto-mode]
/expand [phase|stage] <path> <number> [--auto-mode]
```

### 2. Add Flag Reference Section
Add a dedicated "Common Flags" section to README explaining:
- `--file <path>`: Load description from file (supported by /plan, /research, /debug)
- `--complexity 1-4`: Set research depth (default varies by command)
- `--dry-run`: Preview mode (supported by /build, /setup --cleanup)
- `--auto-mode`: Non-interactive JSON output (/expand, /collapse)

### 3. Document File Passing Behavior
Add explanation of file archival: "When using `--file`, the original file is moved to `{topic}/prompts/` for traceability."

### 4. Add Mode Detection Documentation
For `/convert-docs`, document all trigger keywords: "detailed logging", "quality reporting", "verify tools", "orchestrated workflow"

### 5. Update Examples Section
Add examples showing flag combinations:
```bash
# Long prompt from file with high complexity
/plan --file /path/to/requirements.md --complexity 4

# Debug with external issue description
/debug --file /tmp/error-log.md --complexity 3

# Setup with aggressive cleanup preview
/setup --cleanup --threshold aggressive --dry-run
```

## Implementation Status
- **Status**: Planning In Progress
- **Plan**: [../plans/001_claude_commands_readmemd_accordingly_all_plan.md](../plans/001_claude_commands_readmemd_accordingly_all_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-18

## References

- `/home/benjamin/.config/.claude/commands/build.md` (lines 3, 26-32, 93-104, 156-163)
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 3, 26-33, 55-91)
- `/home/benjamin/.config/.claude/commands/research.md` (lines 3, 26-33, 54-91)
- `/home/benjamin/.config/.claude/commands/debug.md` (lines 3, 27-81, 39-75)
- `/home/benjamin/.config/.claude/commands/revise.md` (lines 3, 26-48, 82-96)
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 3, 19-43)
- `/home/benjamin/.config/.claude/commands/setup.md` (lines 3, 19-61, 28-43)
- `/home/benjamin/.config/.claude/commands/expand.md` (lines 3, 35-49, 526-578, 934-961, 966-1078)
- `/home/benjamin/.config/.claude/commands/collapse.md` (lines 3, 36-49, 649-679)
- `/home/benjamin/.config/.claude/commands/convert-docs.md` (lines 3-5, 36-49, 76-100, 205-214)
- `/home/benjamin/.config/.claude/commands/optimize-claude.md` (lines 1-18)
- `/home/benjamin/.config/.claude/commands/README.md` (entire file, for comparison)
