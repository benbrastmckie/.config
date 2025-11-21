# Troubleshooting Guide: /plan Command Errors

## Common Error Patterns

### Error: append_workflow_state: command not found

**Symptom**: Exit code 127 in Block 1c with error message "append_workflow_state: command not found"

**Root Cause**: Missing state-persistence.sh library sourcing in Block 1c

**Fix Applied**: Block 1c now sources state-persistence.sh along with other required libraries

**Prevention**: Use `source_libraries_for_block "state"` pattern for standardized library sourcing

### Error: Topic naming agent failed (agent_no_output_file)

**Symptom**: Fallback to "no_name" directory structure with warning "Topic naming agent failed to create output file"

**Root Cause**: Agent did not write output file within validation timeout

**Debugging Steps**:
1. Check error log: `/errors --command /plan --type agent_error --limit 5`
2. Verify file permissions: `ls -la ${HOME}/.claude/tmp/`
3. Check disk space: `df -h ${HOME}/.claude/tmp/`
4. Review agent output validation timeout (default 5s)

**Fix Applied**: Added validate_agent_output() function to detect missing output files immediately

**Prevention**: Agents must return TASK_ERROR if Write tool invocation fails

### Error: Bash error at line 1: exit code 127 (bashrc sourcing)

**Symptom**: Workflow fails at startup before Block 1a with bashrc sourcing error

**Root Cause**: `/etc/bashrc` does not exist on NixOS systems

**Fix Applied**: Bashrc sourcing already uses portable pattern in current implementation

**Prevention**: Use conditional sourcing with fallback to multiple standard locations

## Diagnostic Commands

**View recent /plan errors**:
```bash
/errors --command /plan --since 1h --summary
```

**Analyze error patterns**:
```bash
/errors --command /plan --type execution_error --limit 20
```

**Check agent failures**:
```bash
/errors --command /plan --type agent_error --limit 10
```

**Verify state file integrity**:
```bash
ls -lh ${HOME}/.claude/tmp/state_*.sh | tail -5
cat ${HOME}/.claude/tmp/state_$(cat ${HOME}/.claude/tmp/plan_state_id.txt).sh
```

## Infrastructure Components

### Library Sourcing Helper

**File**: `.claude/lib/core/source-libraries.sh`

**Usage**:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/source-libraries.sh"
source_libraries_for_block "state"
validate_sourced_functions "state"
```

**Block Types**:
- `init`: Block 1a (initial setup)
- `state`: Block 1c (state loading)
- `verify`: Block 2/3 (verification)

### Agent Output Validation

**File**: `.claude/lib/core/error-handling.sh`

**Usage**:
```bash
# Invoke agent
Task { ... }

# Validate output
if ! validate_agent_output "agent-name" "$OUTPUT_FILE" 5; then
  echo "WARNING: Agent failed, using fallback"
fi
```

### State Variable Validation

**File**: `.claude/lib/core/state-persistence.sh`

**Usage**:
```bash
# Load state
load_workflow_state "$WORKFLOW_ID" false

# Validate required variables
validate_block_state "state" || exit 1
```

## Related Documentation

- [Error Handling Pattern](.claude/docs/concepts/patterns/error-handling.md)
- [Command Reference](.claude/docs/reference/standards/command-reference.md)
- [State Persistence Library](.claude/lib/core/state-persistence.sh)
