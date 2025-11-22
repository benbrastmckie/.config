# Orchestration Command Troubleshooting Guide

[Used by: All orchestration commands - /orchestrate, /coordinate, /research, /supervise]

This guide provides diagnostic procedures and solutions for common orchestration command failures.

## Overview

Orchestration commands (`/orchestrate`, `/coordinate`, `/research`, `/supervise`) coordinate multiple specialized agents to complete complex workflows. When these commands fail, the root cause typically falls into one of these categories:

1. **Bootstrap Failures**: Library sourcing, function verification, SCRIPT_DIR validation
2. **Agent Delegation Issues**: 0% delegation rate, agents not invoked
3. **File Creation Problems**: Artifacts created in wrong locations or not at all
4. **Error Handling**: Silent failures, unclear error messages
5. **Checkpoint Issues**: State persistence and restoration failures

## Quick Diagnostic Checklist

Use this checklist to quickly identify the failure category:

```bash
# 1. Check if command starts (bootstrap)
/command-name "test" 2>&1 | head -20
# Look for: Library sourcing errors, function verification failures

# 2. Check agent delegation
/command-name "test" 2>&1 | grep "PROGRESS:"
# Look for: PROGRESS: markers indicate agent execution

# 3. Check file creation
find .claude/specs -name "*.md" -mmin -5
# Look for: Recent files in specs/NNN_topic/ directories

# 4. Check for fallback output
ls .claude/TODO*.md 2>/dev/null
# Look for: TODO files indicate agent delegation failure

# 5. Run validation
./.claude/lib/util/validate-agent-invocation-pattern.sh .claude/commands/command-name.md
# Look for: Anti-pattern violations
```

## Section 1: Bootstrap Failures

### Symptom: Command Exits Immediately

**Error Pattern**:
```
ERROR: Failed to source [library-name].sh
EXPECTED PATH: /path/to/.claude/lib/[library].sh
```

**Root Cause**: Required library file missing or not readable.

**Diagnostic Commands**:
```bash
# Check library exists
ls -la .claude/lib/

# Check specific library
cat .claude/lib/[library-name].sh

# Verify SCRIPT_DIR
echo "$PWD"
cd .claude/commands && pwd
```

**Solution**:
1. Verify library file exists at expected path
2. Check file permissions (`chmod +x` if needed)
3. Ensure running from correct directory (project root)
4. If library truly missing, restore from git or reinstall

**Prevention**: Add library existence check to CI/CD pipeline.

### Symptom: Function Not Found

**Error Pattern**:
```
ERROR: Missing required function: [function_name]
EXPECTED PROVIDER: .claude/lib/[library].sh
```

**Root Cause**: Library sourced successfully but function not defined.

**Diagnostic Commands**:
```bash
# Check if function exists in library
grep "function_name()" .claude/lib/[library].sh

# Check if function loaded
declare -F function_name

# List all loaded functions
declare -F | grep -i [keyword]
```

**Solution**:
1. **API mismatch**: Command calls old function name, library provides new name
   - Example: `save_phase_checkpoint()` vs `save_checkpoint()`
   - Fix: Update command to use correct function name
2. **Function not exported**: Library defines function but doesn't export it
   - Add to library: `export -f function_name`
3. **Syntax error in library**: Function definition malformed
   - Check library for bash syntax errors

**Prevention**:
- Integration tests that verify function availability
- Documentation of library API contracts

### Symptom: SCRIPT_DIR Not Set

**Error Pattern**:
```
ERROR: SCRIPT_DIR not set or invalid
DIAGNOSTIC: echo $SCRIPT_DIR
```

**Root Cause**: Command invoked from unexpected directory context.

**Diagnostic Commands**:
```bash
# Check current directory
pwd

# Check where command file is
find . -name "command-name.md"

# Test SCRIPT_DIR calculation
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
echo "$SCRIPT_DIR"
```

**Solution**:
1. Ensure command invoked from project root
2. Use absolute paths in library sourcing:
   ```bash
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/library.sh"
   ```
3. Calculate SCRIPT_DIR relative to known anchor:
   ```bash
   SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
   ```

**Prevention**: Commands should work from any directory by using absolute paths.

## Section 2: Agent Delegation Issues

### Symptom: 0% Delegation Rate

