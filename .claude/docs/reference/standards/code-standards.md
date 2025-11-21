## Code Standards
[Used by: /implement, /refactor, /plan]

### General Principles
- **Indentation**: 2 spaces, expandtab
- **Line length**: ~100 characters (soft limit)
- **Naming**: snake_case for variables/functions, PascalCase for module tables
- **Error Handling**: Use defensive programming patterns with structured error messages (WHICH/WHAT/WHERE) and integrate centralized error logging - See [Defensive Programming Patterns](.claude/docs/concepts/patterns/defensive-programming.md), [Error Handling Pattern](.claude/docs/concepts/patterns/error-handling.md), and [Error Enhancement Guide](.claude/docs/guides/patterns/error-enhancement-guide.md)
- **Documentation**: Every directory must have a README.md
- **Character Encoding**: UTF-8 only, no emojis in file content

### Language-Specific Standards
- **Lua**: See [Neovim Configuration Guidelines](nvim/CLAUDE.md) for detailed Lua standards
- **Markdown**: Use Unicode box-drawing for diagrams, follow CommonMark spec
- **Shell Scripts**: Follow ShellCheck recommendations, use bash -e for error handling

### Command and Agent Architecture Standards
[Used by: All slash commands and agent development]

- **Command files** (`.claude/commands/*.md`) are AI execution scripts, not traditional code
- **Executable instructions** must be inline, not replaced by external references
- **Templates** must be complete and copy-paste ready (agent prompts, JSON schemas, bash commands)
- **Critical warnings** (CRITICAL, IMPORTANT, NEVER) must stay in command files
- **Reference files** (`shared/`, `templates/`, `docs/`) provide supplemental context only
- **Imperative Language**: All required actions use MUST/WILL/SHALL (never should/may/can) - See [Imperative Language Guide](.claude/docs/archive/guides/patterns/execution-enforcement/execution-enforcement-overview.md)
- **Behavioral Injection**: Commands invoke agents via Task tool with context injection (not SlashCommand) - See [Behavioral Injection Pattern](.claude/docs/concepts/patterns/behavioral-injection.md)
- **Verification and Fallback**: All file creation operations require MANDATORY VERIFICATION checkpoints - See [Verification and Fallback Pattern](.claude/docs/concepts/patterns/verification-fallback.md)
- **Robustness Patterns**: Apply systematic robustness patterns for reliable command development - See [Robustness Framework](.claude/docs/concepts/robustness-framework.md)
- See [Command Architecture Standards](../architecture/overview.md) for complete guidelines

### Output Suppression Patterns
[Used by: All commands and agents]

Commands MUST suppress verbose output to maintain clean Claude Code display:

**Library Sourcing**: Suppress output while preserving error handling
```bash
source "${LIB_DIR}/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
```

**Directory Operations**: Suppress non-critical operations
```bash
mkdir -p "$OUTPUT_DIR" 2>/dev/null || true
```

**Single Summary Line**: One output per block instead of multiple progress messages
```bash
# After all operations complete
echo "Setup complete: $WORKFLOW_ID"
```

**WHAT not WHY Comments**: Comments describe what code does, not why it was designed that way
```bash
# Load state management functions (correct - WHAT)
source lib.sh

# We source here because subprocess isolation requires... (incorrect - WHY)
```

