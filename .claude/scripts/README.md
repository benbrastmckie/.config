# Scripts Directory

Standalone operational scripts for system management, migration, and validation tasks. Scripts are task-specific executables that perform discrete operations on the Claude Code system.

## Purpose

This directory contains operational scripts that perform specific system-level tasks distinct from the general-purpose utilities in `lib/`. Scripts are designed to be run directly for maintenance, migration, analysis, and validation operations.

**Key Characteristics**:
- **Executable**: Designed to run as standalone commands
- **Task-Specific**: Each script addresses a particular operational need
- **System-Level**: Operate on system structure, not individual workflows
- **Self-Contained**: Include their own argument parsing and output formatting

**Difference from `lib/` Utilities**:
- **Scripts**: Task-specific executables with CLIs (this directory)
- **Lib Utilities**: Reusable functions sourced by other scripts (see `lib/README.md`)

## Module Documentation

### context_metrics_dashboard.sh
**Purpose**: Generate context reduction metrics dashboard for hierarchical agent system

**Functionality**:
- Parses context reduction logs from agent invocations
- Calculates average, max, and min reduction percentages
- Identifies commands with highest context usage
- Provides improvement recommendations

**Usage**:
```bash
./context_metrics_dashboard.sh [--format text|json] [--log-file PATH]
```

**Output**:
- Average reduction percentage across all agent calls
- Max/min reduction statistics
- Per-command context usage breakdown
- Performance improvement suggestions

**Configuration**:
- Default log file: `.claude/data/logs/context-metrics.log`
- Output formats: text (default), json

### migrate_to_topic_structure.sh
**Purpose**: Migrate flat spec structure to topic-based organization

**Functionality**:
- Converts flat `specs/plans/` structure to topic-based `specs/{NNN_topic}/`
- Creates subdirectories for plans, reports, summaries per topic
- Matches reports and summaries to related plans
- Creates backup before migration

**Usage**:
```bash
# Dry run (preview changes)
DRY_RUN=true ./migrate_to_topic_structure.sh

# Execute migration
DRY_RUN=false ./migrate_to_topic_structure.sh
```

**Strategy**:
1. Each plan `specs/plans/NNN_name.md` becomes topic `specs/NNN_name/`
2. Plan moves to `specs/NNN_name/plans/NNN_name.md`
3. Related reports/summaries matched and moved to topic
4. Unmatched artifacts go to `specs/research/` topic

**Safety**:
- Creates timestamped backup in `specs/backups/`
- Dry run mode for preview
- Verbose logging of all operations

### validate_context_reduction.sh
**Purpose**: Validate context reduction targets and metadata extraction for hierarchical agents

**Functionality**:
- Validates metadata extraction from reports and plans
- Checks context reduction percentages meet targets
- Verifies metadata-only passing between agents
- Tests forward message pattern implementation

**Usage**:
```bash
./validate_context_reduction.sh [test-reports-dir]
```

**Validation Checks**:
- Metadata extraction reduces content by 92-97%
- Title and summary extraction works correctly
- File path references preserved
- Recommendations extracted accurately
- Target: <30% context usage throughout workflows

**Test Artifacts**:
- Uses sample reports and plans from test directories
- Validates against hierarchical agent standards
- Reports pass/fail for each validation check

### validate_migration.sh
**Purpose**: Validate topic-based spec structure after migration

**Functionality**:
- Verifies topic directory structure correctness
- Checks artifact organization (plans, reports, summaries)
- Validates cross-references between artifacts
- Ensures no orphaned files

**Usage**:
```bash
./validate_migration.sh [--verbose]
```

**Validation Checks**:
- All topics follow `NNN_name/` naming convention
- Required subdirectories exist (plans/, reports/, summaries/)
- Artifacts numbered correctly within topics
- Cross-references resolve to valid files
- No artifacts left in old flat structure

**Output**:
- Pass/fail/warning counts
- List of validation failures
- List of warnings for review
- Comprehensive validation summary

## Usage Examples

### Generate Context Metrics Dashboard

```bash
cd /home/benjamin/.config/.claude/scripts

# Text format dashboard
./context_metrics_dashboard.sh

# JSON format for processing
./context_metrics_dashboard.sh --format json

# Custom log file
./context_metrics_dashboard.sh --log-file /path/to/custom.log
```

### Migrate Spec Structure

```bash
cd /home/benjamin/.config/.claude/scripts

# Preview migration (dry run)
DRY_RUN=true ./migrate_to_topic_structure.sh

# Review output and verify correctness

# Execute migration
DRY_RUN=false ./migrate_to_topic_structure.sh

# Validate migration
./validate_migration.sh --verbose
```

### Validate Context Reduction

```bash
cd /home/benjamin/.config/.claude/scripts

# Validate using default test directory
./validate_context_reduction.sh

# Validate custom reports
./validate_context_reduction.sh /path/to/test/reports
```

## Integration Points

### Context Metrics System
- **Log Source**: `.claude/data/logs/context-metrics.log`
- **Related Utilities**: `lib/context-pruning.sh` - Context management functions
- **Related Docs**: `docs/concepts/hierarchical_agents.md` - Architecture guide

### Spec Structure Migration
- **Target Structure**: `specs/{NNN_topic}/` - Topic-based organization
- **Related Commands**: `/report`, `/plan`, `/implement` - Use new structure
- **Related Docs**: `docs/concepts/directory-protocols.md` - Structure specification

### Validation Framework
- **Test Data**: Generated from actual system usage
- **Integration**: Used by CI/CD for system health checks
- **Related Utilities**: `lib/plan-metadata-utils.sh` - Metadata extraction functions

## Design Philosophy

### Operational Focus
Scripts are designed for:
- **System Administration**: Migration, maintenance, cleanup
- **Validation**: Structure verification, standards compliance
- **Analysis**: Metrics, performance, system health
- **One-Time Operations**: Not part of regular workflow commands

### Self-Contained Execution
Each script:
- Has clear CLI with argument parsing
- Includes comprehensive logging and output
- Provides dry-run or preview modes where applicable
- Returns meaningful exit codes for automation

### Complementary to Utilities
Scripts leverage `lib/` utilities for:
- Core functionality (metadata extraction, plan parsing)
- Shared patterns (logging, error handling)
- Code reuse (avoid duplication)

## Navigation

- **Parent**: [.claude/README.md](../README.md) - Claude Code configuration directory
- **Related**: [.claude/lib/README.md](../lib/README.md) - Utility libraries sourced by scripts
- **Related**: [.claude/docs/README.md](../docs/README.md) - Integration guides and standards
- **Related**: [.claude/commands/README.md](../commands/README.md) - Workflow commands
