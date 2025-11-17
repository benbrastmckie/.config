## Code Standards
[Used by: /implement, /refactor, /plan]

### General Principles
- **Indentation**: 2 spaces, expandtab
- **Line length**: ~100 characters (soft limit)
- **Naming**: snake_case for variables/functions, PascalCase for module tables
- **Error Handling**: Use defensive programming patterns with structured error messages (WHICH/WHAT/WHERE) - See [Defensive Programming Patterns](.claude/docs/concepts/patterns/defensive-programming.md) and [Error Enhancement Guide](.claude/docs/guides/error-enhancement-guide.md)
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
- **Imperative Language**: All required actions use MUST/WILL/SHALL (never should/may/can) - See [Imperative Language Guide](.claude/docs/guides/imperative-language-guide.md)
- **Behavioral Injection**: Commands invoke agents via Task tool with context injection (not SlashCommand) - See [Behavioral Injection Pattern](.claude/docs/concepts/patterns/behavioral-injection.md)
- **Verification and Fallback**: All file creation operations require MANDATORY VERIFICATION checkpoints - See [Verification and Fallback Pattern](.claude/docs/concepts/patterns/verification-fallback.md)
- **Robustness Patterns**: Apply systematic robustness patterns for reliable command development - See [Robustness Framework](.claude/docs/concepts/robustness-framework.md)
- See [Command Architecture Standards](.claude/docs/reference/command_architecture_standards.md) for complete guidelines

### Architectural Separation

**Executable/Documentation Separation Pattern**: Commands and agents separate lean executable logic from comprehensive documentation to eliminate meta-confusion loops and enable independent evolution.

**Pattern**:
- **Executable Files** (`.claude/commands/*.md`, `.claude/agents/*.md`): Lean execution scripts (<250 lines for commands, <400 lines for agents) containing bash blocks, phase markers, and minimal inline comments (WHAT not WHY)
- **Guide Files** (`.claude/docs/guides/*-command-guide.md`): Comprehensive task-focused documentation (unlimited length) with architecture, examples, troubleshooting, and design decisions

**Templates**:
- New Command: Start with [_template-executable-command.md](.claude/docs/guides/_template-executable-command.md)
- Command Guide: Use [_template-command-guide.md](.claude/docs/guides/_template-command-guide.md)

**Complete Pattern Documentation**:
- [Executable/Documentation Separation Pattern](.claude/docs/concepts/patterns/executable-documentation-separation.md) - Complete pattern with case studies and metrics
- [Command Development Guide - Section 2.4](.claude/docs/guides/command-development-guide.md#24-executabledocumentation-separation-pattern) - Practical implementation instructions
- [Standard 14](.claude/docs/reference/command_architecture_standards.md#standard-14-executabledocumentation-file-separation) - Formal architectural requirement

**Benefits**: 70% average reduction in executable file size, zero meta-confusion incidents, independent documentation growth, fail-fast execution

### Development Guides
- [Command Development Guide](.claude/docs/guides/command-development-guide.md) - Complete guide to creating and maintaining slash commands
- [Agent Development Guide](.claude/docs/guides/agent-development-guide.md) - Complete guide to creating and maintaining specialized agents
- [Model Selection Guide](.claude/docs/guides/model-selection-guide.md) - Guide to choosing Claude model tiers (Haiku/Sonnet/Opus) for agents with cost/quality optimization

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

See [Link Conventions Guide](.claude/docs/guides/link-conventions-guide.md) for complete standards.
