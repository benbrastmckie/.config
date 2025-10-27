# Utils Directory

Specialized helper utilities for specific operational tasks. These utilities bridge the gap between general-purpose `lib/` functions and task-specific `scripts/`, providing targeted functionality for common operations.

## Purpose

This directory contains helper utilities that:
- Can be executed directly or sourced
- Have specific operational purposes
- May provide compatibility interfaces
- Are less general-purpose than `lib/` utilities but more reusable than `scripts/`

**Key Characteristics**:
- **Dual-Mode**: Can be executed directly or sourced as functions
- **Specialized**: Focused on specific tasks or compatibility needs
- **Bridge Layer**: Between lib utilities and scripts
- **Operational**: Support specific commands or workflows

**Directory Role Comparison**:
- **lib/**: General-purpose reusable functions (sourced)
- **utils/**: Specialized helpers (executable or sourced)
- **scripts/**: Task-specific standalone executables (executed)

## Module Documentation

### parse-adaptive-plan.sh
**Purpose**: Compatibility shim for refactored plan parsing utilities

**Functionality**:
- Sources modular plan parsing utilities from `lib/`
- Provides compatibility interface for legacy tests
- Can be called as script or sourced as library
- Delegates to new modular utilities

**Architecture**:
Sources the following refactored modules:
- `plan-core-bundle.sh` - Core plan parsing functions
- `progressive-planning-utils.sh` - Phase expansion/collapse utilities

**Usage as Script**:
```bash
./parse-adaptive-plan.sh <function_name> [args...]
```

**Usage as Source**:
```bash
source /path/to/parse-adaptive-plan.sh
# Functions from sourced modules now available
```

**Available Functions**:
Functions are defined in sourced modules:
- `plan-structure-utils.sh` - Plan structure operations
- `plan-metadata-utils.sh` - Metadata extraction
- `progressive-planning-utils.sh` - Expansion/collapse
- `parse-plan-core.sh` - Core parsing logic

**Design Rationale**:
Created during refactoring to maintain backward compatibility with existing tests while transitioning to modular utility architecture. Allows tests to continue working during migration period.

### show-agent-metrics.sh
**Purpose**: Display agent performance metrics in human-readable format

**Functionality**:
- Parses agent registry JSON for performance data
- Formats metrics for terminal display
- Shows per-agent statistics and success rates
- Displays last execution information

**Usage**:
```bash
# Use default registry location
./show-agent-metrics.sh

# Specify custom registry file
./show-agent-metrics.sh /path/to/agent-registry.json
```

**Output Format**:
```
==========================================
Agent Performance Metrics
==========================================

Agent: research-specialist
----------------------------------------
  Type: research
  Description: Research and analysis specialist

  Performance:
    Total Invocations: 45
    Successes: 43
    Success Rate: 95.6%
    Average Duration: 2345ms (2.35s)

  Last Execution:
    Time: 2025-10-19T14:30:22Z
    Status: success

==========================================
Registry: .claude/agents/agent-registry.json
Last Updated: 2025-10-19T14:30:22Z
==========================================
```

**Dependencies**:
- `jq` - JSON parsing (required)
- `.claude/agents/agent-registry.json` - Agent registry file

**Metrics Displayed**:
- Agent type and description
- Total invocations count
- Success count and success rate percentage
- Average execution duration (ms and seconds)
- Last execution timestamp and status

## Usage Examples

### Using parse-adaptive-plan.sh as Compatibility Shim

```bash
cd /home/benjamin/.config/.claude/utils

# Call specific function
./parse-adaptive-plan.sh extract_plan_metadata /path/to/plan.md

# Source for function access
source ./parse-adaptive-plan.sh
extract_plan_metadata /path/to/plan.md
```

### Viewing Agent Metrics

```bash
cd /home/benjamin/.config/.claude/utils

# Display all agent metrics
./show-agent-metrics.sh

# View metrics from custom registry
./show-agent-metrics.sh ~/.config/.claude/agents/agent-registry.json
```

### Integration with Tests

```bash
# Tests can source parse-adaptive-plan.sh for backward compatibility
source .claude/utils/parse-adaptive-plan.sh

# Test functions work as before
result=$(extract_plan_metadata "$test_plan_file")
```

## Integration Points

### Plan Parsing System
**parse-adaptive-plan.sh** integrates with:
- **Refactored Utilities**: Sources modular `lib/` utilities
- **Test Suite**: Provides compatibility for `tests/test_*.sh`
- **Commands**: Used by `/implement`, `/plan`, `/expand`, `/collapse`

**Relationship**:
```
Old Interface (tests) → parse-adaptive-plan.sh → New Modular Utilities (lib/)
                              ↓
                        Compatibility Layer
```

### Agent Metrics System
**show-agent-metrics.sh** integrates with:
- **Agent Registry**: `.claude/agents/agent-registry.json`
- **Agent Execution**: Metrics updated by agent invocation system
- **Monitoring**: Used for performance analysis and debugging

**Related Systems**:
- Agent invocation logging
- Performance tracking
- Debug analysis

## Design Philosophy

### Compatibility Layer
Utils serve as compatibility interfaces during system evolution:
- **Graceful Migration**: Allow tests to work during refactoring
- **Backward Compatibility**: Maintain existing interfaces
- **Forward Integration**: Delegate to new implementations

### Specialized Functionality
Each utility addresses specific operational needs:
- **Targeted**: Specific purpose rather than general-purpose
- **Operational**: Support specific workflows or commands
- **Lightweight**: Minimal code, delegate to lib/ for complexity

### Bridge Between Layers
Utils bridge different architectural layers:
- **lib/ → utils/**: Wrap general utilities for specific use cases
- **utils/ → scripts/**: Provide building blocks for complex scripts
- **utils/ → commands/**: Support command implementations

## Deprecation and Evolution

### parse-adaptive-plan.sh
**Status**: Compatibility shim during refactoring transition

**Future**:
- Will be deprecated once all tests migrate to direct module sourcing
- Currently maintained for backward compatibility
- New code should source modular utilities directly

**Migration Path**:
```bash
# Old (using utils/)
source .claude/utils/parse-adaptive-plan.sh

# New (using lib/ directly)
source .claude/lib/plan-core-bundle.sh
source .claude/lib/progressive-planning-utils.sh
```

### show-agent-metrics.sh
**Status**: Active utility

**Future**:
- May be enhanced with additional metrics
- Could be integrated into dashboard script
- Stable interface, no deprecation planned

## Navigation

- **Parent**: [.claude/README.md](../README.md) - Claude Code configuration directory
- **Related**: [.claude/lib/README.md](../lib/README.md) - General-purpose utility libraries
- **Related**: [.claude/scripts/README.md](../scripts/README.md) - Task-specific operational scripts
- **Related**: [.claude/tests/README.md](../tests/README.md) - Test suite using these utilities
- **Related**: [.claude/agents/README.md](../agents/README.md) - Agent system with metrics
