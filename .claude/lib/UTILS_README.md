# Standalone Utility Scripts

Core utility scripts supporting all .claude/ subsystems. These scripts provide essential functionality for checkpointing, templates, error analysis, and workflow coordination.

**Note**: This README documents **standalone utility scripts** (executable scripts). For documentation of **sourced utility libraries** (functions that are sourced into other scripts), see [README.md](README.md).

## Purpose

Utilities provide:

- **Checkpoint management** - Save, load, list, cleanup workflow state
- **Template processing** - Variable substitution and validation
- **Error enhancement** - Detailed diagnostics with fix suggestions
- **Complexity analysis** - Phase difficulty assessment
- **Adaptive planning** - Replan triggers and logging
- **Progressive structures** - Plan expansion and parsing

## Utility Scripts

### Checkpoint Management

#### save-checkpoint.sh
**Purpose**: Save workflow state at phase boundaries

**Usage**: `./save-checkpoint.sh <workflow-type> <state-json>`

**Functionality**:
- Generates unique checkpoint ID
- Validates state completeness
- Saves to checkpoints/ directory
- Returns checkpoint path

---

#### load-checkpoint.sh
**Purpose**: Load workflow state for resumption

**Usage**: `./load-checkpoint.sh <workflow-type> [project-name]`

**Functionality**:
- Finds matching checkpoint
- Validates state integrity
- Returns state JSON
- Handles corrupted checkpoints

---

### Template System

#### parse-template.sh
**Purpose**: Parse and validate workflow templates

**Usage**: `./parse-template.sh <template-path>`

**Functionality**:
- Validates YAML structure
- Extracts variables
- Checks required fields
- Returns template metadata

**Validation**:
- Variable types (string, array, boolean)
- Phase dependencies
- Required fields
- Syntax errors

---

#### substitute-variables.sh
**Purpose**: Replace template variables with actual values

**Usage**: `./substitute-variables.sh <template-path> <variables-json>`

**Functionality**:
- Simple substitution: `{{variable}}`
- Array iteration: `{{#each array}}...{{/each}}`
- Conditionals: `{{#if var}}...{{/if}}`
- Graceful handling of missing variables

**Examples**:
```bash
# Simple
{{entity_name}} → User

# Array
{{#each fields}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}
→ name, email, password

# Conditional
{{#if use_auth}}Add authentication{{/if}}
→ Add authentication (if use_auth=true)
```

---

### Error Analysis

#### analyze-error.sh
**Purpose**: Enhance error messages with fix suggestions

**Usage**: `./analyze-error.sh <error-message> <context-json>`

**Functionality**:
- Pattern matching on common errors
- File/line number extraction
- Suggests concrete fixes
- Links to relevant docs

**Error Types**:
- Syntax errors
- Missing dependencies
- Permission issues
- Configuration problems
- Network failures

**Output**: Enhanced error with fix steps

---

### Complexity Assessment

#### analyze-phase-complexity.sh
**Purpose**: Assess implementation phase difficulty

**Usage**: `./analyze-phase-complexity.sh <phase-json>`

**Functionality**:
- Counts tasks, files, dependencies
- Detects keywords (refactor, migration, etc.)
- Scores complexity (low/medium/high)
- Suggests agent type

**Factors**:
- Task count (5+ = medium, 10+ = high)
- File modifications (3+ = medium, 7+ = high)
- Keywords (refactor, migration, breaking = +1 level)
- Dependencies (external = +1 level)

---

#### parse-phase-dependencies.sh
**Purpose**: Extract and validate phase dependency graph

**Usage**: `./parse-phase-dependencies.sh <plan-path>`

**Functionality**:
- Parses "depends on" references
- Builds dependency DAG
- Detects cycles
- Determines execution order
- Identifies parallel opportunities

**Output**: Dependency graph JSON with execution order

---

### Collaboration

#### handle-collaboration.sh
**Purpose**: Process agent collaboration requests

**Usage**: `./handle-collaboration.sh <request-json>`

**Functionality**:
- Parses REQUEST_AGENT protocol
- Validates agent availability
- Prepares agent context
- Returns invocation details

