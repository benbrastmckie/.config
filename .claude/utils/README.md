# Utilities Directory

Core utility scripts supporting all .claude/ subsystems. These scripts provide essential functionality for checkpointing, learning, templates, error analysis, and workflow coordination.

## Purpose

Utilities provide:

- **Checkpoint management** - Save, load, list, cleanup workflow state
- **Learning data collection** - Pattern capture with privacy filtering
- **Recommendation generation** - Similarity matching and suggestions
- **Template processing** - Variable substitution and validation
- **Error enhancement** - Detailed diagnostics with fix suggestions
- **Complexity analysis** - Phase difficulty assessment
- **Collaboration handling** - Agent coordination protocols

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

#### list-checkpoints.sh
**Purpose**: List available checkpoints

**Usage**: `./list-checkpoints.sh [workflow-type]`

**Functionality**:
- Lists all or filtered checkpoints
- Shows creation time, progress
- Indicates stale/corrupted
- Sorted by most recent

---

#### cleanup-checkpoints.sh
**Purpose**: Remove old/completed checkpoints

**Usage**: `./cleanup-checkpoints.sh [max-age-days]`

**Functionality**:
- Deletes checkpoints older than threshold (default 7 days)
- Archives failed checkpoints
- Preserves active workflows
- Reports cleanup summary

---

### Learning System

#### collect-learning-data.sh
**Purpose**: Capture workflow patterns with privacy filtering

**Usage**: `./collect-learning-data.sh <workflow-json>`

**Functionality**:
- Applies privacy filters (paths, keywords)
- Extracts relevant metadata
- Appends to patterns.jsonl or antipatterns.jsonl
- Non-blocking, always succeeds

**Privacy**:
- Anonymizes file paths
- Filters sensitive keywords
- Sanitizes error messages
- Respects opt-out flag

---

#### match-similar-workflows.sh
**Purpose**: Find similar past workflows using similarity scoring

**Usage**: `./match-similar-workflows.sh <current-workflow-json>`

**Functionality**:
- Jaccard similarity on keywords
- Workflow type exact match
- Phase count tolerance (±2)
- Combined scoring (70% threshold)
- Returns top 3 matches

**Algorithm**:
```
score = (keyword_similarity × 0.6) + (type_match × 0.3) + (phase_match × 0.1)
```

---

#### generate-recommendations.sh
**Purpose**: Create actionable recommendations from similar workflows

**Usage**: `./generate-recommendations.sh <match-results-json>`

**Functionality**:
- Analyzes successful patterns
- Suggests research topics
- Estimates time/complexity
- Recommends agent selection
- Identifies parallelization opportunities

**Output**: Structured recommendation JSON

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

## Integration Points

### Commands Using Utilities

- `/implement` → checkpointing, complexity, dependencies
- `/orchestrate` → collaboration, dependencies
- `/plan` → learning recommendations
- `/plan-from-template` → template parsing, substitution
- `/analyze-patterns` → similarity matching
- `/resume-implement` → checkpoint loading

### Hooks Using Utilities

- `post-command-metrics.sh` → No utilities (direct JSONL write)
- `tts-dispatcher.sh` → No utilities (direct message generation)

### Agents Using Utilities

- `plan-architect` → complexity analysis
- `research-specialist` → learning data (via commands)

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

# Test similarity matching
cat workflow.json | ./match-similar-workflows.sh -

# Test error enhancement
./analyze-error.sh "SyntaxError: line 42" '{"file":"test.lua"}'
```

## Documentation Standards

All utilities follow standards:

- **NO emojis** in file content or output
- **JSON output** for programmatic use
- **Clear error messages** to stderr
- **Usage help** via -h or --help
- **Exit codes**: 0=success, 1=error

See [/home/benjamin/.config/nvim/docs/GUIDELINES.md](../../nvim/docs/GUIDELINES.md) for complete standards.

## Navigation

### Utility Scripts
- [analyze-error.sh](analyze-error.sh) - Error enhancement
- [analyze-phase-complexity.sh](analyze-phase-complexity.sh) - Complexity scoring
- [cleanup-checkpoints.sh](cleanup-checkpoints.sh) - Checkpoint cleanup
- [collect-learning-data.sh](collect-learning-data.sh) - Pattern capture
- [generate-recommendations.sh](generate-recommendations.sh) - Recommendations
- [handle-collaboration.sh](handle-collaboration.sh) - Agent collaboration
- [list-checkpoints.sh](list-checkpoints.sh) - Checkpoint listing
- [load-checkpoint.sh](load-checkpoint.sh) - State loading
- [match-similar-workflows.sh](match-similar-workflows.sh) - Similarity matching
- [parse-phase-dependencies.sh](parse-phase-dependencies.sh) - Dependency graph
- [parse-template.sh](parse-template.sh) - Template parsing
- [save-checkpoint.sh](save-checkpoint.sh) - State saving
- [substitute-variables.sh](substitute-variables.sh) - Variable substitution

### Related
- [← Parent Directory](../README.md)
- [checkpoints/](../checkpoints/README.md) - Uses checkpoint utilities
- [learning/](../learning/README.md) - Uses learning utilities
- [templates/](../templates/README.md) - Uses template utilities
- [commands/](../commands/README.md) - Commands using utilities

## Quick Reference

### Common Operations

```bash
# Checkpoint management
./save-checkpoint.sh implement '{"phase":3,"state":{...}}'
./load-checkpoint.sh implement my-project
./list-checkpoints.sh
./cleanup-checkpoints.sh 7

# Learning system
./collect-learning-data.sh '{"workflow":"feature","keywords":[...]}'
./match-similar-workflows.sh '{"keywords":["auth","user"]}'
./generate-recommendations.sh matches.json

# Template system
./parse-template.sh crud-feature.yaml
./substitute-variables.sh template.yaml '{"entity":"User"}'

# Error analysis
./analyze-error.sh "Error message" '{"file":"test.lua","line":42}'

# Complexity & dependencies
./analyze-phase-complexity.sh '{"tasks":["..."]}'
./parse-phase-dependencies.sh plan.md
```
