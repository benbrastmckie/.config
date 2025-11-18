# State-Based Orchestration: States

**Related Documents**:
- [Overview](state-orchestration-overview.md) - Architecture summary
- [Transitions](state-orchestration-transitions.md) - State transitions
- [Examples](state-orchestration-examples.md) - Reference implementations

---

## State Machine Architecture

The state machine provides explicit workflow lifecycle management through named states and validated transitions.

## State Definitions

### Core States

| State | Purpose | Next States |
|-------|---------|-------------|
| `initialize` | Setup workflow, classify complexity | research, planning |
| `research` | Parallel research agents | planning |
| `planning` | Create implementation plan | implementation |
| `implementation` | Execute code changes | testing |
| `testing` | Run test suite | documentation, debug |
| `debug` | Fix test failures | testing |
| `documentation` | Update docs | complete |
| `complete` | Workflow finished | (terminal) |

### State Diagram

```
initialize
    |
    +----> research ----> planning
    |                        |
    +------------------------+
                             |
                             v
                      implementation
                             |
                             v
                         testing
                          /   \
                         v     v
                     debug    documentation
                       |           |
                       v           v
                   testing     complete
```

## State Properties

### Initialize State

**Purpose**: Setup workflow and classify complexity

**Operations**:
- Detect CLAUDE_PROJECT_DIR
- Source required libraries
- Classify workflow scope (micro/focused/standard/comprehensive)
- Calculate research complexity

**Exports**:
```bash
WORKFLOW_SCOPE        # micro|focused|standard|comprehensive
RESEARCH_COMPLEXITY   # 0-4
RESEARCH_TOPICS_JSON  # ["topic1", "topic2"]
```

**Transitions**:
- -> research (if complexity > 0)
- -> planning (if micro scope)

### Research State

**Purpose**: Gather information through parallel research

**Operations**:
- Launch research-specialist agents
- Collect report metadata
- Verify report creation

**Exports**:
```bash
REPORT_PATHS  # JSON array of report paths
```

**Transitions**:
- -> planning (always)

### Planning State

**Purpose**: Create structured implementation plan

**Operations**:
- Invoke plan-architect agent
- Parse plan structure
- Calculate execution waves

**Exports**:
```bash
PLAN_PATH    # Path to plan file
PHASE_COUNT  # Number of phases
WAVE_COUNT   # Number of waves
```

**Transitions**:
- -> implementation (always)

### Implementation State

**Purpose**: Execute plan phases

**Operations**:
- Execute phases in waves
- Run tests after each phase
- Create git commits

**Exports**:
```bash
CURRENT_WAVE       # Current wave number
COMPLETED_PHASES   # Array of completed phases
```

**Transitions**:
- -> testing (when all phases complete)

### Testing State

**Purpose**: Run comprehensive tests

**Operations**:
- Run unit tests
- Run integration tests
- Report results

**Exports**:
```bash
TEST_STATUS   # pass|fail
TESTS_PASSED  # Count
TESTS_FAILED  # Count
```

**Transitions**:
- -> documentation (if tests pass)
- -> debug (if tests fail)

### Debug State

**Purpose**: Fix test failures

**Operations**:
- Analyze failures
- Apply fixes
- Re-run affected tests

**Transitions**:
- -> testing (after fixes)

### Documentation State

**Purpose**: Update documentation

**Operations**:
- Update affected READMEs
- Create workflow summary
- Update CHANGELOG

**Exports**:
```bash
SUMMARY_PATH  # Path to summary file
```

**Transitions**:
- -> complete (always)

### Complete State

**Purpose**: Terminal state

**Operations**:
- Final checkpoint
- Display completion message

**Transitions**: None (terminal)

## State Machine API

### Initialization

```bash
source "${LIB_DIR}/workflow-state-machine.sh"

# Initialize with workflow description
sm_init "$WORKFLOW_DESC" "$COMMAND_NAME"

# Returns 0 on success, 1 on failure
# Exports: WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
```

### State Operations

```bash
# Get current state
CURRENT=$(sm_get_state)

# Check if state is valid
sm_is_valid_state "planning"  # returns 0 or 1

# Check if transition is valid
sm_can_transition "research" "planning"  # returns 0 or 1
```

### Transitions

```bash
# Transition to next state
sm_transition "research" "planning"

# With validation (recommended)
if ! sm_transition "$FROM" "$TO"; then
  echo "Invalid transition"
  exit 1
fi
```

## State Validation

### Valid Transitions Table

```bash
declare -A VALID_TRANSITIONS=(
  ["initialize"]="research planning"
  ["research"]="planning"
  ["planning"]="implementation"
  ["implementation"]="testing"
  ["testing"]="documentation debug"
  ["debug"]="testing"
  ["documentation"]="complete"
  ["complete"]=""
)
```

### Transition Validation

```bash
sm_can_transition() {
  local from="$1"
  local to="$2"

  # Check if 'to' is in valid transitions for 'from'
  if [[ " ${VALID_TRANSITIONS[$from]} " =~ " $to " ]]; then
    return 0
  fi
  return 1
}
```

## Workflow Scopes

### Micro Scope

- **Complexity**: 0
- **Skip**: Research phase
- **Example**: Single file fix, minor update

### Focused Scope

- **Complexity**: 1-2
- **Research**: 1-2 topics
- **Example**: Small feature, bug fix with research

### Standard Scope

- **Complexity**: 3-4
- **Research**: 3-4 topics
- **Example**: New feature, moderate refactor

### Comprehensive Scope

- **Complexity**: 5+
- **Research**: 4+ topics
- **Example**: Architecture change, major feature

## Classification Algorithm

```bash
classify_workflow() {
  local desc="$1"
  local score=0

  # Keyword scoring
  [[ "$desc" =~ implement|architecture ]] && ((score += 3))
  [[ "$desc" =~ add|improve ]] && ((score += 2))
  [[ "$desc" =~ security|breaking ]] && ((score += 4))
  [[ "$desc" =~ fix|update ]] && ((score += 1))

  # Determine scope
  if [ $score -eq 0 ]; then
    echo "micro"
  elif [ $score -le 2 ]; then
    echo "focused"
  elif [ $score -le 4 ]; then
    echo "standard"
  else
    echo "comprehensive"
  fi
}
```

---

## Related Documentation

- [Overview](state-orchestration-overview.md)
- [Transitions](state-orchestration-transitions.md)
- [Examples](state-orchestration-examples.md)