**Protocol**:
```json
{
  "action": "REQUEST_AGENT",
  "agent_type": "code-writer",
  "task": "Implement auth module",
  "context": {...}
}
```

---

## Integration Points

### Commands Using Utilities

- `/implement` → checkpointing, complexity, adaptive planning
- `/orchestrate` → collaboration (handle-collaboration.sh)
- `/plan-from-template` → template parsing, substitution
- `/expand` `/collapse` → progressive plan parsing
- `/analyze` → agent registry parsing

### Hooks Using Utilities

- `post-command-metrics.sh` → No utilities (direct JSONL write)
- `tts-dispatcher.sh` → No utilities (direct message generation)

### Agents Using Utilities

- `plan-architect` → complexity analysis
- All agents → collaboration protocol (handle-collaboration.sh)

## Utility Development

### Best Practices

**Input Validation**:
```bash
# Always validate required arguments
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <required-arg>" >&2
  exit 1
fi
```

**Error Handling**:
```bash
# Graceful degradation
if ! command -v jq &>/dev/null; then
  echo "jq not found, using fallback" >&2
  # ... fallback logic
fi
```

**Output Format**:
```bash
# Consistent JSON output for piping
echo '{"status":"success","data":{...}}' | jq
```

**Non-Blocking**:
```bash
# Always exit 0 when called from hooks
process_data || true
exit 0
```

### Testing Utilities

```bash
# Test checkpoint save/load
echo '{"state":"test"}' | ./save-checkpoint.sh implement -
./load-checkpoint.sh implement

# Test template substitution
echo '{"entity":"User"}' | ./substitute-variables.sh template.yaml -

# Test error enhancement
./analyze-error.sh "SyntaxError: line 42" '{"file":"test.lua"}'

# Test collaboration
./handle-collaboration.sh '{"action":"REQUEST_AGENT","agent_type":"code-writer"}'
```

## Documentation Standards

All utilities follow standards:

- **NO emojis** in file content or output
- **JSON output** for programmatic use
- **Clear error messages** to stderr
- **Usage help** via -h or --help
- **Exit codes**: 0=success, 1=error

See [/home/benjamin/.config/nvim/docs/CODE_STANDARDS.md](../../nvim/docs/CODE_STANDARDS.md) for complete standards.

## Navigation

### Utility Scripts (Active)
- [adaptive-planning-logger.sh](adaptive-planning-logger.sh) - Adaptive planning event logging
- [analyze-error.sh](analyze-error.sh) - Error enhancement with fix suggestions
- [checkpoint-utils.sh](checkpoint-utils.sh) - Checkpoint management functions
- [complexity-utils.sh](complexity-utils.sh) - Phase complexity scoring
- [error-utils.sh](error-utils.sh) - Error classification and recovery
- [handle-collaboration.sh](handle-collaboration.sh) - Agent collaboration protocol
- [parse-template.sh](parse-template.sh) - Template validation and parsing
- [substitute-variables.sh](substitute-variables.sh) - Variable substitution engine

### Related
- [← Parent Directory](../README.md)
- [data/checkpoints/](../data/checkpoints/README.md) - Uses checkpoint utilities
- [templates/](../templates/README.md) - Uses template utilities
- [commands/](../commands/README.md) - Commands using utilities
- [tests/](../tests/README.md) - Test suites for utilities

## Quick Reference

### Common Operations

```bash
# Template system
./parse-template.sh .claude/templates/crud-feature.yaml validate
./substitute-variables.sh template.yaml '{"entity":"User","fields":["name","email"]}'

# Checkpoint utilities
source ./checkpoint-utils.sh
save_checkpoint "implement" '{"phase":3,"progress":"50%"}'
load_checkpoint "implement" "feature-123"

# Complexity analysis
source ./complexity-utils.sh
calculate_phase_complexity '{"tasks":5,"dependencies":["phase_1"],"estimated_hours":"8"}'

# Error enhancement
./analyze-error.sh "SyntaxError: unexpected token" '{"file":"init.lua","line":42}'

# Collaboration
./handle-collaboration.sh '{"action":"REQUEST_AGENT","agent_type":"code-writer"}'
```