**Error Pattern**:
- No PROGRESS: markers visible during execution
- No reports created in `.claude/specs/NNN_topic/`
- Output written to TODO1.md or TODO2.md files
- Command appears to complete but no agent output

**Root Cause**: Documentation-only YAML blocks (anti-pattern).

**Diagnostic Commands**:
```bash
# Check for YAML blocks in command file
grep -n '```yaml' .claude/commands/command-name.md

# Validate agent invocation pattern
./.claude/lib/util/validate-agent-invocation-pattern.sh .claude/commands/command-name.md

# Check for TODO files
ls -la .claude/TODO*.md

# Run delegation rate test
./.claude/tests/test_orchestration_commands.sh
```

**Solution**:

**Anti-Pattern** (YAML blocks wrapped in code fences):
```markdown
Research phase invokes agents:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC}"
  prompt: "..."
}
```
```

**Correct Pattern** (Imperative bullet-point):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-specialist agent.

- subagent_type: "general-purpose"
- description: "Research authentication patterns for REST APIs"
- prompt: |
    Read and follow: .claude/agents/research-specialist.md

    Research topic: Authentication patterns for REST APIs
    Output file: [insert $report_path from previous step]
```

**Transformation Steps**:
1. Remove markdown code fence (` ```yaml `)
2. Add imperative directive: `**EXECUTE NOW**: USE the Task tool`
3. Use bullet-point format instead of YAML block
4. Replace template variables with concrete examples
5. Add completion signal requirement: `Return: REPORT_CREATED: $path`

**Prevention**:
- Run validation script before committing command changes
- Include delegation rate tests in CI/CD
- Follow [Command Development Guide](../development/command-development/command-development-fundamentals.md)

### Symptom: Template Variables Not Substituted

**Error Pattern**:
- Agent receives `${TOPIC_NAME}` literally instead of actual topic
- File paths contain `${REPORT_PATH}` instead of calculated path

**Root Cause**: Template variables in documentation-style blocks never evaluated.

**Diagnostic Commands**:
```bash
# Check for template variables
grep '\${' .claude/commands/command-name.md

# Look for variable calculation
grep 'report_path=' .claude/commands/command-name.md
```

**Solution**:
1. Pre-calculate all paths before agent invocation:
   ```bash
   **EXECUTE NOW**: USE the Bash tool to calculate paths:

   ```bash
   topic_dir=$(create_topic_structure "authentication")
   report_path="$topic_dir/reports/001_oauth_patterns.md"
   echo "REPORT_PATH: $report_path"
   ```
2. Pass calculated values to agent prompt:
   ```markdown
   Output file: [insert $report_path from above]
   ```
3. Do NOT use template variables like `${VAR}` in prompts

**Prevention**: Validation script detects template variables in agent prompts.

### Symptom: Agents Not Invoked Despite Proper Pattern

**Error Pattern**:
- Imperative directive (**EXECUTE NOW**) present
- Task invocation structurally correct
- Still 0% delegation rate
- No PROGRESS: markers visible

**Root Cause**: Undermining disclaimers after imperative directives (anti-pattern).

**Diagnostic Commands**:
```bash
# Check for undermining disclaimers
grep -A 25 "\*\*EXECUTE NOW\*\*" .claude/commands/command-name.md | \
  grep -i "note.*generate\|template\|example only"

# Check for template disclaimers
grep -A 10 "Task {" .claude/commands/command-name.md | grep "Note:"
```

**Solution**:

**Anti-Pattern** (Undermining disclaimer):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME}"
  prompt: "..."
}

**Note**: The actual implementation will generate N Task calls based on complexity.
```

**Correct Pattern** (Clean imperative):
```markdown
**EXECUTE NOW**: USE the Task tool for each research topic (1 to $RESEARCH_COMPLEXITY) with these parameters:

- subagent_type: "general-purpose"
- description: "Research [insert topic name] with mandatory artifact creation"
- prompt: |
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [insert display-friendly topic name]
    - Report Path: [insert absolute path from REPORT_PATHS array]

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [EXACT_ABSOLUTE_PATH]
```

**Transformation Steps**:
1. Remove all disclaimers following imperative directives
2. Use "for each [item]" phrasing to indicate loops
3. Use `[insert value]` placeholder syntax
4. Use bullet-point format, not YAML blocks
5. Keep imperatives clean and unambiguous