See [Output Formatting Standards](output-formatting.md) for comprehensive patterns and [Bash Block Execution Model](.claude/docs/concepts/bash-block-execution-model.md#pattern-8-block-count-minimization) for block consolidation.

### Directory Creation Anti-Patterns
[Used by: All commands and agents]

Commands MUST NOT create artifact subdirectories eagerly during setup. Use the lazy directory creation pattern where directories are created only when files are written.

**NEVER: Eager Subdirectory Creation**

This anti-pattern creates empty directories that persist when workflows fail or are interrupted:

```bash
# WRONG: Eager directory creation in command setup
initialize_workflow_paths "$TOPIC_NAME" || exit 1

RESEARCH_DIR="${TOPIC_PATH}/reports"
DEBUG_DIR="${TOPIC_PATH}/debug"
PLANS_DIR="${TOPIC_PATH}/plans"

# Creates directories immediately (VIOLATES lazy creation standard)
mkdir -p "$RESEARCH_DIR"
mkdir -p "$DEBUG_DIR"
mkdir -p "$PLANS_DIR"

# If workflow fails before agent writes files, empty directories persist
```

**Impact**: Each failed workflow creates 1-3 empty subdirectories. Over 400-500+ empty directories accumulated before this pattern was remediated (Spec 869 root cause analysis). Empty directories create false signals during debugging and violate the lazy creation standard documented in [Directory Protocols](../../concepts/directory-protocols.md).

**ALWAYS: Lazy Directory Creation in Agents**

Agents create parent directories on-demand when writing files using `ensure_artifact_directory()`:

```bash
# CORRECT: Command setup (path assignment only, no mkdir)
initialize_workflow_paths "$TOPIC_NAME" || exit 1

RESEARCH_DIR="${TOPIC_PATH}/reports"
DEBUG_DIR="${TOPIC_PATH}/debug"
PLANS_DIR="${TOPIC_PATH}/plans"

# No mkdir here - agents handle lazy creation

# In agent behavioral guidelines (e.g., research-specialist.md)
source .claude/lib/core/unified-location-detection.sh

REPORT_PATH="${RESEARCH_DIR}/001_report.md"

# Ensure parent directory exists (lazy creation pattern)
ensure_artifact_directory "$REPORT_PATH" || {
  echo "ERROR: Failed to create parent directory for report" >&2
  exit 1
}

# Write tool creates file (parent directory guaranteed to exist)
# Directory created ONLY when file is written
```

**Benefits**: No empty directories when workflows fail, consistent with lazy creation standard, simpler command code, agents have full control over directory lifecycle.

**Exception: Atomic Directory+File Creation**

When directory creation is immediately followed by file creation in the same bash block, eager creation is acceptable:

```bash
# ACCEPTABLE: Atomic directory+file creation (revise.md example)
BACKUP_DIR="${TOPIC_PATH}/backups"
mkdir -p "$BACKUP_DIR"
cp "$PLAN_PATH" "${BACKUP_DIR}/$(basename "$PLAN_PATH").backup_$(date +%s)"
# File written immediately after mkdir - no empty directory risk
```

**Audit Checklist**:
- Commands MUST NOT use `mkdir -p $RESEARCH_DIR`, `$DEBUG_DIR`, `$PLANS_DIR`, or `$SUMMARIES_DIR`
- Agents MUST call `ensure_artifact_directory()` before writing artifact files
- Only exception: Atomic directory+file creation where file write follows immediately in same bash block
- Verify with: `grep 'mkdir -p "\$.*_DIR"' .claude/commands/*.md` (should only match atomic patterns)

**See Also**:
- [Directory Protocols - Lazy Directory Creation](../../concepts/directory-protocols.md#lazy-directory-creation)
- [Unified Location Detection API](../../concepts/directory-protocols.md#unified-location-detection-library) - `ensure_artifact_directory()` function documentation
- [Error Case Study: Spec 869](../../troubleshooting/common-issues.md) - Empty debug/ directory root cause analysis

### Architectural Separation

**Executable/Documentation Separation Pattern**: Commands and agents separate lean executable logic from comprehensive documentation to eliminate meta-confusion loops and enable independent evolution.

**Pattern**:
- **Executable Files** (`.claude/commands/*.md`, `.claude/agents/*.md`): Lean execution scripts (<250 lines for commands, <400 lines for agents) containing bash blocks, phase markers, and minimal inline comments (WHAT not WHY)
- **Guide Files** (`.claude/docs/guides/*-command-guide.md`): Comprehensive task-focused documentation (unlimited length) with architecture, examples, troubleshooting, and design decisions

**Templates**:
- New Command: Start with [_template-executable-command.md](.claude/docs/guides/templates/_template-executable-command.md)
- Command Guide: Use [_template-command-guide.md](.claude/docs/guides/templates/_template-command-guide.md)

**Complete Pattern Documentation**:
- [Executable/Documentation Separation Pattern](.claude/docs/concepts/patterns/executable-documentation-separation.md) - Complete pattern with case studies and metrics
- [Command Development Guide - Section 2.4](.claude/docs/guides/development/command-development/command-development-fundamentals.md#24-executabledocumentation-separation-pattern) - Practical implementation instructions
- [Standard 14](../architecture/overview.md#standard-14-executabledocumentation-file-separation) - Formal architectural requirement

**Benefits**: 70% average reduction in executable file size, zero meta-confusion incidents, independent documentation growth, fail-fast execution

### Development Guides
- [Command Development Guide](.claude/docs/guides/development/command-development/command-development-fundamentals.md) - Complete guide to creating and maintaining slash commands
- [Agent Development Guide](.claude/docs/guides/development/agent-development/agent-development-fundamentals.md) - Complete guide to creating and maintaining specialized agents
- [Model Selection Guide](.claude/docs/guides/development/model-selection-guide.md) - Guide to choosing Claude model tiers (Haiku/Sonnet/Opus) for agents with cost/quality optimization

### Internal Link Conventions
[Used by: /document, /plan, /implement, all documentation]

**Standard**: All internal markdown links must use relative paths from the current file location.

**Format**:
- Same directory: `[File](file.md)`
- Parent directory: `[File](../file.md)`
- Subdirectory: `[File](subdir/file.md)`
- With anchor: `[Section](file.md#section-name)`

**Prohibited**:
- Absolute filesystem paths: `/home/user/.config/file.md`
- Repository-relative without base: `.claude/docs/file.md` (from outside .claude/)

**Validation**:
- Run `.claude/scripts/validate-links-quick.sh` before committing
- Full validation: `.claude/scripts/validate-links.sh`

**Template Placeholders** (Allowed):
- `{variable}` - Template variable
- `NNN_topic` - Placeholder pattern
- `$ENV_VAR` - Environment variable

**Historical Documentation** (Preserve as-is):
- Spec reports, summaries, and completed plans may have broken links documenting historical states
- Only fix if link prevents understanding current system

See the Link Conventions section above for complete standards.
