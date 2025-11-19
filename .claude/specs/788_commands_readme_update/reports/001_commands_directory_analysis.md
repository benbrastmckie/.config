# Commands Directory Structure and Content Research Report

## Metadata
- **Date**: 2025-11-18
- **Agent**: research-specialist
- **Topic**: Commands Directory Structure and Content Analysis
- **Report Type**: codebase analysis

## Executive Summary

The `.claude/commands/` directory contains 12 active command files implementing a sophisticated state-machine-based workflow system. Commands follow a standardized frontmatter format with metadata fields including `allowed-tools`, `argument-hint`, `description`, `command-type`, `dependent-agents`, and `library-requirements`. The commands are categorized into primary orchestrators (/plan, /build, /research, /debug, /coordinate, /revise, /setup), workflow managers (/expand, /collapse), and utilities (/convert-docs, /optimize-claude), with existing documentation in the README.md requiring updates to accurately reflect current command catalog and architecture.

## Findings

### 1. Command File Inventory

**Active Command Files** (12 files in `/home/benjamin/.config/.claude/commands/`):
- `build.md` - Build-from-plan workflow
- `collapse.md` - Phase/stage collapse operations
- `convert-docs.md` - Document format conversion
- `coordinate.md` - Multi-agent workflow orchestration
- `debug.md` - Debug-focused workflow
- `expand.md` - Phase/stage expansion operations
- `optimize-claude.md` - CLAUDE.md optimization
- `plan.md` - Research and create implementation plans
- `research.md` - Research-only workflow
- `revise.md` - Research and revise existing plans
- `setup.md` - Project standards configuration
- `README.md` - Directory documentation

### 2. Command Metadata Format

All commands use YAML frontmatter with standardized fields:

```yaml
---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob, Write
argument-hint: <feature-description>
description: Brief command description
command-type: primary
dependent-agents:
  - agent-name
library-requirements:
  - library-name.sh: ">=version"
documentation: See path/to/guide.md for complete usage guide
---
```

**Key Frontmatter Fields** (from `/home/benjamin/.config/.claude/commands/plan.md:1-14`):
- `allowed-tools`: List of tools the command can use
- `argument-hint`: Format for command arguments
- `description`: One-line summary shown in help
- `command-type`: primary, workflow, or utility
- `dependent-agents`: Agents invoked by command
- `library-requirements`: Required library versions
- `documentation`: Link to detailed guide

### 3. Command Categories

**Primary Commands** (orchestrators with state machine architecture):
- `/plan` - Research-and-plan workflow (research-specialist, plan-architect)
- `/build` - Build-from-plan workflow (implementer-coordinator, debug-analyst)
- `/research` - Research-only workflow (research-specialist)
- `/debug` - Debug-focused workflow (research-specialist, plan-architect, debug-analyst)
- `/coordinate` - Multi-agent orchestration (all agents)
- `/revise` - Research-and-revise workflow (research-specialist, plan-architect)
- `/setup` - Project standards configuration

**Workflow Commands** (plan structure management):
- `/expand` - Phase/stage expansion (Level 0 to Level 1/2)
- `/collapse` - Phase/stage collapse (Level 1/2 to Level 0)

**Utility Commands**:
- `/convert-docs` - Document format conversion (doc-converter agent)
- `/optimize-claude` - CLAUDE.md optimization

### 4. Command Architecture Patterns

All primary commands follow consistent patterns:

**State Machine Integration** (from `/home/benjamin/.config/.claude/commands/plan.md:11-12`):
```yaml
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
```

**Two-Part Argument Capture** (from `/home/benjamin/.config/.claude/commands/plan.md:24-47`):
- Part 1: Capture argument to temp file with timestamp
- Part 2: Read and validate from temp file

**Workflow Type Declaration** (from `/home/benjamin/.config/.claude/commands/plan.md:18-23`):
```markdown
**Workflow Type**: research-and-plan
**Terminal State**: plan (after planning phase complete)
**Expected Output**: Research reports + implementation plan
```

### 5. Comparison with Existing README