**Prevention**:
- Never add disclaimers after **EXECUTE NOW** directives
- Avoid phrases like "will generate", "template", "example only"
- Test delegation rate after changes
- See [Imperative Language Guide - Pitfall 5](../patterns/execution-enforcement/execution-enforcement-overview.md#pitfall-5-undermining-disclaimers)

### Symptom: Bash Code Blocks Not Executing

**Error Pattern**:
- Code blocks appear in command but never execute
- Variables not calculated before use

**Root Cause**: Bash blocks appearing as documentation, not explicit tool invocations.

**Diagnostic Commands**:
```bash
# Check bash block context
grep -B3 '```bash' .claude/commands/command-name.md
```

**Solution**:

**Anti-Pattern** (Documentation-style):
```markdown
Calculate paths:

```bash
topic_dir=$(create_topic_structure "$topic")
```
```

**Correct Pattern** (Explicit tool invocation):
```markdown
**EXECUTE NOW**: USE the Bash tool to calculate topic directory:

```bash
topic_dir=$(create_topic_structure "$topic")
echo "TOPIC_DIR: $topic_dir"
```

Verify: $topic_dir should contain absolute path to .claude/specs/NNN_topic/
```

**Key Difference**: `**EXECUTE NOW**: USE the Bash tool` directive signals immediate execution.

**Prevention**: Add "EXECUTE NOW" directive before all bash blocks that should run.

### Symptom: Bash Syntax Errors in Large Blocks

**Error Pattern**:
- `bash: ${\\!varname}: bad substitution` errors
- `bash: !: command not found` despite `set +H`
- Errors only occur with large bash blocks (400+ lines)
- Same code works in small blocks (<200 lines)

**Root Cause**: Claude AI transforms bash code when extracting large (400+ line) bash blocks from markdown, escaping special characters like `!` in `${!var}` patterns.

**Diagnostic Commands**:
```bash
# Measure bash block size
awk '/^```bash$/,/^```$/ {if (NR>1 && !/^```/) count++} /^```$/ {if (count>0) {print count, "lines"; count=0}}' .claude/commands/command-name.md

# Test small block equivalent
bash <<'EOF'
TEST_VAR="hello"
result="${!TEST_VAR}"
echo "$result"
EOF
# Expected: Works correctly (proves syntax is valid)
```

**Solution**: Split large bash blocks into chunks of <200 lines each:

```markdown
**EXECUTE NOW - Step 1: Project Setup** (176 lines)

\```bash
# Block 1: Project detection and library loading
WORKFLOW_SCOPE="research-only"
export WORKFLOW_SCOPE  # Export for next block
\```

**EXECUTE NOW - Step 2: Function Definitions** (168 lines)

\```bash
# Block 2: Function verification
# WORKFLOW_SCOPE available from previous block
result="${!WORKFLOW_SCOPE}"  # Works in small block
\```
```

**Key Points**:
- Export variables between blocks: `export VAR_NAME`
- Export functions: `export -f function_name`
- Aim for <200 lines per block (buffer below 400-line threshold)
- Choose logical split boundaries

**Real Example**: `/coordinate` Phase 0 (commit 3d8e49df)
- Before: 402-line block, 3-5 transformation errors
- After: 3 blocks (176, 168, 77 lines), 0 errors
- See [Bash Tool Limitations - Large Bash Block Transformation](../troubleshooting/bash-tool-limitations.md#large-bash-block-transformation) for detailed guide

**Prevention**: Monitor bash block sizes during development, split proactively at 300 lines.

## Section 3: File Creation Problems

### Symptom: Files Created in Wrong Location

**Error Pattern**:
- Reports in `.claude/TODO1.md` instead of `.claude/specs/NNN_topic/reports/`
- Plans in wrong directory or missing topic number prefix

**Root Cause**: Paths not pre-calculated and injected into agent prompts.

**Diagnostic Commands**:
```bash
# Check where files were created
find . -name "*.md" -mmin -10 -ls

# Check for TODO files
ls -la .claude/TODO*.md

# Check specs directory
ls -la .claude/specs/*/reports/
```

**Solution**:
1. Pre-calculate paths using location detection utilities:
   ```bash
   source .claude/lib/core/unified-location-detection.sh
   topic_dir=$(create_topic_structure "feature_name")
   report_path="$topic_dir/reports/001_subtopic.md"
   ```
2. Inject calculated paths into agent prompts
3. Verify file creation after agent returns:
   ```bash
   **MANDATORY VERIFICATION**: Verify report created

   ls -la "$report_path"
   [ -f "$report_path" ] || echo "ERROR: File missing"
   ```

**Prevention**: MANDATORY VERIFICATION checkpoints after every agent file creation operation.

### Symptom: Files Not Created At All

**Error Pattern**:
- Agent returns success but file missing
- No error message, silent failure

**Root Cause**: Write tool transient failure not detected.

**Diagnostic Commands**:
```bash
# Check if agent was invoked
grep "PROGRESS:" [command output]

# Check if agent returned success
grep "REPORT_CREATED:" [command output]

# Verify file existence
ls -la [expected path]
```

**Solution**:

Implement MANDATORY VERIFICATION pattern:

```markdown
**MANDATORY VERIFICATION - File Creation** (REQUIRED AFTER AGENT EXECUTION):

**EXECUTE NOW** (DO NOT SKIP):

1. Verify file exists:
   ```bash
   ls -la "$report_path"
   [ -f "$report_path" ] || echo "ERROR: File missing at $report_path"
   ```

2. Verify file size > 500 bytes:
   ```bash
   file_size=$(wc -c < "$report_path")
   [ "$file_size" -ge 500 ] || echo "WARNING: File too small ($file_size bytes)"
   ```

3. Results:
   - IF VERIFICATION PASSES: ✓ Proceed to next phase
   - IF VERIFICATION FAILS: ⚡ Execute FALLBACK MECHANISM

**FALLBACK MECHANISM** (IF VERIFICATION FAILED):

1. Extract content from agent response
2. Create file using Write tool directly
3. Re-verify:
   ```bash
   ls -la "$report_path"
   [ -f "$report_path" ] || { echo "CRITICAL: Fallback failed"; exit 1; }
   ```
```

**Performance Impact**:
- Without verification: 70% file creation reliability
- With verification: 100% file creation reliability
- Time cost: +2-3 seconds per file creation

**Prevention**: Add MANDATORY VERIFICATION to all agent invocations that create files.

### Symptom: Directory Structure Missing

**Error Pattern**:
- Agents fail because topic directory doesn't exist
- Manual `mkdir -p` required after agent execution

**Root Cause**: Agents not creating directory structure as expected.

**Diagnostic Commands**:
```bash
# Check directory structure
ls -la .claude/specs/

# Check specific topic
ls -la .claude/specs/NNN_topic/

# Check subdirectories
ls -la .claude/specs/NNN_topic/{reports,plans,summaries,debug}
```

**Solution**:

**Correct Pattern**: Use lazy directory creation via `ensure_artifact_directory()` at write time:

```bash
# Agent writes file using ensure_artifact_directory() pattern
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh"

# Directory created only when file is written (lazy creation)
ensure_artifact_directory "${topic_dir}/reports/001_analysis.md"
# Write file immediately after
```

**Verification**: After agent execution, verify FILES exist (not directories):
```bash
# Check for expected report files, not directories
if [ -z "$(find "$topic_dir/reports" -name '*.md' 2>/dev/null)" ]; then
  echo "WARNING: No report files created"
  echo "DIAGNOSTIC: Agent may not have produced output"
fi
```

**DO NOT** pre-create empty directories. Directories should only exist when they contain files.

See [Directory Creation Anti-Patterns](../../reference/standards/code-standards.md#directory-creation-anti-patterns) for the correct pattern.

## Section 4: Error Handling

### Symptom: Silent Failures

**Error Pattern**:
- Command completes without error
- Expected artifacts missing
- No diagnostic output

**Root Cause**: Fallback mechanisms hiding errors.

**Diagnostic Commands**:
```bash
# Check command output
/command-name "test" 2>&1 | tee output.log

# Search for warnings/errors
grep -i "error\|warning\|failed" output.log

# Check exit code
echo $?
```

**Solution**:

**Anti-Pattern** (Silent fallback):
```bash
if ! source .claude/lib/library.sh; then
  # Fallback: define function inline
  function_name() { echo "default"; }
fi
```

**Correct Pattern** (Fail-fast):
```bash
if ! source .claude/lib/library.sh; then
  echo "ERROR: Failed to source library.sh"
  echo "EXPECTED PATH: $SCRIPT_DIR/.claude/lib/library.sh"
  echo "DIAGNOSTIC: ls -la $SCRIPT_DIR/.claude/lib/library.sh"
  echo ""
  echo "CONTEXT: Library required for [specific functionality]"
  echo "ACTION: Verify library file exists and is readable"
  exit 1
fi
```

**Fail-Fast Philosophy**:
- **Bootstrap failures**: Exit immediately with diagnostic commands
- **Configuration errors**: Never mask with fallbacks
- **Transient tool failures**: Detect with verification, retry with fallback

**Prevention**: Remove all bootstrap fallback mechanisms from orchestration commands.

### Symptom: Unclear Error Messages

**Error Pattern**:
- Generic "sourcing failed" message
- No diagnostic commands provided
- Unclear what to do next

**Root Cause**: Error messages lack context and diagnostics.

**Solution**:

**Bad Error Message**:
```
Error: Library sourcing failed
```

**Good Error Message** (5-component structure):
```
ERROR: Failed to source workflow-detection.sh

EXPECTED PATH: /home/user/.config/.claude/lib/workflow/workflow-detection.sh

DIAGNOSTIC COMMANDS:
  ls -la /home/user/.config/.claude/lib/workflow/workflow-detection.sh
  cat /home/user/.config/.claude/lib/workflow/workflow-detection.sh | head -10

CONTEXT: Library required for workflow scope detection (detect_workflow_scope function)

ACTION:
  1. Verify library file exists at expected path
  2. Check file permissions (should be readable)
  3. Restore from git if missing: git checkout .claude/lib/workflow/workflow-detection.sh
```

**Error Message Standards** (5 components):
1. **What failed**: Specific operation that failed
2. **Expected state**: What should have happened
3. **Diagnostic commands**: Exact commands to investigate
4. **Context**: Why this operation is required
5. **Action**: Steps to resolve the issue

**Prevention**: All orchestration commands should use 5-component error messages.

## Section 5: Checkpoint Issues

### Symptom: State Not Persisted

**Error Pattern**:
- Command restarts from beginning after interruption
- Phase progress lost
- Variables not restored

**Root Cause**: Checkpoint save/restore not called or API mismatch.

**Diagnostic Commands**:
```bash
# Check for checkpoint files
ls -la .claude/data/checkpoints/

# Check checkpoint content
cat .claude/data/checkpoints/[command-name]_*.json

# Verify checkpoint functions available
declare -F | grep checkpoint
```

**Solution**:

**API Mismatch Example**:
```bash
# Command called (OLD API):
save_phase_checkpoint "$phase_number" "$data"

# Library provides (NEW API):
save_checkpoint "$checkpoint_name" "$data"
```

**Fix**: Update command to use correct API:
```bash
# Correct usage:
source .claude/lib/workflow/checkpoint-utils.sh
save_checkpoint "coordinate_phase2" "{\"topic\":\"$topic\",\"reports\":\"$reports\"}"

# Restore:
checkpoint_data=$(restore_checkpoint "coordinate_phase2")
```

**Verification**:
```bash
# After save
ls -la .claude/data/checkpoints/ | grep coordinate_phase2

# After restore
echo "$checkpoint_data" | jq .
```

**Prevention**: Integration tests that verify checkpoint save/restore cycle.

### Symptom: Checkpoint Restore Fails

**Error Pattern**:
- Checkpoint file exists but restore returns empty
- Variables not populated after restore

**Root Cause**: Checkpoint data format mismatch or parsing error.

**Diagnostic Commands**:
```bash
# Check checkpoint content
cat .claude/data/checkpoints/[checkpoint].json | jq .

# Verify JSON validity
jq empty .claude/data/checkpoints/[checkpoint].json
```

**Solution**:
1. Verify checkpoint data is valid JSON
2. Check checkpoint contains expected fields
3. Validate restore function returns data:
   ```bash
   data=$(restore_checkpoint "name")
   [ -z "$data" ] && { echo "ERROR: Checkpoint restore failed"; exit 1; }
   ```

**Prevention**: Add checkpoint validation after save, before restore.

## Reference Patterns

### Working Examples

**Compliant Commands** (verified >90% delegation rate):
- `/supervise`: .claude/commands/supervise.md (spec 438, 057)
- `/coordinate`: .claude/commands/coordinate.md (spec 495, 057)
- `/research`: .claude/commands/research.md (spec 495)
- `/orchestrate`: .claude/commands/orchestrate.md (validated in spec 497)

### Agent Invocation Pattern

**Template**:
```markdown
**EXECUTE NOW**: USE the Bash tool to calculate paths:

```bash
source .claude/lib/core/unified-location-detection.sh
topic_dir=$(create_topic_structure "[topic_name]")
report_path="$topic_dir/reports/001_[subtopic].md"
echo "REPORT_PATH: $report_path"
```

**EXECUTE NOW**: USE the Task tool with these parameters:

- subagent_type: "general-purpose"
- description: "[5-10 word description]"
- prompt: |
    Read and follow behavioral guidelines from:
    .claude/agents/[agent-name].md

    **Workflow Context**:
    - Topic: [specific topic]
    - Output Path: [insert $report_path from above]
    - Requirements: [specific requirements]

    Return: REPORT_CREATED: $report_path

**MANDATORY VERIFICATION** (EXECUTE AFTER AGENT RETURNS):

```bash
ls -la "$report_path"
[ -f "$report_path" ] || {
  echo "ERROR: File missing at $report_path"
  echo "FALLBACK: Creating file from agent response"
  # Extract content and use Write tool
}
```

**WAIT FOR**: Agent to return REPORT_CREATED: [path]
```

## Validation Commands

### Quick Validation

```bash
# Validate specific command
./.claude/lib/util/validate-agent-invocation-pattern.sh .claude/commands/command-name.md

# Expected output if compliant:
# ✓ No anti-patterns detected
# ✓ All agent invocations use imperative pattern
# ✓ No template variables in prompts
```

### Comprehensive Testing

```bash
# Run unified test suite
./.claude/tests/test_orchestration_commands.sh

# Expected output:
# Test 1: Agent invocation pattern... PASS
# Test 2: Bootstrap sequence... PASS
# Test 3: Delegation rate... PASS
# Test 4: File creation... PASS
#
# All tests passed (4/4)
```

### Delegation Rate Analysis

```bash
# Run command with delegation tracking
/command-name "test topic" 2>&1 | tee output.log

# Count PROGRESS markers (indicates agent execution)
grep -c "PROGRESS:" output.log

# Count agent invocations in command file
grep -c "USE the Task tool" .claude/commands/command-name.md

# Delegation rate = PROGRESS count / invocation count
# Target: >90%
```

## Troubleshooting Workflow

Follow this decision tree for fastest diagnosis:

```
1. Does command start?
   NO → Section 1: Bootstrap Failures
   YES → Continue

2. Do you see PROGRESS: markers?
   NO → Section 2: Agent Delegation Issues
   YES → Continue

3. Are files created in correct location?
   NO → Section 3: File Creation Problems
   YES → Continue

4. Are there clear error messages?
   NO → Section 4: Error Handling
   YES → Continue

5. Does state persist across interruptions?
   NO → Section 5: Checkpoint Issues
   YES → Working correctly
```

## Prevention Checklist

Before committing changes to orchestration commands:

- [ ] Run validation script: `.claude/lib/util/validate-agent-invocation-pattern.sh`
- [ ] Run test suite: `.claude/tests/test_orchestration_commands.sh`
- [ ] Verify no TODO files created: `ls .claude/TODO*.md` (should fail)
- [ ] Verify files in correct locations: `ls .claude/specs/*/reports/`
- [ ] Test from different directories: `cd /tmp && /command-name "test"`
- [ ] Test with simulated library failure
- [ ] Verify error messages include diagnostic commands
- [ ] Check delegation rate: `grep -c "PROGRESS:"` vs `grep -c "USE the Task tool"`

## See Also

- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Agent invocation patterns
- [Command Architecture Standards](../reference/architecture/overview.md) - Standard 11 details
- [Command Development Guide](../development/command-development/command-development-fundamentals.md) - Complete development workflow
- [Imperative Language Guide](../patterns/execution-enforcement/execution-enforcement-overview.md) - Enforcement patterns
- [Verification and Fallback Pattern](../concepts/patterns/verification-fallback.md) - File creation reliability