The current README.md at `/home/benjamin/.config/.claude/commands/README.md` contains:
- Extensive documentation (~700 lines)
- Some outdated command references
- Missing accurate command count (states 12 but should verify)
- Navigation section references commands that may be archived
- Command highlights section emphasizes /coordinate appropriately

**Inconsistencies Found**:
- README lists commands like `/test`, `/test-all`, `/document`, `/refactor`, `/analyze` that are not in the current command files
- README references `/plan-wizard`, `/plan-from-template`, `/list-*` commands not found
- Command types section needs updating to match actual file inventory

### 6. Command Usage Patterns

**Syntax Patterns**:
- `/plan "feature description"` - Quoted description
- `/build [plan-file] [starting-phase] [--dry-run]` - Optional positional + flags
- `/coordinate "workflow description"` - Quoted description
- `/expand phase <path> <number>` - Subcommand with positional args
- `/setup [dir] [--cleanup] [--validate]` - Optional dir with flags

**Agent Dependencies** (from command frontmatter):
- research-specialist: /plan, /research, /debug, /revise
- plan-architect: /plan, /debug, /revise
- debug-analyst: /build, /debug
- implementer-coordinator: /build
- doc-converter: /convert-docs

### 7. Subdirectory Structure

**Templates Directory** (`/home/benjamin/.config/.claude/commands/templates/`):
- Contains README.md and template files
- Referenced by /plan-from-template (if exists)

**Shared Directory** (`/home/benjamin/.config/.claude/commands/shared/`):
- Contains README.md
- Shared content referenced by multiple commands

## Recommendations

### 1. Update Command Count and Inventory
Update README.md to accurately reflect the 12 active command files. Remove references to archived commands (`/test`, `/test-all`, `/document`, `/refactor`, `/analyze`, `/plan-wizard`, `/plan-from-template`, `/list-*`) or mark them as archived with redirection to replacements.

### 2. Restructure Available Commands Section
Organize commands into current categories:
- Primary Orchestrators (7): /plan, /build, /research, /debug, /coordinate, /revise, /setup
- Workflow Managers (2): /expand, /collapse
- Utilities (2): /convert-docs, /optimize-claude

### 3. Add Standardized Command Entries
For each command, include consistent documentation:
- **Purpose**: Brief description
- **Usage**: Syntax with argument-hint
- **Type**: Command type from frontmatter
- **Agents**: Dependent agents list
- **Output**: Expected outputs
- **See Also**: Link to detailed guide

### 4. Update Navigation Section
Replace the current navigation links (lines 614-640) with accurate file references matching actual command inventory.

### 5. Add State Machine Architecture Documentation
Document the state-machine-based architecture that all primary commands share:
- Library dependencies
- Two-part argument capture pattern
- Workflow type declarations
- Terminal states

### 6. Cross-Reference Documentation
For each command, add link to its detailed guide:
- `/plan` → `.claude/docs/guides/plan-command-guide.md`
- `/build` → `.claude/docs/guides/build-command-guide.md`
- etc.

## References

### Command Files Analyzed
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 1-100)
- `/home/benjamin/.config/.claude/commands/build.md` (lines 1-100)
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 1-100)
- `/home/benjamin/.config/.claude/commands/research.md` (lines 1-100)
- `/home/benjamin/.config/.claude/commands/debug.md` (lines 1-100)
- `/home/benjamin/.config/.claude/commands/expand.md` (lines 1-80)
- `/home/benjamin/.config/.claude/commands/collapse.md` (lines 1-80)
- `/home/benjamin/.config/.claude/commands/setup.md` (lines 1-80)
- `/home/benjamin/.config/.claude/commands/revise.md` (lines 1-80)
- `/home/benjamin/.config/.claude/commands/convert-docs.md` (lines 1-80)
- `/home/benjamin/.config/.claude/commands/README.md` (lines 1-700)

### Documentation Files Referenced
- `/home/benjamin/.config/.claude/docs/reference/command-reference.md` (lines 1-644)
- `/home/benjamin/.config/.claude/docs/reference/code-standards.md` (lines 1-84)

### Directory Listings
- `/home/benjamin/.config/.claude/commands/*.md` (12 files)
- `/home/benjamin/.config/.claude/commands/**/*.md` (14 files including subdirectories)
